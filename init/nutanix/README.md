# Nutanix CE initialization

This path starts with an already configured Nutanix CE cluster and its Prism Element endpoint. It does not create a CE cluster, manage AHV hosts, or deploy Prism Central.

Copy `settings.example.json` to a private `settings.json` and replace every UUID with a value obtained from `scripts/nutanix/Test-PrismElement.ps1`. Prism Element requires a local username and password; do not use Prism Central API keys.

`repo_root` and `software_store` use the native path format of the workstation running the script. For example, use `/Users/name/Source/GO-EUC-LAB` and `/Users/name/Software` on macOS, or `C:\Source\GO-EUC-LAB` and `C:\Software` on Windows. If `repo_root` is omitted or does not exist on the current host, the initializer automatically uses the repository containing `init/nutanix/init.ps1`.

The control-plane VM uses the `docker.user` account and password authentication. Pass its password as a secure string rather than storing it in `settings.json`:

```powershell
$dockerPassword = Read-Host -AsSecureString
.\init.ps1 -SettingsFile .\settings.json -AdoPat $adoPat -GitHubPat $githubPat -PrismPassword $prismPassword -DockerPassword $dockerPassword
```

## Required preconditions

- Prism Element is reachable on TCP 9440 from the initialization workstation and the Azure DevOps agents.
- A VLAN/subnet and storage container already exist on the CE cluster.
- Prism can fetch `docker.image_source_uri`, or the URI points to an internal HTTP server reachable by Prism.
- The selected CIDR has reserved addresses for the Prism endpoint, gateway, DNS, Docker host, and other existing services.
- Azure DevOps and GitHub PATs have the permissions documented in `../README.md`.

Run the capability probe before initialization:

```powershell
$password = Read-Host -AsSecureString
.\scripts\nutanix\Test-PrismElement.ps1 -Endpoint 10.0.0.20 -Username admin -Password $password -SkipCertificateCheck
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
- `go/nutanix/cluster`
- `go/nutanix/network`
- `go/nutanix/storage`
- shared `go/domain`, `go/docker`, `go/build`, `go/postgress`, and `go/domain/accounts`

The image import and VM APIs vary between CE releases. The direct Prism Element adapter reports API/task failures explicitly; do not work around those failures by deploying Prism Central.

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
