# Lab 5 — Encoding forensics

Original checksum (section 4):
`919027f1f8c71d85cba3f12aad0f6c927d4e0450cfb2a2d63378a69f14cab270  staff-broken.csv`
— the same at the end (section 10): the original was never changed.

## Diagnosis (before the fix)

file says (evidence/file-before.txt):
```
staff-broken.csv: Non-ISO extended-ASCII text, with CRLF line terminators
staff-broken.csv: Non-ISO extended-ASCII text, with CRLF line terminators
```

First 16 bytes (evidence/hexdump-before.txt):
```
00000000: d2e0 e12e b93b d4c8 ce3b c4ee ebe6 edee  .....;...;......
```

| Offset | Bytes | What they are |
|---|---|---|
| 00–02 | `D2 E0 E1` | No BOM — the file starts directly with data: **Т а б**, one byte per Cyrillic letter |
| 03 | `2E` | `.` (ASCII) |
| 04 | `B9` | **№** — one byte |
| 05 | `3B` | `;` — semicolon, the column separator |
| 06–08 | `D4 C8 CE` | **Ф И О**, one byte each |
| 09 | `3B` | `;` separator |
| 0A–0F | `C4 EE EB E6 ED EE` | **Д о л ж н о** (start of "Должность") |

The header line is `Таб.№;ФИО;Должность;Отдел;E-mail;Дата приёма`. Its line ending `0D 0A` is at offset 2C–2D, outside the first 16 bytes.

**Encoding: RK1048** (Kazakh Windows code page, also called KZ-1048). Evidence:
- The very first byte, `D2`, is a Cyrillic letter in **one byte** (80–FF), not a `D0`/`D1` pair. So this is a single-byte code page, not UTF-8.
- `iconv -f UTF-8 -t UTF-8` fails: `illegal input sequence at position 0` → UTF-8 ruled out. There is no BOM, so not UTF-16 either.
- `file` only says "Non-ISO extended-ASCII", meaning "some 8-bit code page". That does not say which one.
- **CP866** and **KOI8-R** turn even the Russian header into nonsense (`╥рс.╣;╘╚╬`, `рЮА.╧;тхн`) → ruled out.
- **CP1251, RK1048 and PT154** all read Russian correctly (`Иванов Сергей Петрович`). The Kazakh letters decide between them:

| Byte | RK1048 | PT154 | CP1251 | Seen in |
|---|---|---|---|---|
| `8D` / `9D` | **Қ / қ** | Қ / қ | Ќ / ќ | Қасымова, Серікқызы |
| `A3` | **Ә** | Ј | Ј | Әлия |
| `A2` | **ұ** | ў | ў | Нұрланов |
| `AA` | **Ғ** | Ә | Є | Ғалымжан |

  RK1048 gives `1001;Қасымова Әлия Серікқызы`. CP1251 gives `Ќасымова Јлия Серікќызы`, and PT154 gives `Қасымова Јлия`. PT154 also turns Ө into Ҙ (`Ҙтебаев`) and Ү into Ҝ (`Ҝсенова`). RK1048 and PT154 differ on 16 of the 26 lines, so only one of them can be right, and only RK1048 shows every name correctly.
- `iconv -f RK1048 -t UTF-8 staff-broken.csv` decodes the whole file with no error. I read all 25 names in `less`.

**Line ending: CRLF (Windows)**. Evidence: `file` says "with CRLF line terminators"; `cat -A` shows `^M$` at the end of every line; `tr -cd '\r' | wc -c` = 26 CR bytes, `wc -l` = 26 LF bytes, so CR = LF = 26 lines (header + 25 staff). The file ends with `0D 0A`.

**BOM: absent**. Evidence: the file starts `D2 E0 E1` (Таб), not `EF BB BF` or `FF FE`.

Separator: semicolon (`3B`). The header has 5 semicolons and 0 commas.

## What each application was doing wrong

The bytes were never damaged. Digits, dates and e-mail addresses were always perfect. With no BOM to say what the file is, each program decoded it with its own guess.

- **Excel** (double-click): with no BOM, Excel does not detect anything. It decodes with the Windows ANSI code page of the system, which on my Russian-locale Windows is **CP1251**. The columns are split, because the Windows list separator here is `;`. Russian names are correct, but every Kazakh letter is wrong: `Ќасымова`, `Нўрланов`, `Ґтебаев`, `Јбенова`, `Ћашимов`. (The `########` in the date column only means the column is too narrow: Excel recognised the dates.)
- **LibreOffice Calc**: Character set was "Automatic", and it detected **Cyrillic (Windows-1251)** with locale Russian. It found the `;` separator and split the columns correctly. CP1251 has no Kazakh letters, so every Russian name was right but every Kazakh letter came out as a different CP1251 character from the same byte: `Ќасымова Јлия Серікќызы`, `Нўрланов Єалымжан`, `Ґтебаев` (Ө), `Їсенова` (Ү), `Ћашимов` (Һ). This is a *plausible* but wrong guess. CP1251 and RK1048 share all Russian letters, so nothing in a Russian name can tell them apart.
- **Why Excel and Calc looked the same on my machine:** they reached CP1251 by different routes. Excel takes the system ANSI code page without looking at the bytes. Calc analyses the bytes and, with a Russian locale, guesses CP1251 as the most likely Cyrillic code page. On an English Windows, Excel would use CP1252 and show Latin garbage (`Òàá.¹`), while Calc would still guess Cyrillic. That is why the brief says the file looks different in each program. Neither program can pick RK1048 by itself, because nothing in the file says it is RK1048.
- **cat**: cat decodes nothing. It writes the raw bytes to a UTF-8 terminal. A single byte between 80 and FF is not a valid UTF-8 sequence, so the terminal shows the replacement character `�` for every Cyrillic letter: `���.�;���;...;E-mail;���� �����`. Digits, `;`, dates and e-mail addresses stay perfect, which proves that the bytes themselves are intact.

## Fix

Command / script: `scripts/fix.sh` (`iconv -f RK1048 -t UTF-8`, `sed 's/\r$//'`, BOM written with `printf`).

Changed: encoding RK1048 → UTF-8; line ending CRLF changed to LF; BOM added. Separator (`;`) and data unchanged.

| Reader | Without BOM | With BOM |
|---|---|---|
| Excel, double-click | Wrong: falls back to the ANSI code page | Correct: the BOM tells it UTF-8 |
| LibreOffice Calc | Detects UTF-8 | Detects UTF-8 |
| cat in a UTF-8 terminal | Correct | Correct (BOM is invisible) |
| Script reading the first header | Correct: `Таб.№` | Header becomes `﻿Таб.№` unless read as utf-8-sig |

Decision: I added a UTF-8 BOM, because Excel is the reader that decided it. Without a BOM, a double-click opens the file in the ANSI code page, and the Kazakh letters break again. The cost is that a script must read the file as UTF-8 with BOM (e.g. Python `encoding="utf-8-sig"`). I changed CRLF to LF so that scripts do not get a hidden `\r` at the end of the last column (the date). Excel and Calc read LF correctly.

Byte by byte at the start:
- before: `D2 E0 E1 2E B9 3B ...` (Т а б . № ;)
- after: `EF BB BF D0 A2 D0 B0 D0 B1 2E E2 84 96 3B ...` (BOM, then Т а б as 2 bytes each, `.`, № as 3 bytes, `;`)

Every Cyrillic letter went from 1 byte to 2 bytes. № went from 1 byte to 3. Each `0D 0A` became `0A`, and ASCII is unchanged.

## Verification

file after (evidence/file-after.txt):
```
staff-fixed.csv: Unicode text, UTF-8 (with BOM) text
staff-fixed.csv: Unicode text, UTF-8 (with BOM) text
```
No "with CRLF line terminators" any more, so the line ending is LF.

awk check: `awk -F';' '{ print $NF "|" }' staff-fixed.csv | head -3`
```
Дата приёма|
12.03.2019|
01.09.2017|
```
The `|` sits right after the date: no hidden CR is left.

Original untouched: `sha256sum staff-broken.csv` = `919027f1f8c71d85cba3f12aad0f6c927d4e0450cfb2a2d63378a69f14cab270`, the same as before the fix.

Opened in (evidence/opens-correctly.png):
- **Excel** for Microsoft 365, version 2108 (build 14332.20400): opened by double-click; Kazakh letters correct (Қасымова Әлия, Нұрланов Ғалымжан, Өтебаев) and columns split on `;`.
- **LibreOffice Calc** 26.8.3.1 (x86_64): Text Import dialog proposed Unicode (UTF-8) by itself; I accepted it unchanged; all names correct.
- **cat** on Ubuntu 26.04.1 LTS: every name reads correctly.

The diagnosis commands are collected in `scripts/diagnose.sh`; its full output is in `diag.txt`.
