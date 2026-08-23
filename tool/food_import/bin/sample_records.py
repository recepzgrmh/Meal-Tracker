#!/usr/bin/env python3
"""Draw a reproducible random sample of records from a USDA FoodData Central zip.

The archives are single JSON documents shaped {"<Tier>Foods": [ {...}, ... ]},
and the branded tier is 3.3 GB uncompressed, so records are streamed one at a
time with raw_decode instead of loading the document into memory.

Usage: python3 tool/food_import/bin/sample_records.py <zip> <out.json> [n] [seed]
"""

import io
import json
import random
import sys
import zipfile

CHUNK = 1 << 20
DECODER = json.JSONDecoder()


def stream_records(fp):
    """Yield each object of the document's single top-level array."""
    buf = ""
    # Advance to the '[' that opens the array value of the first key.
    while "[" not in buf:
        chunk = fp.read(CHUNK)
        if not chunk:
            return
        buf += chunk
    buf = buf[buf.index("[") + 1 :]

    while True:
        stripped = buf.lstrip(" \t\r\n,")
        buf = stripped
        if buf[:1] == "]" or (not buf and not (chunk := fp.read(CHUNK))):
            return
        try:
            obj, end = DECODER.raw_decode(buf)
        except ValueError:
            chunk = fp.read(CHUNK)
            if not chunk:
                return
            buf += chunk
            continue
        buf = buf[end:]
        yield obj


def main():
    zip_path, out_path = sys.argv[1], sys.argv[2]
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 10
    seed = int(sys.argv[4]) if len(sys.argv) > 4 else 42

    rng = random.Random(seed)
    reservoir, total, skipped = [], 0, 0

    with zipfile.ZipFile(zip_path) as z:
        member = z.namelist()[0]
        with z.open(member) as raw:
            fp = io.TextIOWrapper(raw, encoding="utf-8")
            for rec in stream_records(fp):
                # The published archives contain literal nulls in the record
                # array (32 of Foundation's 395, for example). Count them so the
                # gap is visible, but keep them out of the sample.
                if not isinstance(rec, dict):
                    skipped += 1
                    continue
                total += 1
                if len(reservoir) < n:
                    reservoir.append(rec)
                else:
                    j = rng.randrange(total)
                    if j < n:
                        reservoir[j] = rec

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(reservoir, f, ensure_ascii=False, indent=2)

    print(
        f"{zip_path}\n  member: {member}\n  usable records: {total}"
        f"\n  null/non-object entries skipped: {skipped}"
        f"\n  sampled: {len(reservoir)} -> {out_path}"
    )


if __name__ == "__main__":
    main()
