#!/bin/bash

set -e

cli=./build/bin/llama-cli
model=../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf
prompt_dir=experiments/prompts
result_dir=experiments/results/retrieval

if [ $# -ne 1 ]; then
    echo "Usage: bash experiments/run_retrieval_evaluation.sh unbounded|sliding|age|h2o50|h2o90"
    exit 1
fi

condition=$1

# Select the context size, output name and policy arguments.
case $condition in
    unbounded)
        context=8192
        output_name=unbounded
        policy_args=()
        ;;
    sliding)
        context=4096
        output_name=sliding
        policy_args=(--sliding-window)
        ;;
    age)
        context=4096
        output_name=age
        policy_args=(--age-eviction --age-keep-start 128 --age-block-size 64)
        ;;
    h2o50)
        context=4096
        output_name=h2o_r050
        policy_args=(--h2o-eviction --h2o-keep-start 0 --h2o-recent-ratio 0.5)
        ;;
    h2o90)
        context=4096
        output_name=h2o_r090
        policy_args=(--h2o-eviction --h2o-keep-start 0 --h2o-recent-ratio 0.9)
        ;;
    *)
        echo "Unknown condition: $condition"
        exit 1
        ;;
esac

# Run the selected condition on all three needle positions.
for position in early middle end; do
    prompt=$prompt_dir/retrieval_${position}.txt
    result=$result_dir/retrieval_${position}_c4096_o1024

    mkdir -p "$result"
    echo "Running $condition on $position"

    "$cli" \
        -m "$model" \
        -f "$prompt" \
        --single-turn \
        --simple-io \
        --no-display-prompt \
        --temp 0 \
        --seed 42 \
        "${policy_args[@]}" \
        -fa off \
        -c "$context" \
        -n 1024 \
        -lv 3 \
        --log-colors off \
        --show-timings \
        > "$result/$output_name.out" \
        2> "$result/$output_name.err"
done

echo "Completed $condition retrieval runs"
