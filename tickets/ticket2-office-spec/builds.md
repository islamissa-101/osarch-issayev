# Ticket 2 — four builds, four different loads

All prices are in tenge (KZT), read live from Kazakhstan sellers' offers on **15.11.2026**
(`evidence/vendor-quotes/offers-2026-11-15.txt`). The row numbers point at `budget.csv` (line 1
is the header). Every build meets the hard requirements: at least 16 GB of memory, a 1 TB SSD, a
licensed OS and a monitor.

| Role | Total, KZT | budget.csv rows | What makes it different |
| :--- | ---: | :--- | :--- |
| Accountant | 499 363 | 2–11 | 16 GB + **UPS** |
| Sales manager | 522 297 | 12–21 | **32 GB** + webcam |
| Web developer | 498 666 | 22–30 | 32 GB + 27″ QHD monitor + **Ubuntu** |
| Designer | 888 466 | 31–40 | 32 GB + **RTX 5060** + 99 % sRGB monitor |
| **All four** | **2 408 792** | | |
| Reserve (not spent) | 591 208 | | 19.7 % of 3 000 000 |

## One platform, four configurations

My first draft put the developer and the designer on AMD AM5 with DDR5, for the longer CPU
upgrade path. Then I re-checked every price on the live seller pages instead of trusting search
results. 32 GB of DDR5 had gone up 39 % and the RTX 5060 65 % (`evidence/price-recheck.md`).
At live prices, AM5 + 32 GB DDR5 costs **~180 000 KZT more per machine** than LGA1700 + 32 GB DDR4.
For that money the company gets a CPU upgrade path it may never use.

So all four machines use **the same base**: Intel Core i5-14400 (BOX, with cooler and built-in
graphics), Gigabyte B760 DS3H DDR4 (4 memory slots), Kingston NV3 1 TB, MSI 650 W, the same case.
What differs between the roles is exactly what their loads need: memory, GPU, monitor, OS, UPS,
camera.

This is the honest part of "buy the same four machines". **The base can be the same. The
configuration cannot.** A shared base gives one set of drivers, one BIOS to update, and
interchangeable spare parts. If the accountant's PSU dies, the developer's can keep her working
for a day.

What I gave up: LGA1700 is a finished socket, and no new CPU generation will fit it. The upgrade
path is one step: the same board takes up to a Core i7-14700 (164 309 KZT today). For office loads
over 4–5 years, memory is the part that runs out first, not the CPU. Every board has 2 empty
memory slots.

---

### Build 1 — accountant

**Load:** 1C:Accounting (file database on the local disk), Excel, a browser with the bank
client, the e-invoice portal (ESF) and NCALayer for the digital signature (ЭЦП). It is
single-user and mostly single-threaded. It is busy at month-end and quarter-end closing.

**Bottleneck:** not CPU and not GPU. It is **data safety, then single-thread speed**. A 1C file
database is a file that is written all the time. A power cut in the middle of a write can damage
it, and then the books have to be rebuilt. Disk latency matters more than disk bandwidth.

**Choices:**
- 16 GB as **2×8 GB DDR4** — row 4. This is enough for 1C plus a browser. Two slots stay empty
  for +16 GB later, without throwing the current sticks away (Lab 0: "16 GB" without the module
  count says nothing about upgrades).
- NVMe SSD — row 5. Its random access is far better than SATA or HDD, and 1C cares about random
  access.
- **APC Back-UPS 750 VA** — row 11. This is the only UPS in the budget, on purpose.
- Windows 11 Pro, not Home, so BitLocker can encrypt the disk with the company's financial data —
  row 9.

**Trade-off:** this is the cheapest configuration of the shared base. The ~50 000 KZT a faster
CPU or more memory would cost went to the UPS instead. More speed would make 1C reports a few
seconds quicker. A UPS prevents a damaged database. Lab 4 taught that RAID is not a backup, and a
UPS is not one either. The accountant still needs a scheduled copy of the 1C database off the
machine. That is free to set up, so it is in the README, not in the budget.

**Total:** 499 363 KZT (budget.csv, rows 2–11)

---

### Build 2 — sales manager

**Load:** CRM in a browser with 30–40 tabs, WhatsApp Web / Telegram, Excel, and several hours of
video calls a day (Zoom / Google Meet), often all at once.

**Bottleneck:** **memory, not CPU.** A browser with dozens of tabs plus a video call fills 16 GB
quickly. When memory runs out, the OS starts compressing and swapping. In Lab 2 I promised the
guests more memory than the host had. The host's available memory dropped below 1 GB and the UI
became noticeably slow. On this machine, that happens in the middle of a call with a customer.

**Choices:**
- **32 GB as 2×16 GB DDR4** — row 14. This is the one decision that matters in this build.
- A webcam — row 21. A desktop PC has no camera. The request says nothing about one, but the job
  is video calls.
- The same i5-14400 as everyone else. Its hardware video engine handles the call, and the CPU
  mostly idles in this role.

**Trade-off:** the 59 380 KZT difference between 16 GB and 32 GB went to memory, not to the CPU or
the monitor. I did not buy a headset. Many people already own one, and it is the first thing to
buy from the reserve if not.

**Total:** 522 297 KZT (budget.csv, rows 12–21)

---

### Build 3 — web developer

**Load:** VS Code, Node / npm builds, several Docker containers (database, backend, cache), two
or three browsers for testing, and sometimes a virtual machine, exactly like the guests in
Labs 1–2.

**Bottleneck:** **memory first, CPU cores second.** Every container and every VM takes a fixed
part of memory. Lab 2 showed what happens when the total is promised past physical RAM. Builds
and test runs use all cores. The i5-14400 has 10 cores / 16 threads, which is enough for a
single developer's builds.

**Choices:**
- 32 GB DDR4 — row 24. It is the same memory as sales, for a different reason.
- 27″ 2560×1440 monitor — row 28. More lines of code on screen is real productivity for this role.
- **Ubuntu 24.04 LTS** — row 29, 0 KZT. It is a licensed OS (free licences), and it is the same
  OS the code will run on in production. Docker runs natively on Linux, with no WSL2 VM in between.

**Trade-off:** choosing Linux saved the 76 980 KZT a Windows licence costs. That paid for the
monitor upgrade from 24″ FHD to 27″ QHD (+66 439 KZT), and the build still costs about the same as
the accountant's. The risk: if the company uses Windows-only tools (1C client, some bank
software), the developer will need a Windows VM. That is one more reason for 32 GB. If builds
become slow later, the CPU can go up to an i7-14700 on the same board.

**Total:** 498 666 KZT (budget.csv, rows 22–30)

---

### Build 4 — designer

**Load:** Photoshop with large multi-layer files, Illustrator, Figma in a browser, sometimes
light video or motion work. Files are hundreds of MB each, with the cache and scratch disk on top.

**Bottleneck:** three at once: **memory** (Photoshop uses all it can get), **GPU** (Photoshop and
Illustrator use it for the canvas, filters and AI features), and **the monitor**. If colours are
wrong on screen, every other component is wasted.

**Choices:**
- 32 GB DDR4 — row 33. Two slots stay free for 64 GB (see the README, question 1).
- GeForce RTX 5060 8 GB — row 34. This is the cheapest current NVIDIA card with full Adobe GPU
  acceleration and hardware video encoding. It is also the most expensive single line in the
  whole budget (288 750 KZT).
- ASUS BE27AQ, 27″ IPS 2560×1440, 99 % sRGB, with a stand that rotates to portrait — row 38.
- Windows 11 Pro — row 39. Adobe Creative Cloud does not run on Linux.

**Trade-off:** this is the most expensive seat (≈30 % of the budget), and the only one where
saving money directly lowers the quality of the work. What I gave up:
- **A factory-calibrated ProArt monitor.** I did not find one at a Kazakhstan seller on the day, so
  I took a 99 % sRGB business monitor. A colorimeter from the reserve would close most of that gap.
- **AM5 / a faster CPU.** At today's DDR5 prices that would cost +180 000 KZT. Photoshop gains more
  from the GPU and memory than from 2 extra CPU cores.
- I kept **1 TB**, the minimum. The designer is the person who will fill it first (see the
  README, question 3).

A cheaper option if the director wants to save: RTX 5050 (~221 000 KZT, 1 offer seen), −68 000 KZT.

**Total:** 888 466 KZT (budget.csv, rows 31–40)

---

### What is *not* in these totals (and is in the reserve)

| Item | Why not bought now |
| :--- | :--- |
| Software: 1C, MS Office / M365, Adobe CC | Subscriptions or separate licences. They may already exist at the first office. Must be confirmed with the director. |
| Assembly and testing of 4 PCs | Free if done in-house. Otherwise a service fee at the shop. |
| Network: switch, cables, Wi-Fi | Unknown whether the new office already has it. |
| Headset for sales, colorimeter and a 2nd NVMe for the designer | First items to buy from the reserve. |
| Price movement | Between the search-result snapshot and the live pages, DDR5 went up 39 % and the GPU 65 %. A reserve under 10 % would not survive until the invoice is paid. |
