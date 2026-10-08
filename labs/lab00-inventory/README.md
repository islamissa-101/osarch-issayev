# Lab 0 — Inventory your own machine
Pair: Issayev / <none>    Driver first half: Issayev
Machine: Windows 11 / ASUS Laptop
Date: 08.10.2026

## What I did
Collected hardware specifications using PowerShell commands and saved raw evidence to .txt files.

## Result
| What | Value | Where I got it |
| :--- | :--- | :--- |
| **CPU Model** | <Ваша модель из cpu.txt> | `Get-CimInstance Win32_Processor` |
| **Cores / Threads** | <Ядра / Потоки из cpu.txt> | `Get-CimInstance Win32_Processor` |
| **Total RAM / Modules** | <Объём и число плашек из memory.txt> | `Get-CimInstance Win32_PhysicalMemory` |
| **Disk Model / Type** | <Модель диска из disk.txt> | `Get-PhysicalDisk` |
| **Free Volume Space** | <Свободное место на диске C из disk.txt> | `Get-Volume -DriveLetter C` |
| **Firmware Type / Date** | UEFI | `$env:firmware_type` |
| **Virtualization** | Enabled | `Get-CimInstance Win32_Processor` |

## What did not work the first time
When executing PowerShell commands to combine disk evidence, a syntax error occurred due to using a comma instead of subexpression syntax `$()`. Resolved it by wrapping the commands properly.

## Evidence
- [evidence/cpu.txt](evidence/cpu.txt) — CPU model, core, and thread count
- [evidence/memory.txt](evidence/memory.txt) — RAM total capacity and installed modules
- [evidence/disk.txt](evidence/disk.txt) — Disk model and free space on volume C: