#!/bin/bash

set -e

cli=./build/bin/llama-cli
model=../models/Qwen3-8B-Q4_K_M.gguf
prompt=experiments/prompts/retrieval_early_qwen.txt
result=experiments/results/retrieval_qwen/retrieval_early_c4096_o1024

mkdir -p "$result"

for condition in unbounded sliding age h2o_r050; do
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
        h2o_r050)
            context=4096
            policy_args=(--h2o-eviction --h2o-keep-start 0 --h2o-recent-ratio 0.5)
            ;;
    esac

    echo "Running Qwen3 $condition"

    "$cli" \
        -m "$model" \
        -f "$prompt" \
        --single-turn \
        --simple-io \
        --no-display-prompt \
        --jinja \
        --reasoning-budget 0 \
        --temp 0 \
        --seed 42 \
        "${policy_args[@]}" \
        -fa off \
        -c "$context" \
        -n 1024 \
        -lv 3 \
        --log-colors off \
        --show-timings \
        > "$result/$condition.out" \
        2> "$result/$condition.err"
done

echo "Completed Qwen3 retrieval runs"
