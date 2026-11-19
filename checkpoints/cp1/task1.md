# Checkpoint 1 — Task 1

## 1a. The computer in front of you

Raw output for every figure is in `evidence/task1.txt`.

| Figure | This computer | Command it came from |
|---|---|---|
| CPU model | Intel Core i7-14650HX | `Get-CimInstance Win32_Processor` → Name |
| Cores / logical processors | 16 cores / 24 logical processors | `Get-CimInstance Win32_Processor` → NumberOfCores, NumberOfLogicalProcessors |
| Hardware virtualization: supported? enabled in firmware? | Supported: yes. Enabled in firmware: yes. The three WMI flags read `False`, but `HyperVisorPresent` is `True` and `systeminfo` reports "Обнаружена низкоуровневая оболочка" (a hypervisor has been detected). When the Windows hypervisor (VBS / Virtual Machine Platform) is already running, Windows hides these flags. The hypervisor could not start unless VT-x were enabled in firmware. | `Get-CimInstance Win32_Processor`; `(Get-ComputerInfo).HyperVisorPresent`; `systeminfo \| Select-String "Hyper-V\|гипервизор\|hypervisor"` |
| Memory: total / available now | 31.6 GiB total / 20.6 GiB available (33 147 576 KB / 21 552 084 KB; KB ÷ 1 048 576 = GiB) | `Get-CimInstance Win32_OperatingSystem` → TotalVisibleMemorySize, FreePhysicalMemory |
| System disk: size, free space, SSD or HDD | Volume C: 952.9 GiB, 524.4 GiB free (bytes ÷ 1024³). Physical disk: WD PC SN5000S 1 TB, NVMe SSD | `Get-Volume -DriveLetter C` → Size, SizeRemaining; `Get-PhysicalDisk` → MediaType, BusType |
| Partition style of the system disk | GPT | `Get-Disk` → PartitionStyle |
| OS and version | Windows 11 Home, 64-bit, version 26H2 (build 26300.9974) | `Get-CimInstance Win32_OperatingSystem` → Caption, Version, OSArchitecture; `Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'` → DisplayVersion, CurrentBuild, UBR |

Notes:
- PowerShell was run elevated (prompt `C:\Windows\System32`). Without administrator rights `Get-Disk` may return "Access denied"; the fallback is `Get-CimInstance Win32_DiskPartition | Select Name, Type` (type starts with `GPT:` on a GPT disk).
- Windows 11 **Home** has no Hyper-V Manager. The guests run in VMware Workstation Pro (as in Labs 1–2), which runs on top of the already-active Windows hypervisor. This matters for Task 2.

## 1b. A machine you have never seen: thin-and-light laptop

### Guest sizes (from my Labs 1–2 build log)

| Guest | vCPU | Memory | Disk | Source |
|---|---|---|---|---|
| Ubuntu Server (`osarch-lab01`) | 2 | 6 GB (6144 MB) | 20 GB, growable (VMware default; type not recorded in the log) | Lab 1, "Result" |
| Windows 11 Enterprise eval (`lab02-win11`) | 2 | 4 GB | 64 GB, thin | Lab 2, "What I did" |
| **Total** | **4** | **10 GB** | **84 GB virtual size** | |

Hypervisor used in the labs: VMware Workstation Pro.

### Assumptions for the host itself

| Resource | What the host keeps for itself | Why |
|---|---|---|
| CPU | at least 1 thread | Windows, the VMware processes and the guests' I/O need CPU time |
| Memory | about 3 GB | Windows 11 needs 4 GB to install; while running with a browser and VMware it uses roughly 3 GB |
| Disk | at least 15 GB free | Windows Update, the page file, VMware swap files (`.vmem`) and temporary files; a full system disk breaks the host |

### 1. Could it run both guests at the same time?

**No. As delivered it can't run any guest, and even once that is fixed, memory and disk don't fit.**

**Blocker before any arithmetic: the OS.** Windows 11 Home in S mode installs apps only from the Microsoft Store. VMware Workstation Pro is installed from a downloaded installer, so S mode blocks it (the same goes for VirtualBox). Home also does not include Hyper-V. AMD-V is supported and enabled, so the hardware is not the problem; the OS is.

Suppose S mode is switched off. The arithmetic then looks like this:

| Resource | Available | Guests need | Host needs | Balance | Verdict |
|---|---|---|---|---|---|
| CPU | 4 threads | 2 + 2 = 4 vCPU | ≥ 1 | 4 − 4 = 0 left for the host | Starts (vCPUs can be overcommitted), but the host and both guests share 4 threads at 1.1 GHz, so it is effectively unusable |
| Memory | 8 GB | 6 + 4 = 10 GB | ~3 GB | 8 − 10 − 3 = **−5 GB** | **Does not fit.** The guests alone already exceed the whole machine (10 > 8) |
| Disk (as built: growable/thin) | 31 GB free | actually written after install: ~5 GB (Ubuntu) + ~22 GB (Windows 11) ≈ 27 GB, growing towards 84 GB | 15 GB | 31 − 27 − 15 = **−11 GB** | **Does not fit**, and gets worse with every update inside the guests |
| Disk (if fixed/preallocated) | 31 GB free | 20 + 64 = 84 GB | 15 GB | 31 − 84 − 15 = **−68 GB** | **Does not fit** |

**On memory overcommit:** VMware Workstation will let me promise more RAM than the host has, but my own Lab 2 experiment shows the cost. On a 16 GB host at a ratio of about 1.25× (20 GB promised), available host RAM fell below 1 GB, memory compression and swap kicked in, and the host UI became noticeably slow. Here the ratio would be (10 + 3) / 8 ≈ **1.6×**, and the swap would land on a slow eMMC. So overcommit is not a workaround.

Even with the Ubuntu guest cut to its real need, it still doesn't fit. Ubuntu Server's documented minimum is 1.5 GB (ISO install) and its suggested minimum is 3 GB, so the 6 GB in my Lab 1 log is more than a CLI server needs. At 2 GB: 8 − (2 + 4) − 3 = **−1 GB**, still short. The Windows 11 guest cannot go below its 4 GB minimum.

### 2. What to upgrade or change first

**Hardware: nothing can be upgraded.** The memory is LPDDR4X soldered to the board, and the 128 GB eMMC is soldered too. There are no RAM slots and no M.2 slot.

**First change: switch out of S mode** (Settings → System → Activation → Switch out of S mode, through the Microsoft Store). It is free, but one-way. It comes first because it is the only thing standing between this laptop and running *any* guest, and it is the only thing on this machine that can actually be changed.

Then, what I would do instead of an upgrade:
1. **Run one guest at a time, sized down.** Ubuntu Server alone at 1–2 vCPU and 2 GB RAM fits: 8 − 2 − 3 = 3 GB left for the host, about 5 GB of disk actually used. The Windows 11 guest alone (4 GB) fits on memory (8 − 4 − 3 = 1 GB, tight) but leaves only about 31 − 22 = 9 GB of disk, below my 15 GB host reserve.
2. **Put the VM disks on an external USB 3 SSD.** That removes the 31 GB limit and is faster than the eMMC. It does not fix memory, so it still does not allow both guests at once.
3. **For both guests at the same time, use a different machine**, for example the computer from 1a (31.6 GiB RAM, 24 logical processors, 524 GiB free on NVMe), or a cloud VM. On 8 GB of soldered RAM, running both together is not possible.
