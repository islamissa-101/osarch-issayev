# Lab 0 — Inventory your own machine
Pair: Issayev / <none>    Driver first half: Issayev
Machine: Windows 11 / ASUS Laptop
Date: 08.10.2026

## What I did
Collected hardware specifications using PowerShell commands and saved raw evidence to .txt files.

## Result
| What | Value | Where I got it |
| :--- | :--- | :--- |
| **CPU Model** | <Intel(R) Core(TM) i7-14650HX> | `Get-CimInstance Win32_Processor` |
| **Cores / Threads** | <16 Cores / 24 Threads> | `Get-CimInstance Win32_Processor` |
| **Total RAM / Modules** | <32 GB (2x 16GB Modules, 5600 MHz)> | `Get-CimInstance Win32_PhysicalMemory` |
| **Disk Model / Type** | < NVMe WD PC SN5000S SDEQNSJ-1T00-1002 E823_8FA6_BF53_0001_001B_448B_42AD_ACE0> | `Get-PhysicalDisk` |
| **Free Volume Space** | < 752.13 GB> | `Get-Volume -DriveLetter C` |
| **Firmware Type / Date** | UEFI | `$env:firmware_type` |
| **Virtualization** | Enabled | `Get-CimInstance Win32_Processor` |

## What did not work the first time
When executing PowerShell commands to combine disk evidence, a syntax error occurred due to using a comma instead of subexpression syntax `$()`. Resolved it by wrapping the commands properly.

## Evidence
- [evidence/cpu.txt](evidence/cpu.txt) — CPU model, core, and thread count
- [evidence/memory.txt](evidence/memory.txt) — RAM total capacity and installed modules
- [evidence/disk.txt](evidence/disk.txt) — Disk model and free space on volume C: