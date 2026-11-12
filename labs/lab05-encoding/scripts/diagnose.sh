#!/usr/bin/env bash
# Lab 5 — diagnosis of staff-broken.csv (run BEFORE any fix)
# Run from ~/labs/lab05-encoding:   bash scripts/diagnose.sh
# Writes evidence/file-before.txt and evidence/hexdump-before.txt,
# prints everything else to the screen (copy it into the README).
set -uo pipefail
cd "$(dirname "$0")/../evidence"
F=staff-broken.csv
[ -f "$F" ] || { echo "No $F in evidence/"; exit 1; }

echo "##### 0. Checksum (write it down)"
sha256sum "$F"

echo; echo "##### 1. file / file -e csv"
file "$F"        | tee file-before.txt
file -e csv "$F" | tee -a file-before.txt

echo; echo "##### 2. First 16 bytes"
xxd -l 16 "$F" | tee hexdump-before.txt
echo "--- first 20 lines of the dump (names), not evidence:"
xxd "$F" | head -20

echo; echo "##### 3. BOM?"
case "$(head -c 3 "$F" | xxd -p)" in
  efbbbf) echo "UTF-8 BOM present (EF BB BF)";;
  fffe*)  echo "UTF-16LE BOM present (FF FE)";;
  feff*)  echo "UTF-16BE BOM present (FE FF)";;
  *)      echo "No BOM — first bytes are already data";;
esac

echo; echo "##### 4. Valid UTF-8?"
if iconv -f UTF-8 -t UTF-8 "$F" > /dev/null 2>/tmp/utf8err; then
  echo "valid UTF-8  -> check for double encoding (РђР№... in cat output)"
else
  echo "NOT UTF-8: $(cat /tmp/utf8err)"
fi

echo; echo "##### 5. Candidate code pages (first 5 lines each)"
for enc in CP1251 CP866 KOI8-R RK1048 PT154; do
  echo "=== $enc"
  if iconv -f "$enc" -t UTF-8 "$F" > /dev/null 2>&1; then
    iconv -f "$enc" -t UTF-8 "$F" | head -5
  else
    echo "(fails to decode the whole file)"
  fi
done

echo; echo "##### 6. Kazakh letters per candidate (Ә Ғ Қ Ң Ө Ұ Ү Һ І, both cases)"
for enc in CP1251 RK1048 PT154; do
  n=$(iconv -f "$enc" -t UTF-8 "$F" 2>/dev/null | LC_ALL=C.UTF-8 grep -o '[ӘәҒғҚқҢңӨөҰұҮүҺһІі]' | wc -l)
  echo "$enc: $n Kazakh letters"
done
echo "--- lines that differ between RK1048 and PT154:"
diff <(iconv -f RK1048 -t UTF-8 "$F" 2>/dev/null) <(iconv -f PT154 -t UTF-8 "$F" 2>/dev/null) \
  && echo "(none: RK1048 and PT154 agree on this whole file — name both)"

echo; echo "##### 7. Line ending"
cat -A "$F" | head -3
CR=$(tr -cd '\r' < "$F" | wc -c)
LF=$(wc -l < "$F")
echo "CR bytes: $CR   LF bytes: $LF"
if   [ "$CR" -eq 0 ];     then echo "-> LF (Unix)"
elif [ "$CR" -eq "$LF" ]; then echo "-> CRLF (Windows)"
elif [ "$LF" -eq 0 ];     then echo "-> CR (classic Mac)"
else                           echo "-> MIXED"
fi
echo "Last byte: $(tail -c 1 "$F" | xxd -p)  (0a = file ends with a newline)"

echo; echo "##### 8. Separator in the header line"
head -1 "$F" | tr -d '\r' | awk '{print "commas:" gsub(/,/,"") "  semicolons:" gsub(/;/,"") "  tabs:" gsub(/\t/,"")}'
