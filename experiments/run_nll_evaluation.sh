#!/bin/bash

set -e

CLI=./build/bin/llama-cli
MODEL=../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf
PROMPT_DIR=experiments/prompts
RESULT_DIR=experiments/results/nll

check_rows() {
    csv=$1
    expected=$2
    rows=$(($(wc -l < "$csv") - 1))

    if [ "$rows" -ne "$expected" ]; then
        echo "Expected $expected tokens in $csv, but found $rows"
        exit 1
    fi
}

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
        check_rows "$result/unbounded.csv" "$output"
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
        check_rows "$result/sliding.csv" "$output"
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
        check_rows "$result/age.csv" "$output"
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
        check_rows "$result/h2o.csv" "$output"
        touch "$result/h2o.done"
    fi
}

run_budget() {
    context=$1
    output=${2:-}

    case $context in
        1024)
            output=${output:-256}
            ;;
        2048)
            output=${output:-512}
            ;;
        4096)
            output=${output:-1024}
            ;;
        *)
            echo "Usage: bash experiments/run_nll_evaluation.sh [1024|2048|4096] [output tokens]"
            exit 1
            ;;
    esac

    run_case typhoon "$context" "$output"
    run_case brock "$context" "$output"
    run_case manila "$context" "$output"
}

if [ $# -eq 0 ]; then
    run_budget 1024
    run_budget 2048
    run_budget 4096
elif [ $# -le 2 ]; then
    run_budget "$1" "${2:-}"
else
    echo "Usage: bash experiments/run_nll_evaluation.sh [1024|2048|4096] [output tokens]"
    exit 1
fi

echo "All selected NLL runs are complete"
