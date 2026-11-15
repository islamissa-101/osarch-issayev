# PCPartPicker — compatibility check only, not prices

PCPartPicker shows prices for a fixed list of countries. As far as I could find, Kazakhstan is
not one of them (check the country selector at the top of pcpartpicker.com). That means
PCPartPicker **cannot be the price source** for this ticket. The brief requires prices from a
seller that delivers to Kazakhstan, so all prices in `budget.csv` come from Kazakhstan sellers
(see `vendor-quotes/offers-2026-11-15.txt`).

I used PCPartPicker for one job only: **checking that the parts fit together** (socket, memory
type, case size, power). All four machines share one platform, so there are three distinct lists:

| Build | Parts entered | PCPartPicker list | Compatibility result |
| :--- | :--- | :--- | :--- |
| Accountant | i5-14400, Gigabyte B760 DS3H DDR4, 2×8 GB DDR4-3200, Kingston NV3 1 TB, MSI MAG A650BN | _paste link_ | _paste result_ |
| Sales / Web developer | as above, but 2×16 GB DDR4-3200 | _paste link_ | _paste result_ |
| Designer | as sales + RTX 5060 8 GB | _paste link_ | _paste result_ |

Things I checked by hand, because a parts list can still miss them:

- I chose the i5-14400 (**not** 14400F) because it has built-in graphics. Without a graphics
  card, an "F" CPU gives no picture at all, and three of the four machines have no graphics card.
- The BOX version comes with Intel's cooler, so no separate cooler line is needed. That cooler is
  enough for a 65 W CPU in an office.
- The Gigabyte B760 DS3H DDR4 takes **DDR4 only**. DDR5 sticks do not fit its slots.
- The B760 chipset needs a BIOS that knows 14th-gen CPUs. Boards sold in 2026 ship with it, but
  check the BIOS version on first boot and update it. The Intel microcode fixes for 13th/14th-gen
  stability are also delivered through BIOS updates.
- The RTX 5060 draws about 150 W, and the 650 W PSU covers it with plenty of margin.
