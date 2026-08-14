#!/usr/bin/env python3

import re
from pathlib import Path


result_dir = Path(__file__).resolve().parent / "results" / "performance"
cases = [(1024, 256), (2048, 512), (4096, 1024)]
policies = ["unbounded", "sliding", "age", "h2o_r050"]


def get_number(pattern, text, path):
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        raise ValueError(f"Missing value in {path}")
    return float(match.group(1))


def read_result(budget, output, policy):
    folder = result_dir / f"natural_manila_c{budget}_o{output}"
    out_path = folder / f"{policy}.out"
    err_path = folder / f"{policy}.err"
    time_path = folder / f"{policy}.time"

    out_text = out_path.read_text()
    err_text = err_path.read_text()
    time_text = time_path.read_text()

    timing = re.search(
        r"\[ Prompt: ([0-9.]+) t/s \| Generation: ([0-9.]+) t/s \]",
        out_text,
    )
    if not timing:
        raise ValueError(f"Missing throughput in {out_path}")

    memory_line = next(line for line in err_text.splitlines() if "MTL0 (" in line)
    context_mib = get_number(
        r"\(\s*\d+\s*=\s*\d+\s*\+\s*(\d+)\s*\+\s*\d+\s*\)",
        memory_line,
        err_path,
    )

    prompt_tps = float(timing.group(1))
    generation_tps = float(timing.group(2))
    context = 8192 if policy == "unbounded" else budget

    if context_mib != context / 8:
        raise ValueError(f"Unexpected context memory in {err_path}")

    return {
        "context": context,
        "prompt_tps": prompt_tps,
        "generation_tps": generation_tps,
        "generation_ms": 1000.0 / generation_tps,
        "total_time_seconds": get_number(r"^\s*([0-9.]+) real", time_text, time_path),
        "context_mib": context_mib,
        "rss_mib": get_number(
            r"^\s*(\d+)\s+maximum resident set size", time_text, time_path
        ) / (1024 * 1024),
    }


def percent(new, old):
    return (new - old) / old * 100.0


results = {}
for budget, output in cases:
    for policy in policies:
        results[budget, policy] = read_result(budget, output, policy)


print("Performance results")
print(
    f"{'context':>7} {'output':>6} {'policy':>11} {'prompt_tok/s':>12} "
    f"{'gen_tok/s':>9} {'gen_ms/tok':>10} {'total_time_s':>12} "
    f"{'context_mib':>11} {'rss_mib':>8}"
)

for budget, output in cases:
    for policy in policies:
        value = results[budget, policy]
        print(
            f"{value['context']:7d} {output:6d} {policy:>11} "
            f"{value['prompt_tps']:12.1f} {value['generation_tps']:9.1f} "
            f"{value['generation_ms']:10.2f} {value['total_time_seconds']:12.2f} "
            f"{value['context_mib']:11.1f} {value['rss_mib']:8.1f}"
        )


print("\nH2O overhead compared with simple policies")
print(
    f"{'context':>7} {'baseline':>8} {'prompt_throughput_loss':>22} "
    f"{'gen_throughput_loss':>19} {'gen_latency_overhead':>20} "
    f"{'total_time_overhead':>19} {'extra_rss_mib':>14}"
)

for budget, _ in cases:
    h2o = results[budget, "h2o_r050"]
    for baseline_name in ("sliding", "age"):
        baseline = results[budget, baseline_name]
        print(
            f"{budget:7d} {baseline_name:>8} "
            f"{-percent(h2o['prompt_tps'], baseline['prompt_tps']):21.1f}% "
            f"{-percent(h2o['generation_tps'], baseline['generation_tps']):18.1f}% "
            f"{percent(h2o['generation_ms'], baseline['generation_ms']):19.1f}% "
            f"{percent(h2o['total_time_seconds'], baseline['total_time_seconds']):18.1f}% "
            f"{h2o['rss_mib'] - baseline['rss_mib']:14.1f}"
        )
