
## Prepare test prompt files
1034 tokens
`sed -n '1,17p' wikitext-2-raw/wiki.test.raw > experiments/prompts/wiki_1k.txt`

3817 tokens
`sed -n '1,75p' wikitext-2-raw/wiki.test.raw > experiments/prompts/wiki_3_8k.txt`

3935 tokens
`sed -n '1,79p' wikitext-2-raw/wiki.test.raw > experiments/prompts/wiki_3_9k.txt`

4006 tokens
`sed -n '1,80p' wikitext-2-raw/wiki.test.raw > experiments/prompts/wiki_4k.txt`

3992 tokens
wiki_3_9k_needle_start.txt, wiki_3_9k_needle_middle.txt, wiki_3_9k_needle_end.txt


## Commands for baseline test and some results
### Unbounded Baseline With llama-cli - 3.8k tokens prompt
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_8k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/unbounded_3_8k_o512.txt

### Unbounded Baseline With llama-cli - 3.9k tokens prompt
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/unbounded_3_9k_o512.txt

### Unbounded Baseline With llama-cli - 4k tokens prompt
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_4k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/unbounded_4k_o512.txt

### Unbounded Baseline With llama-cli - 1k tokens prompt
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_1k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/unbounded_1k_o512.txt


# Sliding Window Baseline With llama-cli - 3.8k tokens
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_8k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --sliding-window 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/sliding_win_3_8k_o512.txt

# Sliding Window Baseline With llama-cli - 3.9k tokens
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --sliding-window 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/sliding_win_3_9k_o512.txt

# Sliding Window Baseline With llama-cli - 4k tokens
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_4k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --sliding-window 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/sliding_win_4k_o512.txt

# Sliding Window Baseline With llama-cli - 1k tokens
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_1k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --sliding-window 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/sliding_win_1k_o512.txt


# age and importance based policy llama-cli - 3.8k tokens
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_8k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/age_based_3_8k_o512.txt

# age and importance based policy llama-cli - 3.9k tokens
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/age_based_3_9k_o512.txt

# age and importance based policy llama-cli - 4k tokens
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_4k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/age_based_4k_o512.txt

# age and importance based policy llama-cli - 1k tokens
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_1k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/age_based_1k_o512.txt

# age and importance based policy llama-cli - 3.9k tokens but use 32 tokens blocks
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        --age-block-size 32 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/age_based_3_9k_o512_b32.txt

# age and importance based policy llama-cli - 3.9k tokens but use 128 tokens blocks
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        --age-block-size 128 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/age_based_3_9k_o512_b128.txt

# output divergence
  python3 output_divergence.py \
    --name wiki_3_8k_o512 \
    --baseline unbounded_3_8k_o512.txt \
    --sliding sliding_win_3_8k_o512.txt \
    --age age_based_3_8k_o512.txt \
    --out-dir divergence_results

  python3 output_divergence.py \          
    --name wiki_4k_o512 \                                    
    --baseline unbounded_4k_o512.txt \  
    --sliding sliding_win_4k_o512.txt \  
    --age age_based_4k_o512.txt  \ 
    --out-dir divergence_results

  python3 output_divergence.py \                                     
    --name wiki_3_9k_o512 \
    --baseline unbounded_3_9k_o512.txt \
    --sliding sliding_win_3_9k_o512.txt \
    --age age_based_3_9k_o512.txt \
    --out-dir divergence_results

    python3 output_divergence.py \
        --name wiki_1k_o512 \
        --baseline unbounded_1k_o512.txt \
        --sliding sliding_win_1k_o512.txt \
        --age age_based_1k_o512.txt \
        --out-dir divergence_results


# Needle in a Haystack test
### Unbounded Baseline
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_start.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_start_unbounded.txt

    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_middle.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_middle_unbounded.txt

    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_end.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_end_unbounded.txt

### Sliding Window
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_start.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --sliding-window 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_start_sw.txt

    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_middle.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --sliding-window 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_middle_sw.txt

    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_end.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --sliding-window 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_end_sw.txt

### age based
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_start.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_start_age.txt

    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_middle.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_middle_age.txt

    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/wiki_3_9k_needle_end.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --age-eviction 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee experiments/needle_end_age.txt

# command to test token size in a prompt
    ./build/bin/llama-tokenize \
    -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
    -f experiments/prompts/wiki_3_9k_needle_start.txt \
    --show-count \
    --log-disable
