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

run_ratio() {
    family=$1
    ratio=$2
    tag=$3

    prompt=$PROMPT_DIR/natural_${family}_c1024.txt
    result=$RESULT_DIR/natural_${family}_c1024_o1024
    reference=$result/unbounded.csv

    if [ ! -f "$prompt" ]; then
        echo "Missing prompt: $prompt"
        exit 1
    fi

    if [ ! -f "$reference" ]; then
        echo "Missing reference: $reference"
        exit 1
    fi

    if [ -f "$result/h2o_${tag}.done" ]; then
        echo "Skipping $family with recent ratio $ratio"
        return
    fi

    echo "Running $family with recent ratio $ratio"

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
        --h2o-recent-ratio "$ratio" \
        -fa off \
        -c 1024 \
        -n 1024 \
        -lv 3 \
        --log-colors off \
        --nll-reference "$reference" \
        --nll-output "$result/h2o_${tag}.csv" \
        > "$result/h2o_${tag}.out" \
        2> "$result/h2o_${tag}.err"

    check_rows "$result/h2o_${tag}.csv" 1024
    touch "$result/h2o_${tag}.done"
}

for family in typhoon brock manila; do
    run_ratio "$family" 0.25 r025
    run_ratio "$family" 0.75 r075
    run_ratio "$family" 0.90 r090
done

echo "H2O recent-ratio sensitivity runs completed"
