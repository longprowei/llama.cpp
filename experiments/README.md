
## Prepare test prompt files
# 1034 tokens
`sed -n '1,17p' wikitext-2-raw/wiki.test.raw > experiments/prompts/wiki_1k.txt`

# 3817 tokens
`sed -n '1,75p' wikitext-2-raw/wiki.test.raw > experiments/prompts/wiki_3_8k.txt`

# 3935 tokens
`sed -n '1,79p' wikitext-2-raw/wiki.test.raw > experiments/prompts/wiki_3_9k.txt`

# 4006 tokens
`sed -n '1,80p' wikitext-2-raw/wiki.test.raw > experiments/prompts/wiki_4k.txt`


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

Result:
- Prompt throughput: `211.6 t/s`
- Generation throughput: `22.2 t/s`
- Estimated per-token decode latency: `~45.0 ms/token`
- MTL0 memory breakdown:
  - model: `4685 MiB`
  - context: `1024 MiB`
  - compute: `258 MiB`
- Host memory breakdown:
  - model: `281 MiB`
  - context: `0 MiB`
  - compute: `32 MiB`
- Peak RSS: `5463097344 bytes` (`~5.46 GB`)
- Peak memory footprint: `1188099968 bytes` (`~1133.1 MiB`)

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


### Throughput Benchmark with llama-bench
    ./build/bin/llama-bench \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -p 512 \
        -n 128 \
        -r 3 \
        -o md \
        2>&1 | tee /tmp/bench.txt

Result:
| model                          |       size |     params | backend    | threads |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | ------: | --------------: | -------------------: |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | MTL,BLAS   |       6 |           pp512 |        222.14 ± 0.05 |
| llama 8B Q4_K - Medium         |   4.58 GiB |     8.03 B | MTL,BLAS   |       6 |           tg128 |         23.91 ± 0.17 |

### Quality Baseline With llama-perplexity
    /usr/bin/time -l ./build/bin/llama-perplexity \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f wikitext-2-raw/wiki.test.raw \
        -c 2048 \
        --ppl-stride 512 \
        --perf \
        2>&1 | tee /tmp/perplexity.txt

Result: 
- Final perplexity: `6.4422`
- Input tokens processed: `289078`
- Chunks: `561`
- Effective context size: `2304`
- Prompt eval throughput: `193.89 t/s`
- Prompt eval cost: `5.16 ms/token`
- MTL0 KV/context memory:
  - KV buffer size: `288 MiB`
  - context memory breakdown: `288 MiB`
- MTL0 memory breakdown:
  - model: `4685 MiB`
  - compute: `266 MiB`
- Host memory breakdown:
  - model: `281 MiB`
  - context: `0 MiB`
  - compute: `20 MiB`
- Peak RSS: `8428748800 bytes` (`~8.43 GB`)
- Peak memory footprint: `3713452608 bytes` (`~3.46 GiB`)

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
    
