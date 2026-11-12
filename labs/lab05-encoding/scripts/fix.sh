#!/usr/bin/env bash
# Lab 5 — convert staff-broken.csv to UTF-8
# Run from ~/labs/lab05-encoding:   bash scripts/fix.sh
set -euo pipefail
SRC_ENC="RK1048"          # <-- the encoding YOU named in section 6
IN=evidence/staff-broken.csv
OUT=evidence/staff-fixed.csv

# 1. decode from SRC_ENC, encode as UTF-8
# 2. line endings: CRLF -> LF                 (section 7)
# 3. BOM: add one, because Excel needs it      (section 8)
{
  printf '\xEF\xBB\xBF'
  iconv -f "$SRC_ENC" -t UTF-8 "$IN" | sed 's/\r$//'
} > "$OUT"

file -e csv "$OUT"
xxd -l 16 "$OUT"
