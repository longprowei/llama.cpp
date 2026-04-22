#!/usr/bin/env python3
import argparse
import csv
import difflib
from pathlib import Path

START_MARKER = "... (truncated)\n\n"
END_MARKERS = [
    "llama_memory_breakdown_print:"
]

def extract_generated_text(path):
    raw = path.read_text(encoding="utf-8", errors="replace")

    end = len(raw)
    for marker in END_MARKERS:
        idx = raw.find(marker)
        if idx != -1:
            end = min(end, idx)

    body = raw[:end]

    start = body.find(START_MARKER)
    if start == -1:
        raise ValueError(f"{path}: could not find the boundary between prompt and output.\n")

    return body[start + len(START_MARKER):].strip()

def common_prefix_len(a, b):
    n = min(len(a), len(b))
    i = 0
    while i < n and a[i] == b[i]:
        i += 1
    return i

def compare_texts(baseline, other, variant):
    prefix = common_prefix_len(baseline, other)
    exact = baseline == other
    ratio = difflib.SequenceMatcher(None, baseline, other, autojunk=False).ratio()

    return {
        "variant": variant,
        "exact_match": int(exact),
        "first_divergence_char": "None" if exact else prefix,
        "common_prefix_chars": prefix,
        "baseline_chars": len(baseline),
        "variant_chars": len(other),
        "similarity_ratio": f"{ratio:.6f}",
        "divergence_score": f"{1.0 - ratio:.6f}",
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--baseline", required=True, type=Path)
    ap.add_argument("--sliding", required=True, type=Path)
    ap.add_argument("--age", required=True, type=Path)
    ap.add_argument("--out-dir", type=Path, default=None)
    ap.add_argument("--name", required=True)
    args = ap.parse_args()

    baseline = extract_generated_text(args.baseline)
    sliding = extract_generated_text(args.sliding)
    age = extract_generated_text(args.age)

    rows = [
        compare_texts(baseline, sliding, "sliding"),
        compare_texts(baseline, age, "age"),
    ]

    for row in rows:
        print(
            f"{row['variant']:7s} | "
            f"exact={row['exact_match']} | "
            f"first_div={row['first_divergence_char']} | "
            f"prefix={row['common_prefix_chars']} | "
            f"sim={row['similarity_ratio']} | "
            f"div={row['divergence_score']}"
        )

    if args.out_dir is not None:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        prefix = args.name

        (args.out_dir / f"{prefix}_baseline_clean.txt").write_text(baseline, encoding="utf-8")
        (args.out_dir / f"{prefix}_sliding_clean.txt").write_text(sliding, encoding="utf-8")
        (args.out_dir / f"{prefix}_age_clean.txt").write_text(age, encoding="utf-8")

        csv_path = args.out_dir / f"{prefix}_summary.csv"
        with csv_path.open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            writer.writeheader()
            writer.writerows(rows)

        print(f"\nWrote cleaned output context files and summary to {args.out_dir}")

if __name__ == "__main__":
    main()
