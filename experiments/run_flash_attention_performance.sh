#!/bin/bash

set -e

cli=./build/bin/llama-cli
model=../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf
prompt=experiments/prompts/natural_manila_c4096.txt
result=experiments/results/performance/natural_manila_c4096_o1024

if [ ! -x "$cli" ] || [ ! -f "$model" ] || [ ! -f "$prompt" ]; then
    echo "llama-cli, model or prompt was not found"
    exit 1
fi

mkdir -p "$result"

for condition in unbounded sliding age; do
    case $condition in
        unbounded)
            context=8192
            policy_args=()
            ;;
        sliding)
            context=4096
            policy_args=(--sliding-window)
            ;;
        age)
            context=4096
            policy_args=(--age-eviction --age-keep-start 128 --age-block-size 64)
            ;;
    esac

    name=${condition}_fa_on
    echo "Running $condition with flash attention on"

    /usr/bin/time -l -o "$result/$name.time" \
        "$cli" \
        -m "$model" \
        -f "$prompt" \
        --single-turn \
        --simple-io \
        --no-display-prompt \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        "${policy_args[@]}" \
        -fa on \
        -c "$context" \
        -n 1024 \
        --perf \
        --show-timings \
        -lv 1 \
        --log-colors off \
        > "$result/$name.out" \
        2> "$result/$name.err"

    grep -q "\[ Prompt: .* | Generation:" "$result/$name.out"
    grep -q "maximum resident set size" "$result/$name.time"
done

echo "Flash-attention performance runs are complete"
