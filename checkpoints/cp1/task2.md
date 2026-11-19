# Checkpoint 1 — Task 2: Plan and justify

**Host (figures from Task 1a):** Intel Core i7-14650HX, 16 cores / 24 logical processors, VT-x enabled (Windows hypervisor already active), 31.6 GiB RAM with 20.6 GiB available at measurement time, C: 952.9 GiB NVMe SSD with 524.4 GiB free, GPT, Windows 11 Home 26H2.

**Hypervisor:** VMware Workstation Pro, as in Labs 1–2. Windows 11 Home has no Hyper-V Manager, so Hyper-V is not an option. VMware runs on top of the active Windows hypervisor, which costs some performance, but it works.

**Verdict:** this computer can run both guests at the same time with a large margin. No resource has to be set below a minimum.

## 1. Allocation

| Setting | Ubuntu Server guest | Windows 11 guest |
|---|---|---|
| vCPUs | 2 | 4 |
| Memory | 4 GB (4096 MB) | 8 GB (8192 MB) |
| Disk size | 25 GB | 80 GB |
| Disk type | Dynamically allocated (VMware "growable"), single file | Dynamically allocated (VMware "growable"), single file |
| Firmware | UEFI | UEFI + Secure Boot, virtual TPM 2.0 |
| Network adapter(s) | 1 adapter, **NAT (VMnet8)** | 1 adapter, **NAT (VMnet8)** |
| IP address | Static `192.168.34.20/24`, gateway and DNS `192.168.34.2` (outside the VMnet8 DHCP pool, which starts at `.128`) | DHCP from VMnet8 |
| Other | `openssh-server` installed, `ssh` service enabled | — |

## 2. Arithmetic

### Assumptions for the host itself

| Resource | Host keeps | Basis |
|---|---|---|
| CPU | ≥ 4 logical processors | Windows, browser, VMware UI and the VMs' I/O threads |
| Memory | ≥ 8 GB, plus about 1 GB of VMware overhead for two running VMs | Measured: the host was already using 31.6 − 20.6 = **11.0 GiB** with my normal apps open, so I plan against that real figure, not a guess |
| Disk | ≥ 50 GB free | Windows Update, page file, temporary files, room for snapshots |

### Balance

| Resource | Host has | Guests take | Left for host | Host needs | OK? |
|---|---|---|---|---|---|
| CPU | 24 logical | 2 + 4 = 6 vCPU | 24 − 6 = **18** | ≥ 4 | Yes, 25% of logical processors given to guests |
| Memory | 31.6 GiB | 4 + 8 = 12 GB + ~1 GB VMware overhead = 13 GB | 31.6 − 13 = **18.6 GiB** | 11.0 GiB in use now (≥ 8 GB minimum) | Yes: 18.6 − 11.0 = **~7.6 GiB still free** with both guests running and my normal apps open |
| Disk (worst case, fully grown) | 524.4 GiB free | 25 + 80 = 105 GB disks + 12 GB `.vmem` paging files (VMware creates one per running VM, the size of its RAM) = 117 GB | 524.4 − 117 = **~407 GiB** | ≥ 50 GB | Yes |
| Disk (right after install) | 524.4 GiB free | ~5 GB (Ubuntu) + ~22 GB (Windows 11) + 12 GB `.vmem` ≈ 39 GB | ~485 GiB | ≥ 50 GB | Yes |

Memory overcommit ratio: (12 + 11) / 31.6 ≈ **0.73×**, under 1. Compare my Lab 2 experiment: at 1.25× on a 16 GB host, available RAM dropped below 1 GB and the UI slowed down. This plan stays well clear of that.

## 3. Justification

**Network mode: NAT (VMnet8) for both guests, one adapter each.**
- In VMware, NAT is enough for both requirements. The host gets its own virtual adapter on VMnet8 ("VMware Network Adapter VMnet8", `192.168.34.1`), so it can reach the Ubuntu guest directly at `192.168.34.20`, and `ssh` works with no port forwarding. The NAT gateway `192.168.34.2` gives the guest internet access.
- *Not bridged:* it would put the test server on the office LAN, visible to every machine there, which a test lab does not need. It also depends on the physical network: on campus, MAC filtering silently dropped unregistered guest MACs (seen in Lab 2). On Wi-Fi bridging can be unreliable, and if the laptop changes networks, the guest's IP changes.
- *Not host-only (VMnet1) alone:* it gives `ssh` from the host but no internet access, so it fails the second requirement.
- *Not NAT + host-only (two adapters):* that is the usual answer in VirtualBox, where NAT does not let the host in. In VMware the host is already on VMnet8, so a second adapter adds routing complexity and nothing else.
- *Static IP for Ubuntu:* the `ssh` target must not change. A DHCP lease can change after the VM is rebuilt or the lease expires. `.20` is outside the VMnet8 DHCP pool (`.128–.254`), so it cannot collide with a lease.

**CPU.**
- Ubuntu at 2 vCPU: a CLI server for a test lab does not need more, and 2 gives the installer and `apt` room.
- Windows 11 at 4 vCPU rather than 2: the minimum is 2 cores, but a desktop OS with updates and Defender scans is much more responsive with 4. The host has 18 logical processors spare.
- Not more: on a hybrid CPU (8 P-cores + 8 E-cores), large vCPU counts can land on E-cores and gain little. 6 of 24 keeps the host clearly usable.

**Memory.**
- Ubuntu at 4 GB, not the 6 GB from my Lab 1 log: Ubuntu Server's documented minimum is 1.5 GB (ISO install) and its suggested minimum is 3 GB. 4 GB is above both, and 6 GB was more than a CLI server needs.
- Windows 11 at 8 GB, not 4: 4 GB is the minimum and makes the guest sluggish. The host can afford 8 and still keep ~7.6 GiB free.

**Disk.**
- *Dynamically allocated rather than fixed:* a fixed disk would claim 105 GB at once for a lab that uses about 27 GB. On an NVMe SSD the speed difference is small. With 524 GiB free there is no risk that the thin disks outgrow the host, even fully grown (worst case leaves ~407 GiB).
- *Single file rather than split into 2 GB files:* the host's file system is NTFS, so there is no file-size limit to work around, and a single file is simpler to copy or back up.
- Ubuntu at 25 GB (minimum 5 GB): room for logs, packages and test data. Windows 11 at 80 GB (minimum 64 GB): room for feature updates, which need several GB of free space inside the guest.

**Below a minimum:** nothing. Windows 11's requirements (2 cores, 4 GB, 64 GB, UEFI + Secure Boot, TPM 2.0) are all met. VMware's virtual TPM requires the VM to be encrypted; I would use the option that encrypts only the files needed for the TPM.

## 4. Verification plan

### On the host: VM configuration as saved

| Command (PowerShell on host) | Expected output |
|---|---|
| `Select-String -Path "$env:USERPROFILE\Documents\Virtual Machines\osarch-lab01\osarch-lab01.vmx" -Pattern 'numvcpus\|memsize\|ethernet0.connectionType'` | `numvcpus = "2"`, `memsize = "4096"`, `ethernet0.connectionType = "nat"` |
| `Select-String -Path "$env:USERPROFILE\Documents\Virtual Machines\lab02-win11\lab02-win11.vmx" -Pattern 'numvcpus\|memsize\|ethernet0.connectionType\|vtpm.present\|firmware'` | `numvcpus = "4"`, `memsize = "8192"`, `ethernet0.connectionType = "nat"`, `vtpm.present = "TRUE"`, `firmware = "efi"` |
| `& "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" list` | `Total running VMs: 2` and both `.vmx` paths |

### Inside the Ubuntu guest: the resources it actually sees

| Command | Expected output |
|---|---|
| `nproc` | `2` |
| `free -h` | `Mem:` total about `3.8Gi` (a little under 4 GB; the kernel reserves some) |
| `lsblk` | `sda` `25G` |
| `df -h /` | Root file system on `/dev/mapper/ubuntu--vg-ubuntu--lv`. If it shows only ~12G, the installer's default LVM layout left part of the disk unused; `sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv` gives it the full ~24G |
| `ip -br a` | `ens33  UP  192.168.34.20/24` |
| `ip route` | `default via 192.168.34.2 dev ens33` |
| `systemctl is-active ssh` / `systemctl is-enabled ssh` | `active` / `enabled` |

### SSH from the host

| Command (PowerShell on host) | Expected output |
|---|---|
| `ipconfig` | Section "VMware Network Adapter VMnet8" with IPv4 `192.168.34.1` |
| `Test-NetConnection 192.168.34.20 -Port 22` | `TcpTestSucceeded : True` |
| `ssh isko@192.168.34.20 hostname` | the Ubuntu guest's hostname, e.g. `osarch-lab01` |

### Internet from the Ubuntu guest

| Command | Expected output |
|---|---|
| `ping -c 3 1.1.1.1` | `3 packets transmitted, 3 received, 0% packet loss` (proves routing through the NAT gateway) |
| `resolvectl query ubuntu.com` | one or more IPv4/IPv6 addresses (proves DNS) |
| `curl -sI https://ubuntu.com \| head -1` | `HTTP/2 200` (proves real outbound HTTPS) |
| `sudo apt update` | ends without `Failed to fetch` errors |

### Inside the Windows 11 guest

| Command (PowerShell) | Expected output |
|---|---|
| `Get-CimInstance Win32_ComputerSystem \| Select NumberOfLogicalProcessors, TotalPhysicalMemory` | `4`, about `8.5E+09` (about 8 GiB in bytes) |
| `Get-Volume -DriveLetter C \| Select Size, SizeRemaining` | `Size` about 79 GiB (85 000 000 000 bytes or so) |
| `Get-Tpm` (as administrator) | `TpmPresent : True`, `TpmReady : True` |
| `Confirm-SecureBootUEFI` (as administrator) | `True` |
| `Test-NetConnection 1.1.1.1` | `PingSucceeded : True` |

### The host stays usable (both guests running)

| Command (PowerShell on host) | Expected output |
|---|---|
| `Get-CimInstance Win32_OperatingSystem \| Select TotalVisibleMemorySize, FreePhysicalMemory` | `FreePhysicalMemory` around 7–8 GiB (≈ 7 500 000–8 500 000 KB), not below ~4 GiB |
| `Get-Volume -DriveLetter C \| Select SizeRemaining` | still about 480+ GiB after both installs |
| `Get-Counter '\Processor(_Total)\% Processor Time'` (on Russian Windows: `Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'"` → `PercentProcessorTime`) | low at idle (under ~20%), with both guests idle |
