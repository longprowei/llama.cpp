#!/usr/bin/env python3

import csv
import math
import re
import statistics
import sys
from pathlib import Path


def percentile_95(values):
    """Return the linearly interpolated 95th percentile."""
    ordered = sorted(values)
    position = 0.95 * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    fraction = position - lower
    return ordered[lower] + fraction * (ordered[upper] - ordered[lower])


def read_prompt_tokens(log_path):
    text = log_path.read_text(errors="replace")
    match = re.search(r"task\.n_tokens = (\d+)", text)
    if not match:
        raise SystemExit(f"Could not find the prompt token count in {log_path}")
    return int(match.group(1))


def read_metrics(csv_path, first_affected_index, expected_tokens):
    drifts = []
    row_count = 0

    with csv_path.open(newline="") as file:
        reader = csv.DictReader(file)
        if not reader.fieldnames or not {"token_index", "nll_drift"}.issubset(reader.fieldnames):
            raise SystemExit(f"Missing token_index or nll_drift in {csv_path}")

        for expected_index, row in enumerate(reader):
            row_count += 1
            token_index = int(row["token_index"])
            if token_index != expected_index:
                raise SystemExit(f"Unexpected token index in {csv_path}: {token_index}")

            drift = float(row["nll_drift"])
            if not math.isfinite(drift):
                raise SystemExit(f"Non-finite NLL drift in {csv_path} at token {token_index}")

            if token_index >= first_affected_index:
                # Keep every post-eviction value, including zero drift.
                drifts.append(drift)

    if row_count != expected_tokens:
        raise SystemExit(f"Expected {expected_tokens} rows in {csv_path}, but found {row_count}")

    if not drifts:
        raise SystemExit(f"No post-eviction tokens found in {csv_path}")

    absolute = [abs(value) for value in drifts]
    return {
        "tokens": len(drifts),
        "mean": statistics.fmean(drifts),
        "mean_abs": statistics.fmean(absolute),
        "median_abs": statistics.median(absolute),
        "p95_abs": percentile_95(absolute),
        "max_abs": max(absolute),
    }


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: python3 experiments/analyze_nll.py CONTEXT OUTPUT")

    context = int(sys.argv[1])
    output = int(sys.argv[2])
    result_root = Path(__file__).resolve().parent / "results" / "nll"
    case_dirs = sorted(result_root.glob(f"natural_*_c{context}_o{output}"))

    if not case_dirs:
        raise SystemExit(f"No results found for context {context} and output {output}")

    # Compare only policy CSV files that exist for every prompt.
    policies = None
    for case_dir in case_dirs:
        available = {path.stem for path in case_dir.glob("*.csv")}
        available.discard("unbounded")
        policies = available if policies is None else policies & available

    if not policies:
        raise SystemExit("No common policy CSV files were found")

    order = ["sliding", "age", "h2o", "h2o_r025", "h2o_r075", "h2o_r090"]
    policies = sorted(policies, key=lambda name: (order.index(name) if name in order else len(order), name))
    summaries = {policy: [] for policy in policies}

    print(f"Post-eviction NLL drift: context={context}, output={output}")
    print("Lower mean_abs, median_abs, p95_abs and max_abs values are better.\n")
    print("Values use 8 decimal places. P95 uses linear interpolation.\n")

    for case_dir in case_dirs:
        family = case_dir.name.removeprefix("natural_").split("_c", 1)[0]
        prompt_tokens = read_prompt_tokens(case_dir / "unbounded.err")
        first_affected_index = context - prompt_tokens

        if first_affected_index < 0:
            raise SystemExit(f"Prompt is larger than the context in {case_dir}")

        print(f"{family}: prompt_tokens={prompt_tokens}, first_affected_index={first_affected_index}")
        print(
            f"{'policy':<12}"
            f"{'tokens':>10}"
            f"{'signed_mean':>14}"
            f"{'mean_abs':>14}"
            f"{'median_abs':>14}"
            f"{'p95_abs':>14}"
            f"{'max_abs':>14}"
        )

        for policy in policies:
            metrics = read_metrics(case_dir / f"{policy}.csv", first_affected_index, output)
            summaries[policy].append(metrics)
            display_name = "h2o_r050" if policy == "h2o" else policy
            print(
                f"{display_name:<12}"
                f"{metrics['tokens']:>10d}"
                f"{metrics['mean']:>14.8f}"
                f"{metrics['mean_abs']:>14.8f}"
                f"{metrics['median_abs']:>14.8f}"
                f"{metrics['p95_abs']:>14.8f}"
                f"{metrics['max_abs']:>14.8f}"
            )
        print()

    print(f"Macro mean across {len(case_dirs)} prompts with equal prompt weight")
    print(
        f"{'policy':<12}"
        f"{'signed_mean':>14}"
        f"{'mean_abs':>14}"
        f"{'median_abs':>14}"
        f"{'p95_abs':>14}"
        f"{'mean_max_abs':>14}"
    )

    for policy in policies:
        results = summaries[policy]
        display_name = "h2o_r050" if policy == "h2o" else policy
        macro = {
            key: statistics.fmean(result[key] for result in results)
            for key in ("mean", "mean_abs", "median_abs", "p95_abs", "max_abs")
        }
        print(
            f"{display_name:<12}"
            f"{macro['mean']:>14.8f}"
            f"{macro['mean_abs']:>14.8f}"
            f"{macro['median_abs']:>14.8f}"
            f"{macro['p95_abs']:>14.8f}"
            f"{macro['max_abs']:>14.8f}"
        )


if __name__ == "__main__":
    main()
