#!/usr/bin/env python3

import re
from pathlib import Path


result_dir = (
    Path(__file__).resolve().parent
    / "results"
    / "performance"
    / "natural_manila_c4096_o1024"
)

runs = [
    ("unbounded", "unbounded_fa_on", "on", 8192),
    ("sliding", "sliding_fa_on", "on", 4096),
    ("age", "age_fa_on", "on", 4096),
    ("h2o_r050", "h2o_r050", "off", 4096),
]


def get_number(pattern, text, path):
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        raise ValueError(f"Missing value in {path}")
    return float(match.group(1))


def read_result(name, file_name, flash_attention, context):
    out_path = result_dir / f"{file_name}.out"
    err_path = result_dir / f"{file_name}.err"
    time_path = result_dir / f"{file_name}.time"

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

    return {
        "name": name,
        "fa": flash_attention,
        "context": context,
        "prompt_tps": prompt_tps,
        "generation_tps": generation_tps,
        "generation_ms": 1000.0 / generation_tps,
        "total_time_seconds": get_number(
            r"^\s*([0-9.]+) real", time_text, time_path
        ),
        "context_mib": context_mib,
        "rss_mib": get_number(
            r"^\s*(\d+)\s+maximum resident set size", time_text, time_path
        ) / (1024 * 1024),
    }


def percent(new, old):
    return (new - old) / old * 100.0


results = {
    name: read_result(name, file_name, fa, context)
    for name, file_name, fa, context in runs
}

print("Native performance results")
print(
    f"{'context':>8}  {'policy':>12}  {'fa':>4}  {'prompt_tok/s':>14}  "
    f"{'gen_tok/s':>11}  {'gen_ms/tok':>12}  {'total_time_s':>14}  "
    f"{'context_mib':>13}  {'rss_mib':>10}"
)

for name, _, _, _ in runs:
    value = results[name]
    print(
        f"{value['context']:8d}  {name:>12}  {value['fa']:>4}  "
        f"{value['prompt_tps']:14.1f}  {value['generation_tps']:11.1f}  "
        f"{value['generation_ms']:12.2f}  {value['total_time_seconds']:14.2f}  "
        f"{value['context_mib']:13.1f}  {value['rss_mib']:10.1f}"
    )


print("\nH2O practical overhead")
print(
    f"{'baseline':>9}  {'prompt_throughput_loss':>24}  "
    f"{'gen_throughput_loss':>21}  {'gen_latency_overhead':>22}  "
    f"{'total_time_overhead':>21}  {'extra_rss_mib':>16}"
)

h2o = results["h2o_r050"]
for baseline_name in ("sliding", "age"):
    baseline = results[baseline_name]
    print(
        f"{baseline_name:>9}  "
        f"{-percent(h2o['prompt_tps'], baseline['prompt_tps']):23.1f}%  "
        f"{-percent(h2o['generation_tps'], baseline['generation_tps']):20.1f}%  "
        f"{percent(h2o['generation_ms'], baseline['generation_ms']):21.1f}%  "
        f"{percent(h2o['total_time_seconds'], baseline['total_time_seconds']):20.1f}%  "
        f"{h2o['rss_mib'] - baseline['rss_mib']:16.1f}"
    )
