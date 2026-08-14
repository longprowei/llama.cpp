#!/bin/bash

set -e

CLI=./build/bin/llama-cli
MODEL=../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf
PROMPT_DIR=experiments/prompts
RESULT_DIR=experiments/results/nll

run_case() {
    family=$1
    context=$2
    output=$3

    prompt=$PROMPT_DIR/natural_${family}_c${context}.txt
    result=$RESULT_DIR/natural_${family}_c${context}_o${output}

    mkdir -p "$result"
    echo "Running $family with context $context and output $output"

    # Generate the unbounded reference tokens.
    if [ ! -f "$result/unbounded.done" ]; then
        "$CLI" \
            -m "$MODEL" \
            -f "$prompt" \
            --single-turn \
            --simple-io \
            --temp 0 \
            --seed 42 \
            --ignore-eos \
            -fa off \
            -c 8192 \
            -n "$output" \
            -lv 3 \
            --log-colors off \
            --nll-output "$result/unbounded.csv" \
            > "$result/unbounded.out" \
            2> "$result/unbounded.err"
        touch "$result/unbounded.done"
    fi

    # Replay the reference tokens with sliding-window eviction.
    if [ ! -f "$result/sliding.done" ]; then
        "$CLI" \
            -m "$MODEL" \
            -f "$prompt" \
            --single-turn \
            --simple-io \
            --temp 0 \
            --seed 42 \
            --ignore-eos \
            --sliding-window \
            -fa off \
            -c "$context" \
            -n "$output" \
            -lv 3 \
            --log-colors off \
            --nll-reference "$result/unbounded.csv" \
            --nll-output "$result/sliding.csv" \
            > "$result/sliding.out" \
            2> "$result/sliding.err"
        touch "$result/sliding.done"
    fi

    # Replay the reference tokens with age-based eviction.
    if [ ! -f "$result/age.done" ]; then
        "$CLI" \
            -m "$MODEL" \
            -f "$prompt" \
            --single-turn \
            --simple-io \
            --temp 0 \
            --seed 42 \
            --ignore-eos \
            --age-eviction \
            --age-keep-start 128 \
            --age-block-size 64 \
            -fa off \
            -c "$context" \
            -n "$output" \
            -lv 3 \
            --log-colors off \
            --nll-reference "$result/unbounded.csv" \
            --nll-output "$result/age.csv" \
            > "$result/age.out" \
            2> "$result/age.err"
        touch "$result/age.done"
    fi

    # Replay the reference tokens with H2O eviction.
    if [ ! -f "$result/h2o.done" ]; then
        "$CLI" \
            -m "$MODEL" \
            -f "$prompt" \
            --single-turn \
            --simple-io \
            --temp 0 \
            --seed 42 \
            --ignore-eos \
            --h2o-eviction \
            --h2o-keep-start 0 \
            --h2o-recent-ratio 0.5 \
            -fa off \
            -c "$context" \
            -n "$output" \
            -lv 3 \
            --log-colors off \
            --nll-reference "$result/unbounded.csv" \
            --nll-output "$result/h2o.csv" \
            > "$result/h2o.out" \
            2> "$result/h2o.err"
        touch "$result/h2o.done"
    fi
}

run_budget() {
    case $1 in
        1024)
            run_case typhoon 1024 256
            run_case brock 1024 256
            run_case manila 1024 256
            ;;
        2048)
            run_case typhoon 2048 512
            run_case brock 2048 512
            run_case manila 2048 512
            ;;
        4096)
            run_case typhoon 4096 1024
            run_case brock 4096 1024
            run_case manila 4096 1024
            ;;
        *)
            echo "Usage: bash experiments/run_nll_evaluation.sh [1024|2048|4096]"
            exit 1
            ;;
    esac
}

if [ $# -eq 0 ]; then
    run_budget 1024
    run_budget 2048
    run_budget 4096
else
    run_budget "$1"
fi

echo "All selected NLL runs are complete"
