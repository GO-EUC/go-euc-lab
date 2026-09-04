# Getting started: GO-EUC lab on Nutanix CE

This guide walks through a complete from-scratch deployment of the GO-EUC lab on a Nutanix CE cluster: from an empty (but installed) cluster to a running lab domain with golden images and workload VMs. Follow it top to bottom; each step depends on the previous one.

The end state:

- A control-plane VM (`dckr-1`) running PostgreSQL (Terraform state), HashiCorp Vault (secrets), NGINX (software store), and the Azure DevOps agents in Docker.
- An Azure DevOps project with three pipelines: image build, lab deployment, and image customization.
- Windows golden images (Server 2019/2022/2025, Windows 11) built from ISO with Packer and stored in the Prism image library.
- Lab workload VMs (domain controller, management, SQL, RD Gateway, build machine, optional Citrix/Horizon roles) provisioned by Terraform and configured by Ansible.

## 1. Prerequisites

### Nutanix CE cluster

- A working Nutanix CE 2.1 (AOS 6.8.x) cluster with Prism Element reachable on TCP 9440 from your workstation.
- A VLAN/subnet and a storage container already created on the cluster.
- An **iSCSI Data Services IP** configured (`Prism Element > Settings > iSCSI Data Services IP`). This is required before Prism Central can be deployed.
- Enough free resources for Prism Central (4 vCPU / 18 GiB), the control plane (2 vCPU / 4 GiB), one image build VM at a time (2-4 vCPU / 4 GiB), and the lab workloads.

### Prism Central (one-time manual deployment)

The image pipeline uses the official Packer Nutanix builder, which only talks to Prism Central. Deploy it once through the Prism Element UI:

1. Download the **"Prism Central 1-click deploy from Prism Element"** package from the [Nutanix portal](https://portal.nutanix.com/page/downloads?product=prism) (requires a MyNutanix account). You need both the installation binary (`pc.<version>.tar`) and the metadata file (`generated-pc.<version>-metadata.json`), for a version compatible with your CE release.
2. On the Prism Element home page, click **"Register or create new"** on the Prism Central widget, then **Deploy**.
3. If no compatible version is listed online, click **"Upload Installation Binary"** and provide the two downloaded files.
4. Choose the **X-Small** size (4 vCPU, 18 GiB RAM, 100 GiB disk — sufficient for this lab), give the PC VM a free static IP on the lab network, and deploy.
5. When deployment finishes, register the cluster with the new Prism Central instance and log in once to set the `admin` password.

Note the Prism Central IP and admin password; they go into `settings.json` later.

### Workstation

- PowerShell 7+ (`pwsh`). The initializer runs on Windows and macOS/Linux.
- Terraform in the PATH (used locally to bootstrap the Azure DevOps project).
- A checkout of this repository. (Posh-SSH is installed automatically on first run.)

### Azure DevOps and GitHub

- An Azure DevOps organization.
- An Azure DevOps PAT with **Read, Write & Manage** on both **"Project and Team"** and **"Agent Pools"**. See [`init/README.md`](../README.md) for details.
- A GitHub PAT with read access to the repository (used by the pipelines to check out code).

### Software store

Create a local folder with the installation media. It is uploaded to the control plane during initialization and served by NGINX at `http://<docker-ip>:8080/`:

```
├── Microsoft
│   ├── Server
│   │   ├── windows_server_2019.iso
│   │   ├── windows_server_2022.iso
│   │   └── windows_server_2025.iso
│   ├── Desktop
│   │   └── windows_11.iso
├── Nutanix
│   └── Nutanix-VirtIO-1.2.3.iso
├── Citrix
│   └── ... (only when deploying Citrix roles)
```

- ISO file names must contain the OS marker the pipeline searches for: `windows_11`, `windows_server_2019`, `windows_server_2022`, `windows_server_2025`.
- The `Microsoft/Server` and `Microsoft/Desktop` subfolders match the standard store layout described in [`init/README.md`](../README.md); the image pipeline also falls back to ISOs placed directly in `Microsoft/` if the subfolders are absent.
- The `Nutanix/` folder must contain a [Nutanix VirtIO driver ISO](https://portal.nutanix.com/page/downloads?product=ahv) (any file name containing `virtio`). Windows setup needs its SCSI and network drivers.
- ISOs already present in the Prism image library under the same file name are reused; anything missing is registered by Packer from the store on first build.

### Network plan

Reserve addresses in the lab CIDR before starting. With the example `10.0.0.0/24`:

| Address | Purpose | Where it is configured |
| :------ | :------ | :--------------------- |
| 10.0.0.1 | Gateway / upstream DNS | `network.gateway`, `network.dns` (offsets) |
| 10.0.0.5 | Prism Element endpoint (cluster VIP) | `prism.endpoint` |
| 10.0.0.7 | Prism Central | `prism_central.endpoint` |
| 10.0.0.6 | Control-plane VM | `docker.static_ip` / `docker.ip` |
| 10.0.0.20 | Packer build VM (temporary during image builds) | `build.ip` |
| 10.0.0.10-200 | Workload range used by the pipelines | `network.start` / `network.end` |

The addresses above match `settings.example.json`; adapt them to your subnet. Make sure the reserved addresses do not fall inside a DHCP scope, and that the workload range does not overlap the Prism endpoints or the CVM/AHV host addresses. The network plan script excludes the gateway, DNS, control plane, and build addresses from the workload range automatically.

## 2. Probe Prism Element and collect UUIDs

The settings file needs the cluster, storage container, and subnet UUIDs. The read-only probe records them along with API availability:

```powershell
$prismPassword = Read-Host -AsSecureString
./scripts/nutanix/Test-PrismElement.ps1 -Endpoint 10.0.0.5 -Username admin -Password $prismPassword -SkipCertificateCheck
```

Inspect the generated `scripts/nutanix/prism-element-capabilities.json` and copy the UUIDs. The probe must report the cluster, network, and VM APIs as available.

## 3. Create settings.json

Copy the example and fill in your values:

```powershell
Copy-Item init/nutanix/settings.example.json init/nutanix/settings.json
```

| Setting | Type | Description |
| :------ | :--- | :---------- |
| repo_root | string | Path to this repository on the workstation (native path format). Optional; inferred when omitted or invalid. |
| domain_name | string | The Active Directory domain to create, in FQDN format. |
| ado_url | string | The Azure DevOps organization URL. |
| ado_agents | int | Number of Azure DevOps agent containers to start. |
| prism.endpoint | string | Prism Element IP or FQDN. |
| prism.username | string | Prism Element local user. |
| prism.cluster_uuid | string | Cluster UUID from the probe. |
| prism.storage_container_uuid | string | Storage container UUID from the probe. |
| prism.subnet_uuid | string | Subnet UUID from the probe. |
| prism.insecure | bool | Skip TLS validation (true for the default self-signed certificate). |
| prism_central.endpoint | string | Prism Central IP or FQDN. |
| prism_central.username | string | Prism Central local user (usually `admin`). |
| prism_central.insecure | bool | Skip TLS validation for Prism Central. |
| network.cidr | string | Lab network CIDR, e.g. `10.0.0.0/24`. |
| network.gateway | int | Gateway offset in the CIDR (1 = 10.0.0.1). |
| network.dns | int | Upstream DNS offset in the CIDR. |
| network.start / network.end | int | Workload address range used by the pipelines. |
| docker.name | string | Control-plane VM name (e.g. `dckr-1`). |
| docker.user | string | Control-plane admin user. |
| docker.ip | int | Reserved offset for the control plane (kept for lab-wide conventions). |
| docker.static_ip | string | Full static address for the control plane (e.g. `10.0.0.6`). |
| docker.image_source_uri | string | Ubuntu cloud image URL reachable by Prism. |
| build.user | string | Local admin user baked into golden images. |
| build.ip | int | Offset used by the temporary Packer build VM. |
| software_store | string | Local path to the software store folder. |

## 4. Run the initializer

```powershell
$prismPassword = Read-Host -AsSecureString         # Prism Element password
$prismCentralPassword = Read-Host -AsSecureString  # Prism Central password
$dockerPassword = Read-Host -AsSecureString        # control-plane user password (optional; generated when omitted)

./init/nutanix/init.ps1 `
  -SettingsFile ./init/nutanix/settings.json `
  -AdoPat $adoPat `
  -GitHubPat $githubPat `
  -PrismPassword $prismPassword `
  -PrismCentralPassword $prismCentralPassword `
  -DockerPassword $dockerPassword
```

The script is staged and logs each step: it probes Prism, imports the Ubuntu cloud image, creates and boots the control-plane VM, applies the static address via cloud-init, starts the containers, initializes and seeds Vault, bootstraps the Azure DevOps project with Terraform, uploads the software store, and starts the agent containers. Expect the first run to take 20-40 minutes, dominated by the software store upload.

**Save the Vault root token printed at the end.** The unseal keys are stored as secret pipeline variables in Azure DevOps, but the token is only printed once.

Rerun notes:

- The run is idempotent where practical: images and the VM are reused, containers are recreated.
- Cloud-init only applies on the VM's first boot. After changing anything that affects the control-plane VM (user, password, static IP), rerun with `-RecreateControlPlaneVm`.

## 5. Build the golden images

In the new Azure DevOps project, run **Nutanix CE - 1. Images** (`.devops/pipelines/nutanix/image.yml`). No parameters are required.

The pipeline first starts a temporary dnsmasq DHCP container on the control-plane VM: the Packer build VMs need a DHCP lease for the WinRM connection, and the lab VLAN intentionally has no standing DHCP server (the domain controller provides DHCP once the lab is deployed). The final pipeline stage always removes the container again, even when builds fail.

The **Nutanix CE - Build DHCP** utility pipeline (`.devops/pipelines/nutanix/dhcp.yml`) starts or removes the same container manually via its `enable` parameter — useful when troubleshooting a build VM outside a pipeline run, or to clean up after a cancelled run.

Each stage (Windows 11, Server 2019, 2022, 2025) discovers its ISO in the software store, lets Packer register the ISO plus the VirtIO ISO in the Prism image library, boots a temporary VM, installs Windows unattended, applies Windows updates, and captures the result as a library image (`windows-server-2022-standard`, `windows-desktop-11`, ...). The infra pipeline resolves these images by name directly from the Prism Central image library, so no build artifact is exchanged.

You can cancel or skip stages for images you do not need; the infra pipeline currently requires `windows-server-2022-standard`. A full stage takes roughly 1-2 hours depending on Windows update volume; stages run in parallel across the available agents.

## 6. Deploy the lab

Run **Nutanix CE - 2. Infra** (`.devops/pipelines/nutanix/infra.yml`). Parameters:

| Parameter | Effect |
| :-------- | :----- |
| citrix_cloud | Adds the Citrix Cloud Connector VM. |
| citrix_vad | Adds the Citrix DDC, StoreFront, and license VMs. |
| vmware_horizon | Adds the Horizon connection server VM. |
| loadgen_bots | Adds two LoadGen bot VMs and the bot Ansible stage (off by default). |

The pipeline unseals Vault, provisions the workload VMs through the official `nutanix` Terraform provider against Prism Central (resolving the golden image by name from the image library), deploys the monitoring stack, and runs the Ansible stages: domain, management, SQL, RD Gateway, optional LoadGen bots, Citrix/Horizon when selected, then Windows Updates.

### Timezone

Every Windows machine gets its timezone from the optional `timezone` key in `settings.json`, which the initializer seeds into Vault under `go/domain` (default when omitted: `W. Europe Standard Time`). The value must be a Windows timezone id; the full list is in Microsoft's [Default Time Zones](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones) reference, or run `tzutil /l` on any Windows machine. To change it on an existing lab without re-running the initializer, update the secret directly:

```bash
vault kv put -mount=go domain name=go.euc timezone='GMT Standard Time'
```

### Monitoring stack

The `docker` stage runs the `ansible/monitoring.yml` playbook against the control-plane VM and deploys two containers next to the existing NGINX/Vault/Postgres set:

- **InfluxDB 2.x** on port 8086, initialized non-interactively with the `GO` organization and the `Performance` and `Tests` buckets the GO-EUC dashboards expect.
- **Grafana** on port 3000, with an Influx datasource provisioned under the fixed name `DS_GO`. The GO-EUC dashboard bundle is downloaded and imported automatically on every run; additional dashboard JSON files dropped into `/etc/grafana/dashboards` on the VM are imported too.

All credentials are generated on first run and stored in Vault: `go/influx` (`url`, `org`, `user`, `password`, `token`) and `go/grafana` (`url`, `user`, `password`). Reruns reuse them, so the stage is idempotent. The telegraf agents installed on the workload VMs read the Influx URL, org, and token from `go/influx`, so metrics land in the lab's own InfluxDB instead of the hosted GO-EUC endpoint.

Already running your own Influx/Grafana? Set `monitoring.external` to `true` in `settings.json` with your instance's URL, org, and token before running the initializer (see the [initializer README](README.md#reusing-an-existing-monitoring-stack)). The docker stage then skips the deployment and telegraf reports to your existing stack.

## 7. Customize the build image

Run **Nutanix CE - 3. Delivery** (`.devops/pipelines/nutanix/build.yml`) with the `delivery` parameter (`Citrix`, `VMware`, or `RDSH`) to run the Windows image customization playbook against the build VM.

## Troubleshooting

- **Initializer cannot SSH to the control plane** — the VM boots on DHCP and switches to the static address late in first boot; the script waits for Prism to report the static IP, reboots the VM, and retries. If it times out, open the VM console in Prism and check `/var/log/cloud-init-output.log`. Rerun with `-RecreateControlPlaneVm` after fixing settings.
- **Vault shows "not ready" repeatedly** — check the container on the control plane: `docker logs vault`. The Vault CLI inside the container needs `VAULT_ADDR=http://127.0.0.1:8200`.
- **Pipelines cannot reach Vault/Postgres after a control-plane reboot** — Vault starts sealed; every pipeline begins with an unseal stage using the keys stored as pipeline variables, so simply rerun the pipeline.
- **Packer build hangs at "Waiting for IP"** — open the temporary VM's console in Prism. The most common causes are no DHCP on the lab VLAN (check the `dhcp` container on the control plane: `docker logs dhcp`; the pipeline's first stage should have started it), missing VirtIO drivers (wrong `Nutanix/` ISO), or an ISO whose edition name does not match the autounattend `vm_inst_os_image` value.
- **Image already exists errors in Packer** — the templates set `force_deregister`, so stale images are replaced; genuine duplicates of the *source ISO* are tolerated. Clean out duplicate ISO entries in the image library if they accumulate.
- **Terraform apply fails with Azure DevOps 401/403** — recreate the Azure DevOps PAT with Read, Write & Manage on "Project and Team" and "Agent Pools".
