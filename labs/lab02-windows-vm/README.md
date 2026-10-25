# Lab 2 — A Windows guest, and a network between them

Pair: Issayev / <Фамилия_Напарника>
Driver first half: Issayev
Machine: Host (Windows 11, 16 GB RAM), Guest 1 (Ubuntu Server), Guest 2 (Windows 11)
Date: 25.10.2026

## What I did
1. Built a Windows 11 Enterprise evaluation VM with 2 vCPUs, 4 GB RAM, 64 GB thin disk, UEFI, and virtual TPM 2.0.
2. Selected VMware NAT (VMnet8) network mode for both guests.
3. Retrieved IPv4 addresses: Windows (`192.168.34.135`), Linux (`192.168.34.133`).
4. Configured an inbound ICMP rule on Windows Defender Firewall via PowerShell:
   ```powershell
   New-NetFirewallRule -DisplayName "Lab02 - allow ping (ICMPv4 echo)" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress LocalSubnet -Action Allow
   ```
5. Verified bidirectional ICMP connectivity (ping) between both VMs.
6. Conducted a memory overcommitment experiment by promising 20 GB RAM across guests on a 16 GB host.
## Network Choice Justification
I used VMware NAT (VMnet8) mode for both guests. Requirement: the guests must reach each other and the internet. VMware NAT meets both because VMnet8 provides a virtual switch with internal DHCP and an outbound NAT gateway (192.168.34.2). I did not use bridged mode because campus network MAC filtering silently drops unregistered guest MAC addresses. I did not use host-only because it blocks internet access.
## Network Diagram
                     Internet
                      |
           [ Host: Physical Laptop ]
                      |
        ( VMware NAT Router: 192.168.34.2 )
                      |
======== Virtual Switch: VMnet8 (NAT) ========
        |                           |
[ osarch-lab01 ]             [ lab02-win11 ]
Interface: ens33             Interface: Ethernet0
IP: 192.168.34.133           IP: 192.168.34.135
## Overcommitment Experiment Result
Host Total RAM: 16 GB
Sum Promised to Guests: 20 GB (Linux: 8 GB, Windows: 12 GB) — Ratio ~1.25x
Before Load: Host available RAM was ~8.5 GB with minimal compression/swap.
Under Load: Host available RAM dropped sharply below 1 GB, memory compression and swap usage increased on the host, leading to noticeable UI responsiveness degradation under heavy memory stress.
## What did not work the first time
Initial ping from Linux to Windows failed with 100% packet loss. Windows Defender Firewall assigned the Public network category to the new network interface and dropped incoming ICMPv4 echo requests by default. The issue was solved by adding a targeted inbound firewall rule for ICMP type 8 rather than disabling the firewall.
## Evidence
evidence/ipconfig-windows.txt — Output of ipconfig on Windows guest.
evidence/ip-addr-linux.txt — Output of ip addr on Linux guest.
evidence/ping-both-ways.txt — Bidirectional ping command outputs.
evidence/host-memory-before.png — Host memory state before overcommit test.
evidence/host-memory-after.png — Host memory state during overcommit load.
