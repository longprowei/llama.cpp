#!/bin/bash

for file in experiments/prompts/natural_*.txt; do
    echo "$file"
    ./build/bin/llama-tokenize \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f "$file" \
        --no-bos \
        --show-count \
        --log-disable |
        tail -n 1
done
