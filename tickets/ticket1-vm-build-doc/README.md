# Ticket 1: Virtual Machine Build Documentation & Developer Environment Setup

## 1. What was asked
> From: Aigerim T. (Office Manager)  
> Subject: test machine for new dev  
> Hi, we have someone starting on Monday and he needs a test computer set up. Nothing special, just so he can try things without breaking anything. Can you write down how to do it so I can do the next one myself? Thanks

---

## 2. What was actually needed
The original request from the office manager contained several critical technical omissions, flawed assumptions, and scope ambiguities that required engineering analysis rather than literal execution:

1. **Physical Machine vs. Isolated Virtual Environment:**
   The request asks for a "test computer set up ... so he can try things without breaking anything." Deploying a dedicated physical PC for exploratory development is wasteful, slow to recover, and poses security risks if connected directly to the corporate LAN. The actual technical requirement is an **isolated virtual machine equipped with point-in-time snapshots**, enabling the developer to safely execute untested code, kernel modules, or administrative scripts with the ability to revert to a known good state in seconds.

2. **Unrealistic Expectations of Self-Service Delegation:**
   The office manager assumed that configuring a hypervisor environment can be reduced to a mechanical checklist that non-technical personnel can repeat ("so I can do the next one myself"). In reality, hypervisor deployment involves host resource budgeting (avoiding host RAM starvation), virtual network topology selection (NAT vs. Bridged), firewall policy management, and storage allocation trade-offs. The documentation in `BUILD.md` was therefore written with defensive defaults, clear architectural justifications, and explicit prerequisites.

3. **Missing Hardware and Workload Specifications:**
   The ticket specified neither the host hardware budget nor the developer's tech stack (guest OS requirements, compilation toolchains, runtime environments, or network port forwarding). 

4. **Engineering Assumptions Made:**
   - **Guest OS:** Deployed **Ubuntu Server 24.04 LTS (64-bit)** as the primary Linux testing sandbox, supplemented by a **Windows 11** guest environment to satisfy cross-platform testing and inter-guest networking requirements.
   - **Networking:** Implemented a private host-segmented **NAT network (`VMnet8` / `192.168.34.0/24`)** rather than Bridged networking. This guarantees outbound internet access for package installations, bypasses external campus/corporate Wi-Fi MAC filtering, and isolates host LAN peers from guest experimentation.
   - **Host Resource Budgeting:** Preserved 50% of host RAM for the host OS to prevent thrashing, allocating minimal viable memory tiers to each guest.

---

## 3. What I did

### Step-by-Step Actions
1. Created the standardized project directory structure: `tickets/ticket1-vm-build-doc/` with dedicated `evidence/` and `review/` directories.
2. Formulated a step-by-step procedural guide (`BUILD.md`) targeting a novice reader, incorporating technical justifications for all configuration choices.
3. Created a Linux virtual machine (`osarch-lab01`) running Ubuntu 24.04 LTS and verified hardware resource allocations.
4. Attached the virtual network adapter to VMware Workstation's NAT virtual switch (`VMnet8`), establishing a deterministic subnet (`192.168.34.0/24`).
5. Configured and booted the companion Windows 11 guest machine (`192.168.34.135`), establishing bidirectional ICMP connectivity between the Linux guest (`192.168.34.133`) and Windows guest.
6. Captured a clean baseline snapshot named `Clean Base Install` immediately following OS installation and OpenSSH configuration.

### Resource Budgeting Calculation
The host machine has **16 GB of physical RAM** and an SSD storage pool:
- **Host System (Windows 11):** Reserved **10 GB RAM** to guarantee smooth host execution, IDE usage, and background OS processes without swapping.
- **Linux Guest (`osarch-lab01`):** Allocated **2048 MB (2 GB) RAM**, **2 vCPUs**, and a **25 GB dynamically expanding virtual disk (stored as a single file)**. Since Ubuntu Server runs headless without a desktop GUI, 2 GB provides ample headroom for kernel builds and container experimentation.
- **Windows 11 Guest:** Allocated **4096 MB (4 GB) RAM**, **2 vCPUs**, and a **40 GB virtual disk** to meet minimum Windows 11 virtualization requirements.
- **Total RAM Allocated:** 10 GB (Host) + 2 GB (Linux) + 4 GB (Windows) = **16 GB** (100% capacity accounted for, zero overcommitment).

### Non-Default Configuration Settings & Justifications
- **Virtual Disk as a Single File:** Selected instead of the default 2 GB split files to maximize disk I/O performance across host NVMe storage.
- **NAT Network Mode (`VMnet8`):** Selected over Bridged mode because corporate/university Wi-Fi infrastructure frequently blocks multiple MAC addresses per physical port or requires 802.1X captive portal re-authentication.

### Troubleshooting: What Went Wrong and How It Was Resolved
- **Problem:** When attempting to verify network reachability from the Linux VM (`192.168.34.133`) to the Windows VM (`192.168.34.135`), all ICMP echo requests timed out (`100% packet loss`), despite both machines successfully pinging the default gateway (`192.168.34.2`) and public DNS (`8.8.8.8`).
- **Diagnosis:** The Windows Defender Firewall blocks incoming ICMPv4 Echo Requests by default across private and public profiles.
- **Resolution:** Rather than disabling the firewall (which violates basic system security standards), a targeted inbound firewall rule was added via PowerShell with administrative privileges on the Windows guest:
  ```powershell
  New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow
