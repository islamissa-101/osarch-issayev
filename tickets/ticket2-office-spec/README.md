# Ticket 2 — "We are kitting out the new office"

## 1. What was asked

> From: Daniyar K. (Director)
> Subject: computers for the new office
>
> We are opening the second office and need four computers — accountant,
> sales, web developer, designer. Budget 3,000,000 tenge for everything.
> Everyone says we should just buy the same four machines, is that right?
> Make sure they last a few years. Monitors included.

## 2. What was actually needed

**Where the request is wrong.** No, "the same four machines" is not right. The four people put
four different loads on a computer, so each machine runs out of a different resource first:

| Role | What runs out first |
| :--- | :--- |
| Accountant | data safety (power cuts, 1C file database), then single-thread speed |
| Sales | memory (browser tabs + video calls) |
| Web developer | memory, then CPU cores (containers, VMs, builds) |
| Designer | memory, GPU, and the colour accuracy of the monitor |

One identical machine would have to be sized for the most demanding person, the designer. Four
copies of the designer build cost **3 553 864 KZT**, which is over budget. Four copies of the
accountant build cost 1 997 452 KZT and fit, but then the sales manager swaps during calls and the
designer has no GPU.

**Where the director's instinct is half right.** Identical machines are easier to support: one
driver set, one BIOS, interchangeable spare parts. I kept that advantage. All four machines share
the **same base** (CPU, board, SSD, PSU, case) and differ only in what the role needs: memory,
GPU, monitor, OS, UPS, camera. *The base can be the same; the configuration cannot.*

**What the request left out, and what I assumed instead of an answer.**

| Missing information | What I would have asked Daniyar | What I assumed |
| :--- | :--- | :--- |
| Is VAT and delivery inside the 3 000 000? | "Is that with VAT and delivery?" | Retail shelf prices, which in Kazakhstan already include VAT. Delivery from the reserve. |
| Peripherals (keyboard, mouse, webcam, UPS) | "Do people bring their own?" | Not provided. Keyboard + mouse for everyone, webcam for sales, UPS for the accountant. |
| Software (1C, Office, Adobe) | "Are licences coming from the first office?" | **Not** in this budget. Only the OS is included, as the brief requires. |
| Desktop or laptop? Sales people often travel | "Does sales go to client meetings?" | Desktops. "Computers" plus "monitors included" points to fixed desks. |
| "Last a few years" — how many? | "3 years? 5?" | 4–5 years, with one cheap upgrade in the middle. Every board has 2 free memory slots and takes a faster CPU. |
| Who assembles and supports the machines? | "Is there IT staff at the new office?" | Assembled by me or the shop. This decides question 2. |
| Linux or Windows for the developer? | "What stack does the developer use?" | Web stack (Node, Docker) → Ubuntu 24.04 LTS, a licensed OS at 0 KZT. |
| Network equipment | "Is there a switch / Wi-Fi?" | Already exists. Not budgeted. |

**Where the brief itself needed interpreting.**
- "A vendor that actually delivers to Kazakhstan". As far as I could find, PCPartPicker does not
  list Kazakhstan prices, so I used it only for compatibility (`evidence/pcpartpicker-links.md`).
  Every price is from a Kazakhstan seller.
- "A licensed OS". Kazakhstan marketplaces sell "Windows 11 Pro keys" for 2 000–3 500 KZT. These
  are grey-market keys, not a valid licence for a company. I priced the Kazakhstan-only DSP/OEI
  licence (FQC-10548, 76 980 KZT).
- **"With the date you took the price"** means the price as it is on the seller's page that day.
  My first draft used prices from search-engine snippets. On the live pages, DDR5 was 39 % and the
  RTX 5060 65 % more expensive. This changed the platform for two of the four machines
  (`evidence/price-recheck.md`).

## 3. What I did

1. Wrote down each role's load and the bottleneck that load creates (`builds.md`), before choosing
   any part.
2. First draft: two platforms. Intel + DDR4 for accountant and sales, AMD AM5 + DDR5 for developer
   and designer, priced from search results.
3. Re-checked **every** price on the live e-katalog.kz / alfa.kz pages through a browser. I saved
   every seller's offer for every part to `evidence/vendor-quotes/offers-2026-11-15.txt`.
4. The live prices broke the first draft. AM5 + 32 GB DDR5 = 444 566 KZT against
   LGA1700 + 32 GB DDR4 = 264 065 KZT, **+180 501 per machine**. All four machines moved to one
   LGA1700/DDR4 base. The comparison is in `evidence/price-recheck.md`.
5. Picked the cheapest seller per part from the live offers. I recorded seller, URL and date in
   every row of `budget.csv`.
6. Checked compatibility by hand: DDR4 board + DDR4 memory, built-in graphics (no "F" CPU), box
   cooler, PSU vs GPU, BIOS for 14th gen (`evidence/pcpartpicker-links.md`).
7. Recalculated the totals from the CSV, not by hand:

   ```bash
   awk -F, 'NR>1{s[$1]+=$4;t+=$4} END{for(r in s) printf "%-11s %9d\n", r, s[r]; printf "TOTAL       %9d\nRESERVE     %9d\n", t, 3000000-t}' budget.csv
   ```
   ```
   designer       888466
   webdev         498666
   accountant     499363
   sales          522297
   TOTAL         2408792
   RESERVE        591208
   ```
8. Priced the pre-built alternative from the same day (`evidence/prebuilt-quotes.csv`).

**Decisions with reasons (the long version is in `builds.md`):**
- **One shared base on LGA1700 + DDR4.** At November 2026 prices, DDR5 costs about twice as much
  as DDR4 for the same 32 GB. The AM5 upgrade path is not worth +180 000 KZT per machine for
  office loads. The cost: LGA1700 is a finished socket, so the upgrade path is one step (up to
  an i7-14700 on the same board).
- **Reserve of 591 208 KZT (19.7 %), on purpose.** I measured price movement myself: +39 % on DDR5
  and +65 % on the GPU between two readings of the same pages. A plan that spends the full 3 000 000
  today is over budget by the time the invoice is paid. The reserve also covers what the director
  did not mention: software licences, delivery, assembly, a headset, a colorimeter.
- **UPS only for the accountant.** A power cut can damage a 1C file database. On the other
  machines, a power cut loses only unsaved work.
- **A graphics card only for the designer.** The i5-14400 has built-in graphics. A GPU for office
  work would cost ~289 000 KZT per machine with no benefit.

### The three questions

**1. Which machine will I upgrade first, eighteen months from now, and why?**

The **designer's**, with +32 GB memory (two more 16 GB DDR4 sticks in the two free slots, about
131 000 KZT today). It is the only role where the load grows by itself: files get bigger, and
Adobe adds AI features each year that run locally and use memory. Nothing is thrown away, because
the slots are already there. One caution: DDR4 is an old standard, and it may get harder to find
or more expensive. If the designer is already near 32 GB in the first year, buy the sticks then,
not in month 18. The accountant and the sales manager will not need anything in 18 months, since
their machines were sized with spare capacity in the one resource their role uses.

**2. The same four as pre-built machines. What does the company gain and what does it lose?**

| | Custom (this plan) | Pre-built (HP, alfa.kz, same day) |
| :--- | ---: | ---: |
| Accountant (+ monitor, UPS) | 499 363 | 903 596 |
| Sales (+ monitor, webcam) | 522 297 | 867 150 |
| Web developer (+ monitor) | 498 666 | 972 174 |
| Designer (+ monitor) | 888 466 | ≥ 996 244 * |
| **Total** | **2 408 792** | **≥ 3 739 164** |

Pre-built systems used: HP Pro Tower 400 G9 (99Q40ET, i5-14500 / 16 GB / 1 TB / Win 11 Pro) for
accountant and sales, and HP ProDesk 2 Tower G1i E (B6YX4ET, i7-14700 / 32 GB / 1 TB) for the
developer. Same monitors, UPS and webcam as the custom builds. Prices: `evidence/prebuilt-quotes.csv`.
\* Lower bound only. The cheapest HP with 32 GB has **no graphics card**, so it is not a designer
machine even at this price.

**What the company gains with pre-built:** a manufacturer warranty on the whole machine and one
company to call. Nobody has to work out which part failed. There is one invoice from one legal
entity, which the accountant will appreciate. No assembly time, and Windows is already activated.

**What it loses:** at least **739 000 KZT over budget** (25 % over), and it still has no designer
GPU. The pre-built I priced for sales has only **16 GB**, in the role that most needs 32 GB.
Office pre-builts also use small branded power supplies and boards. That makes memory, GPU and
CPU upgrades harder or impossible, the opposite of "make sure they last a few years".

**My recommendation:** build. If the company has no one to support self-built machines, buy all
the parts from one shop with assembly and a shop warranty. Most of the sellers in
`offers-2026-11-15.txt` offer that, and it costs far less than the pre-built difference.

**3. One of these four people will complain about performance within a month. Who, and about what?**

The **designer**, about **disk space, and the slowdown when the disk fills up**. 1 TB looks large.
But the OS, Adobe apps and their caches take roughly 150–200 GB (my estimate). A designer working
with large PSD files, stock assets and exported versions can fill the rest in weeks, and
Photoshop's scratch disk needs free space on top of that. The NV3 is a budget drive without DRAM
cache, and it slows down noticeably when nearly full. The complaint will be "the computer got
slow", not "the disk is full". The fix is planned: a second NVMe in the board's free M.2 slot from
the reserve, plus an archive on shared storage.

## 4. Evidence

- [builds.md](builds.md) — each build described by load → bottleneck → trade-off, with row references.
- [budget.csv](budget.csv) — every part with role, model, price in KZT, seller URL and date (15.11.2026).
- [evidence/vendor-quotes/offers-2026-11-15.txt](evidence/vendor-quotes/offers-2026-11-15.txt) — every seller's live offer for every part on 15.11.2026, with the one used marked. It also lists the alternatives I checked and rejected.
- [evidence/price-recheck.md](evidence/price-recheck.md) — search-result prices vs live prices. Proves why the platform changed.
- [evidence/prebuilt-quotes.csv](evidence/prebuilt-quotes.csv) — pre-built prices used in question 2.
- [evidence/pcpartpicker-links.md](evidence/pcpartpicker-links.md) — compatibility check, and why PCPartPicker is not the price source.
- Labs used as reasoning, not copied: Lab 0 (module count decides upgrades), Lab 2 (what memory overcommit does to a machine, measured), Lab 3 (socket and slot limits decide what can be upgraded), Lab 4 (RAID ≠ backup → the accountant needs a backup, not just a UPS).

## 5. What I would do differently

- **Read the price on the seller's page from the very start.** My first draft trusted
  search-engine snippets. They were out of date, and the two most expensive parts had gone up
  39–65 %. Half the design had to be redone. Now I know that "the date you took the price" means
  the date *you read the page*, not the date you found the link.
- **Ask for one written quote from one shop** (a commercial offer, "коммерческое предложение")
  instead of the cheapest seller per part. A real company buys from one supplier, with one
  invoice and one warranty desk, and will pay a bit more than my per-part minimum. Part of the
  reserve would go to that difference.
- **Send Daniyar the questions from section 2 before building anything.** Two of the answers (are
  software licences included, does sales travel) could change a whole build.
