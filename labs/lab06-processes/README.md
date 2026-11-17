# Lab 6 — Live processes and memory pressure

Pair: Issayev / Duisebai         Driver first half: Issayev
Machine: VMware Workstation host; guests `osarch-lab01` (Ubuntu Server, 5.2 GiB RAM) and `DESKTOP-FMRQHJ6` (Windows 11 Enterprise eval)
Date: 17.11.2026

## What I did

### Part 1 — one process, three tools

The process is one SSH connection, seen from both ends: the client `ssh.exe` on the Windows guest
and the session process `sshd-session: isko@pts/0` on the Linux guest. Both sides belong to the same
login and were captured during the same session.

Preparation on Linux (the SSH server was not running):

```bash
systemctl is-active ssh            # inactive
sudo systemctl enable --now ssh
systemctl is-active ssh            # active
```

Windows guest, open the connection and read the process from the command line:

```powershell
ssh isko@192.168.34.133
Get-CimInstance Win32_Process -Filter "Name='ssh.exe'" |
  Select ProcessId,ParentProcessId,HandleCount,WorkingSetSize,PrivatePageCount | Format-List
Get-Process -Id (Get-CimInstance Win32_Process -Filter "Name='ssh.exe'").ParentProcessId |
  Select Id,ProcessName
```

Then Task Manager → Details (added columns Handles, Commit size, Memory (private working set)),
and Process Explorer → `ssh.exe` → Properties → Image / Performance tabs.

Linux guest:

```bash
ps -eo pid,ppid,user,rss,vsz,cmd | grep "[s]shd"
grep -E 'Name|^Pid|PPid|VmSize|VmRSS' /proc/2654/status
sudo ls /proc/2654/fd | wc --lines
htop -p 2595,2654                  # F5 tree, F2 → added PPID column
ps -eo pid,ppid,cmd | grep "[s]shd"
systemctl status ssh --no-pager | head -n 5
```

### Part 2 — memory pressure on Linux

The guest had no swap, so a 1 GiB swap file was created first:

```bash
sudo fallocate --length 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Before / during / after, written to one file:

```bash
mkdir -p ~/lab06 && cd ~/lab06
{ echo "=== BEFORE $(date +%T) ==="; free -h; swapon --show; } | tee memory-pressure.txt

# second terminal (SSH session)
echo "=== DURING ===" >> memory-pressure.txt
while true; do echo "--- $(date +%T)"; free -h; sleep 2; done | tee -a memory-pressure.txt

# first terminal: allocate 50 MiB every 0.5 s until something gives
python3 -c "
import time
a = []
while True:
    a.append(b'x' * (50*1024*1024))
    print(len(a)*50, 'MiB', flush=True)
    time.sleep(0.5)
"

{ echo "=== AFTER $(date +%T) ==="; free -h; swapon --show; } | tee -a memory-pressure.txt
sudo journalctl -k --since today | grep -i -E "oom|out of memory|killed process" | tee kernel-log-extract.txt
```

### Part 3 — the same class of event on Windows

```powershell
$blocks = New-Object System.Collections.Generic.List[IntPtr]
try {
  while ($true) {
    $blocks.Add([System.Runtime.InteropServices.Marshal]::AllocHGlobal(512MB))
    $c = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples[0].CookedValue
    "{0} MB allocated, commit {1:N1}%" -f ($blocks.Count*512), $c
  }
} catch { "Allocation failed: $($_.Exception.Message)" }
Start-Sleep 90
$blocks | ForEach-Object { [System.Runtime.InteropServices.Marshal]::FreeHGlobal($_) }

Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-Resource-Exhaustion-Detector'} -MaxEvents 5 |
  Format-List TimeCreated,Id,Message
```

## Result

### Three-tool comparison

| | Task Manager (`ssh.exe`) | Process Explorer (`ssh.exe`) | htop (`sshd-session`) |
|---|---|---|---|
| PID | 5060 | 5060 | 2654 |
| Parent | **not shown** | `powershell.exe` (10512) | PPID 2595 = `sshd-session: isko [priv]` |
| "Memory" | Memory (private working set) 2,116 K | Working Set 3,224 K (WS Private 516 K, WS Shareable 2,708 K), Peak WS 11,636 K | RES 7,700 K, SHR 5,492 K |
| Committed / private | Commit size 2,752 K | Private Bytes 2,752 K | — (no direct column) |
| Virtual | — | Virtual Size 2,151,772,876 K | VIRT 18,688 K |
| Handles / fds | Handles 158 | Handles 158 | 15 open fds (`/proc/2654/fd`) |

Cross-check from the command line: `Get-CimInstance` gave PID 5060, parent 10512, 160 handles,
WorkingSetSize 11,915,264 B, PrivatePageCount 2,965,504 B; `/proc/2654/status` gave VmSize 18,688 kB
and VmRSS 7,700 kB, identical to htop's VIRT and RES.

### Where the tools disagree

1. **Same number, different name.** Task Manager's *Commit size* and Process Explorer's *Private Bytes*
   are both 2,752 K: it is the same quantity (private committed memory) under two names.
2. **"Memory" means different things.** Task Manager's default column is the *private* working set only;
   Process Explorer shows the full working set (3,224 K) split into private and shareable; htop shows RES
   (all resident pages, including shared libraries) and SHR separately. No two of the "memory" figures agree.
3. **The working set is not stable, commit is.** `Get-CimInstance`, run right after logging in, reported
   11,636 K, which is exactly the Peak Working Set in Process Explorer. Ten minutes later Windows had
   trimmed the idle process to 3,224 K. Private Bytes / Commit size stayed at 2,752 K in both tools.
4. **Parent.** Task Manager does not show the parent at all; Process Explorer and htop do.
5. **Handles vs file descriptors.** 158 handles against 15 fds is not a like-for-like comparison: a Windows
   handle can refer to almost any kernel object (threads, events, registry keys, sections), whereas
   `/proc/PID/fd` lists only open files, sockets and pipes.
6. **Virtual size.** Process Explorer reports ~2 TB virtual size for a 3 MB process (64-bit address space
   reservations); htop's VIRT on Linux is a modest 18 MB.

### Linux memory pressure

| Time (UTC) | Mem used | Mem free | buff/cache | Swap used | What happened |
|---|---|---|---|---|---|
| 08:12:20 | 661Mi | 3.3Gi | 1.6Gi | 0B | **Before** |
| 08:19:27 | 716Mi | 3.3Gi | 1.6Gi | 0B | python3 starts allocating |
| 08:20:12 | 3.8Gi | 142Mi | 1.6Gi | 0B | free RAM nearly gone |
| 08:20:14–08:20:26 | 4.0 → 5.1Gi | ~150–200Mi | 1.3Gi → 258Mi | 0B → 3.1Mi | kernel drops the page cache first |
| 08:20:28–08:20:36 | 5.1Gi | ~150–200Mi | ~210Mi | 91Mi → 903Mi | swapping; both terminals lag |
| 08:20:38 | 5.1Gi | 151Mi | 186Mi | **1.0Gi (free 0B)** | swap exhausted |
| 08:20:40 | — | — | — | — | **OOM killer kills python3** |
| 08:20:42 | 506Mi | 4.8Gi | 94Mi | 13Mi | memory returned |
| 08:25:13 | 526Mi | 4.8Gi | 128Mi | 13Mi | **After** |

The order of the kernel's response is visible in the figures: first free RAM is used, then the page cache
is reclaimed (1.6Gi → ~200Mi), then anonymous pages go to swap until swap is full, and only then the
OOM killer runs. The kernel record:

```
python3 invoked oom-killer: gfp_mask=0x140cca(GFP_HIGHUSER_MOVABLE|__GFP_COMP), order=0, oom_score_adj=0
oom-kill:constraint=CONSTRAINT_NONE,...,global_oom,task_memcg=/user.slice/user-1000.slice/session-1.scope,task=python3,pid=21305,uid=1000
Out of memory: Killed process 21305 (python3) total-vm:6060764kB, anon-rss:5010552kB, ...
```

`CONSTRAINT_NONE` / `global_oom` means the whole machine ran out, not a cgroup limit. The victim had
~4.8 GB resident (anon-rss) plus most of the swap. Afterwards 13 MiB stayed in swap: pages of other
processes that were pushed out and have not been needed since.

### Windows: the same class of event

The allocation loop reached 8,704 MB before `AllocHGlobal` failed with *"Insufficient memory to continue
the execution of the program."* On the way, commit usage jumped between 88 % and 95 % several times:
each drop is Windows growing the page file and raising the commit limit. At 99.4 % it stopped growing.

System log, Resource-Exhaustion-Detector:

```
TimeCreated : 11/17/2026 2:30:01 PM
Id          : 2004
Message     : Windows successfully diagnosed a low virtual memory condition. The following programs consumed
              the most virtual memory: powershell.exe (11052) consumed 9756540928 bytes, ...
```

**The difference:** Linux overcommits and, when it really runs out, picks a victim and kills it. Windows
does not overcommit: it refuses the next allocation (the program gets an error it can handle, as
PowerShell did here), grows the page file, and logs event 2004 naming the largest consumers. Nobody was killed.

## What did not work the first time

1. **`tail /dev/zero` ate no memory.** It ran from 08:13 to 08:19 and `free` did not move (used stayed at
   ~660Mi, see the first part of `memory-pressure.txt`). The clue was an earlier error from `wc`
   (`error: unexpected argument ... tip: to pass '-1' as a value`): that is the Rust re-implementation of
   coreutils, not GNU, and its `tail` evidently does not buffer `/dev/zero` the way GNU `tail` does.
   Replaced it with a small Python allocator, which worked at once (08:19:27).
2. **The parent PID changed under me.** `ps` first showed `2595 → parent 2419` (`sshd -D [listener]`).
   In htop a few minutes later 2595 had PPID **1**. `systemctl status ssh` showed the service had been
   started again (it is socket-activated, `TriggeredBy: ssh.socket`) and the listener now had PID 12685.
   The old listener exited, so systemd (PID 1) adopted the orphaned session process.
3. **No swap and no SSH server.** `swapon --show` printed nothing and `ssh` was inactive; both had to be
   set up before the lab could start. The first `fallocate -1 1G` failed: the option is the letter `l`
   (length), not the digit 1; rewritten as `--length`.
4. **winget could not install Process Explorer.** First `0x8a15005e: The server certificate did not match`
   on the msstore source, then, with `--source winget`, `Installer hash does not match`. Downloaded
   `procexp64.exe` directly from live.sysinternals.com and checked it with `Get-AuthenticodeSignature`
   before running it.

## Evidence

- [evidence/task-manager.png](evidence/task-manager.png) — `ssh.exe` PID 5060 with memory, commit size and handles in Task Manager
- [evidence/process-explorer.png](evidence/process-explorer.png) — Process Explorer Image tab: PID 5060, parent `powershell.exe (10512)`, command line
- [evidence/process-explorer-performance.png](evidence/process-explorer-performance.png) — Private Bytes, Working Set breakdown, Handles for the same PID
- [evidence/htop.png](evidence/htop.png) — htop tree for `sshd-session` 2595 → 2654 with PPID, VIRT, RES, SHR
- [evidence/process-chain.png](evidence/process-chain.png) — `ps` / `systemctl status ssh` / fd count: the listener restart and PPID 1
- [evidence/memory-pressure.txt](evidence/memory-pressure.txt) — `free -h` before, every 2 s during, and after the Linux experiment
- [evidence/kernel-log-extract.txt](evidence/kernel-log-extract.txt) — the OOM killer record from `journalctl -k`
- [evidence/windows-memory-pressure.png](evidence/windows-memory-pressure.png) — the Windows allocation loop up to the failed allocation
- [evidence/windows-event.txt](evidence/windows-event.txt) — Event 2004 from Resource-Exhaustion-Detector
