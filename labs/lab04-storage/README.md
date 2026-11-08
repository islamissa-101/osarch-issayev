# Lab 4 — Storage

Student: ISSAYEV

## Windows

Disk 0: partition style **GPT**, `$env:firmware\_type` = **UEFI** — because the guest
boots through UEFI, and UEFI boots Windows from a GPT disk, so the system disk has to be GPT.

New disk (Disk 1): partition style **GPT** — 2 GB fits either table, so nothing forced
the choice here. I chose GPT because it is the standard for UEFI systems, has no 2 TB
size limit and no 4-primary-partition limit, and keeps a backup copy of the partition
table at the end of the disk. MBR vs GPT would only matter if the disk were larger than
2 TB, needed more than four partitions, or had to boot a Legacy BIOS machine.
Windows also created a 16 MB Microsoft Reserved partition (partition 1) automatically,
as it does on every GPT disk; my NTFS volume `LAB4` is partition 2, letter E:.

`Get-Disk` (after):

```
Number Friendly Name Serial Number                    HealthStatus         OperationalStatus      Total Size Partition
                                                                                                             Style
------ ------------- -------------                    ------------         -----------------      ---------- ----------
0      VMware Vir... DC0D\_2687\_E56C\_172E\_000C\_2969... Healthy              Online                      64 GB GPT
1      VMware Vir... 0489\_859A\_8810\_696B\_000C\_2968... Healthy              Online                       2 GB GPT
```

`Get-Partition -DiskNumber 1` (key fields):

```
PartitionNumber : 1
Type            : Reserved
Size            : 16759808
DriveLetter     :

PartitionNumber : 2
Type            : Basic
Size            : 2130640896
DriveLetter     : E
AccessPaths     : {E:\\, \\\\?\\Volume{ab7d9965-e593-482d-95d4-3948eb2fa6ad}\\}
```

`$env:firmware\_type`:

```
UEFI
```

## Linux layout — before

```
NAME                      SIZE TYPE FSTYPE      MOUNTPOINT
loop0                     1.5M loop squashfs    /snap/hwctl/123
loop1                    66.8M loop squashfs    /snap/core24/1643
loop2                    50.1M loop squashfs    /snap/snapd/27710
sda                        20G disk
├─sda1                      1M part
├─sda2                    1.8G part ext4        /boot
└─sda3                   18.2G part LVM2\_member
  └─ubuntu--vg-ubuntu--lv  10G lvm  ext4        /
sdb                         2G disk
sdc                         2G disk
sdd                         2G disk
sr0                       2.7G rom  iso9660
```

## Linux layout — after the rebuild

```
NAME                      SIZE TYPE  FSTYPE            MOUNTPOINT
loop0                     1.5M loop  squashfs          /snap/hwctl/123
loop1                    66.8M loop  squashfs          /snap/core24/1643
loop2                    50.1M loop  squashfs          /snap/snapd/27710
loop3                     1.5M loop  squashfs          /snap/hwctl/131
sda                        20G disk
├─sda1                      1M part
├─sda2                    1.8G part  ext4              /boot
└─sda3                   18.2G part  LVM2\_member
  └─ubuntu--vg-ubuntu--lv  10G lvm   ext4              /
sdb                         2G disk
└─sdb1                      2G part  linux\_raid\_member
  └─md0                     2G raid1 ext4              /mnt/mirror
sdc                         2G disk
└─sdc1                      2G part  linux\_raid\_member
sdd                         2G disk
└─sdd1                      2G part  linux\_raid\_member
  └─md0                     2G raid1 ext4              /mnt/mirror
sr0                       2.7G rom   iso9660
```

md0 now sits under sdb1 and sdd1; sdc1 is left as a RAID partition that belongs to no array.

|Role|Device|
|-|-|
|Mirror half A|sdb1|
|Failed half|sdc1|
|Replacement|sdd1|

## Timeline (from the evidence files, UTC)

|State|File|Time|Status|
|-|-|-|-|
|Healthy|array-healthy.txt|16:39:28|\[2/2] \[UU]|
|Degraded|array-degraded.txt|16:47:49|\[2/1] \[U\_]|
|Rebuilt|array-rebuilt.txt|17:00:06|\[2/2] \[UU]|

Checksums before the failure and after the failure (read back from the single surviving
disk after `umount` + `mount`) are identical — `diff` printed nothing and `MATCH`.

## The question

Your colleague deleted the wrong file from the mirror an hour ago.
Does RAID 1 help? Why?

<No, RAID 1 does not help here. A mirror copies every write to both disks at the same moment, so the deletion was carried out on sdb1 and sdd1 at once, just as faithfully as it kept random.bin alive when sdc1 failed in my test. Only a backup or snapshot taken before the deletion, stored separately from the array, would let us restore the file.>

