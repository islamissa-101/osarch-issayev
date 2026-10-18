# Lab 1 — Your first virtual machine

Pair: Student / Partner            Driver first half: Student
Machine: Host (Windows 11), Guest (Ubuntu Server)
Date: 18.10.2026

## What I did
1. Created a new virtual machine in VMware Workstation Pro.
2. Configured VM hardware parameters (vCPU, RAM, Disk) based on Host measurements from Lab 0.
3. Installed Ubuntu Server Edition (without GUI).
4. Executed `lsb_release -a` in the guest terminal to capture OS release details.
5. Created a baseline system snapshot named `clean-install`.
6. Intentionally broke the guest system by removing the `/etc/hostname` file (`sudo rm /etc/hostname`).
7. Verified system breakage, restarted the VM, and executed a rollback to the `clean-install` snapshot.

## Result
Allocated **6 GB RAM** (6144 MB), **2 vCPUs**, and **20 GB Disk space**. This configuration matches the recommended memory size for Ubuntu Server while providing smooth performance for lab tasks.

## What did not work the first time
1. During the execution of `sudo rm /etc/hostname`, password authentication failed multiple times due to Linux hiding characters on input by default.
2. Terminal output was temporarily distorted by background system kernel logs (`irq 19`), creating the illusion that the console froze. Resolved by pressing `Ctrl + C` to clear the prompt line and entering the password carefully.

## Evidence
- [evidence/vm-settings.png](evidence/vm-settings.png) — screenshot of VM hardware parameters
- [evidence/guest-release.txt](evidence/guest-release.txt) — output of `lsb_release -a`
- [evidence/broken.png](evidence/broken.png) — guest system in broken state (removed `/etc/hostname`)
- [evidence/snapshot-list.png](evidence/snapshot-list.png) — snapshot manager showing `clean-install` state after rollback
