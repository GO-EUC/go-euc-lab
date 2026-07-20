# Nutanix CE initialization

This path starts with an already configured Nutanix CE cluster, its Prism Element endpoint, and a deployed Prism Central instance. It does not create a CE cluster or manage AHV hosts.

For a complete from-scratch walkthrough (cluster prerequisites through image builds and lab deployment), see [`GETTING-STARTED.md`](GETTING-STARTED.md). This file documents the initializer itself.

Prism Central is a prerequisite because the image pipeline uses the official Packer Nutanix builder, which only supports the Prism Central APIs. Deploy it once from the Prism Element UI:

1. Configure a Data Services IP on the cluster if not already set (`Settings > iSCSI Data Services IP`).
2. Download the "Prism Central 1-click deploy from Prism Element" bundle (binary and metadata file) for a version compatible with your CE release from the Nutanix portal, and upload it in the deployment wizard if no compatible version is listed online.
3. On the Prism Element home page choose "Register or create new" on the Prism Central widget, deploy an **X-Small** instance (4 vCPU, 18 GiB RAM, 100 GiB disk) with a free static IP on the lab network, and register the cluster with it.

Copy `settings.example.json` to a private `settings.json` and replace every UUID with a value obtained from `scripts/nutanix/Test-PrismElement.ps1`. Prism Element and Prism Central require a local username and password; do not use Prism Central API keys.

`repo_root` and `software_store` use the native path format of the workstation running the script. For example, use `/Users/name/Source/GO-EUC-LAB` and `/Users/name/Software` on macOS, or `C:\Source\GO-EUC-LAB` and `C:\Software` on Windows. If `repo_root` is omitted or does not exist on the current host, the initializer automatically uses the repository containing `init/nutanix/init.ps1`.

The control-plane VM uses the `docker.user` account and password authentication. Pass its password as a secure string rather than storing it in `settings.json`:

```powershell
$dockerPassword = Read-Host -AsSecureString
.\init.ps1 -SettingsFile .\settings.json -AdoPat $adoPat -GitHubPat $githubPat -PrismPassword $prismPassword -PrismCentralPassword $prismCentralPassword -DockerPassword $dockerPassword
```

`-PrismCentralPassword` is required when `settings.json` contains a `prism_central` section. The credentials are stored in Vault at `go/nutanix/prism_central` and used by the image pipeline for Packer builds.

## Required preconditions

- Prism Element is reachable on TCP 9440 from the initialization workstation and the Azure DevOps agents.
- Prism Central is deployed, registered with the cluster, and reachable on TCP 9440 from the Azure DevOps agents.
- A VLAN/subnet and storage container already exist on the CE cluster.
- Prism can fetch `docker.image_source_uri`, or the URI points to an internal HTTP server reachable by Prism.
- The selected CIDR has reserved addresses for the Prism endpoints, gateway, DNS, Docker host, and other existing services.
- The software store contains the Windows ISOs under `Microsoft/Server/` and `Microsoft/Desktop/` and a Nutanix VirtIO driver ISO under `Nutanix/` (see "Image builds" below).
- Azure DevOps and GitHub PATs have the permissions documented in `../README.md`.

Run the capability probe before initialization:

```powershell
$password = Read-Host -AsSecureString
.\scripts\nutanix\Test-PrismElement.ps1 -Endpoint 10.0.0.5 -Username admin -Password $password -SkipCertificateCheck
```

The probe is read-only. It records the cluster, storage container, subnet, image, and VM endpoint availability in `prism-element-capabilities.json`.

## Bootstrap

```powershell
.\init\nutanix\init.ps1 `
  -SettingsFile .\init\nutanix\settings.json `
  -AdoPat $adoPat `
  -GitHubPat $githubPat `
  -PrismPassword $password
```

The initializer imports an Ubuntu cloud image, creates the control-plane VM, then configures PostgreSQL, Vault, NGINX, and Azure DevOps agents through the same Docker-based control-plane convention used by the VMware path. It writes the following Vault paths:

- `go/nutanix/prism`
- `go/nutanix/prism_central`
- `go/nutanix/cluster`
- `go/nutanix/network`
- `go/nutanix/storage`
- shared `go/domain`, `go/docker`, `go/build`, `go/postgress`, and `go/domain/accounts`

The initializer talks to Prism Element directly (through `scripts/nutanix/Invoke-PrismElement.ps1`) to create the control-plane VM; the image and infra pipelines use Prism Central.

## Image builds

The Nutanix image pipeline (`.devops/pipelines/nutanix/image.yml`) builds Windows Server 2019/2022/2025 and Windows 11 golden images with the official Packer Nutanix builder against Prism Central. Each stage:

1. Discovers the operating system ISO in the software store (`http://<docker-ip>:8080/Microsoft/Server/` or `.../Microsoft/Desktop/`, falling back to a flat `.../Microsoft/`), plus the Nutanix VirtIO driver ISO in `http://<docker-ip>:8080/Nutanix/`.
2. Passes the ISO URIs to Packer; the builder registers them in the Prism image library on first use and reuses them by name afterwards. ISOs that are already present in the image library under their software-store file name are used as-is.
3. Boots a temporary VM from the ISO, runs the unattended installation (VirtIO drivers are injected from the second CD-ROM), applies the provisioning scripts and Windows updates, and captures the disk as a library image (for example `windows-server-2022-standard`).
4. Captures the finished image in the Prism Central image library under a fixed name (for example `windows-server-2022-standard`); the Terraform composition (using the official `nutanix` provider against Prism Central) resolves it by that name and clones it when provisioning lab VMs. No manifest artifact is exchanged between the pipelines.

Place the VirtIO ISO (downloadable from the Nutanix portal, e.g. `Nutanix-VirtIO-1.2.3.iso`) in the `Nutanix/` folder of the software store before running the pipeline.

The control-plane customization is applied only on the VM's first boot. If an earlier run created `dckr-1` with DHCP or incorrect cloud-init, stop the initializer and rerun it with `-RecreateControlPlaneVm`. This deletes only the Nutanix VM named by `docker.name` before recreating it; use it only before the control plane contains state you need to preserve.

The Nutanix initializer defaults to DHCP for the control-plane VM and polls Prism Element for its reported IPv4 address before connecting over SSH. `docker.ip` remains a reserved-address convention for compatibility with the rest of the lab configuration, but it is not used to connect to the Nutanix control plane.

To configure a fixed control-plane address, set `docker.static_ip` to an unused address in `network.cidr`. Nutanix Prism Element does not expose Config Drive network metadata, so the initializer uses the documented workaround: cloud-init overwrites `/etc/netplan/50-cloud-init.yaml`, matches the AHV NIC, runs `netplan generate`, then applies the resulting configuration. The control plane uses `8.8.8.8` and `8.8.4.4` for external DNS after the static configuration takes effect. The initializer waits for Prism to report the address, restarts the VM, then begins its SSH readiness checks:

```json
"docker": {
  "name": "dckr-1",
  "user": "gouser",
  "static_ip": "10.0.0.6"
}
```

After adding or changing `static_ip`, rerun with `-RecreateControlPlaneVm` because guest customization is first-boot only.
