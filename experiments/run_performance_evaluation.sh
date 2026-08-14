#!/bin/bash

set -e

cli=./build/bin/llama-cli
model=../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf
prompt_dir=experiments/prompts
result_dir=experiments/results/performance

if [ ! -x "$cli" ]; then
    echo "llama-cli was not found: $cli"
    exit 1
fi

if [ ! -f "$model" ]; then
    echo "Model was not found: $model"
    exit 1
fi

run_condition() {
    condition=$1
    budget=$2
    output=$3

    prompt=$prompt_dir/natural_manila_c${budget}.txt
    result=$result_dir/natural_manila_c${budget}_o${output}

    case $condition in
        unbounded)
            context=8192
            output_name=unbounded
            policy_args=()
            ;;
        sliding)
            context=$budget
            output_name=sliding
            policy_args=(--sliding-window)
            ;;
        age)
            context=$budget
            output_name=age
            policy_args=(--age-eviction --age-keep-start 128 --age-block-size 64)
            ;;
        h2o)
            context=$budget
            output_name=h2o_r050
            policy_args=(--h2o-eviction --h2o-keep-start 0 --h2o-recent-ratio 0.5)
            ;;
    esac

    if [ ! -f "$prompt" ]; then
        echo "Prompt was not found: $prompt"
        exit 1
    fi

    mkdir -p "$result"
    echo "Running $condition with context $context, budget $budget and output $output"

    /usr/bin/time -l -o "$result/$output_name.time" \
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
        -fa off \
        -c "$context" \
        -n "$output" \
        --perf \
        --show-timings \
        -lv 1 \
        --log-colors off \
        > "$result/$output_name.out" \
        2> "$result/$output_name.err"

    if ! grep -q "\[ Prompt: .* | Generation:" "$result/$output_name.out"; then
        echo "Timing result was not found in $result/$output_name.out"
        exit 1
    fi

    if ! grep -q "maximum resident set size" "$result/$output_name.time"; then
        echo "Memory result was not found in $result/$output_name.time"
        exit 1
    fi
}

run_budget() {
    budget=$1

    case $budget in
        1024)
            output=256
            conditions=(unbounded sliding age h2o)
            ;;
        2048)
            output=512
            conditions=(h2o age sliding unbounded)
            ;;
        4096)
            output=1024
            conditions=(sliding unbounded h2o age)
            ;;
        *)
            echo "Usage: bash experiments/run_performance_evaluation.sh [1024|2048|4096]"
            exit 1
            ;;
    esac

    # Change the order between budgets to reduce order and thermal bias.
    for condition in "${conditions[@]}"; do
        run_condition "$condition" "$budget" "$output"
    done
}

if [ $# -eq 0 ]; then
    run_budget 1024
    run_budget 2048
    run_budget 4096
elif [ $# -eq 1 ]; then
    run_budget "$1"
else
    echo "Usage: bash experiments/run_performance_evaluation.sh [1024|2048|4096]"
    exit 1
fi

echo "All selected performance runs are complete"
