# Feedback on Islam's BUILD.md
Reviewer: Saiazhan
Commit reviewed: https://github.com/islamissa-101/osarch-issayev/tree/main/tickets/ticket1-vm-build-doc
Hypervisor I used: VMware Fusion 13.5 (Host: macOS Sonoma, Apple Silicon M-series ARM64)

## First step where I got stuck
Step number: Step 1 / Prerequisites
What the step says: "Prerequisites: Hypervisor: VMware Workstation Pro / Player (version 17 or higher); Host OS: Windows 11 (64-bit)" / Step 1: "Click File -> New Virtual Machine (or press Ctrl+N)".
What I did: Attempted to follow the guide on my host machine, which is a MacBook running macOS on Apple Silicon.
What happened / what I had to guess: VMware Workstation is a Windows/Linux-only application and cannot be installed on macOS. On a Mac, the equivalent hypervisor is VMware Fusion. Because of this prerequisite lock, I could not follow the exact menu paths or shortcut keys (`Ctrl+N`). More critically, modern Macs run on ARM64 architecture; if I downloaded the standard x86_64 Ubuntu ISO implied in Step 2, VMware Fusion would refuse to boot it without x86 emulation. To proceed with evaluating the build logic, I had to translate the instructions to VMware Fusion on macOS and substitute the installation media with the Ubuntu Server ARM64 ISO.

## Other places I hesitated
- Step 2 & Step 7 (Easy Install conflict): In Step 2, the guide instructs to select the installer ISO file directly during the wizard. On modern VMware hypervisors, selecting an Ubuntu ISO triggers the automated "Easy Install" mechanism, which skips the manual console installer prompts (network setup, disk partitioning, and OpenSSH checkbox) described in Step 7. I hesitated because the screens in Step 7 did not appear during boot until I re-created the VM selecting "I will install the operating system later".
- Scope of Work (Missing Windows Guest): Ticket 1 requires demonstrating a complete test environment with inter-guest communication between Linux and Windows. The guide stops after Step 9 (clean snapshot of Ubuntu) and completely omits the build, hardware sizing, and configuration steps for the companion Windows 11 virtual machine.
- Memory sizing ambiguity (Step 5): The guide suggests "2048 MB (or 4096 MB depending on your host RAM)". As a reader, I was unsure which value to choose to keep enough memory available for both the host and the second VM.

## Settings I would not have chosen without the document
- Selecting "Store virtual disk as a single file" (Step 4) instead of the default split disk layout, justified by improved random I/O throughput on modern host NVMe SSDs.
- Explicitly choosing NAT mode (VMnet8) in Step 6, backed by a clear and accurate explanation that campus/office Wi-Fi networks block bridged virtual machines due to MAC address filtering.

## One thing that worked well
- Step 9 (creating a baseline snapshot immediately after installation) is clearly documented with an explicit rationale that directly maps back to the office manager's requirement: enabling the developer to "try things without breaking anything".
