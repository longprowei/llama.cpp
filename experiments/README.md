# KV-Cache Experiments

This folder contains the scripts, logs, and result files used for the KV-Cache memory management experiments in this project.

## Included results

The main experimental results used in the report are already committed in this folder. In most cases, it is not necessary to rerun the experiments in order to inspect the project outcomes. If you only want to review the reported behaviour, you can read the saved logs and result summaries directly.

## External files not included

The repository does not include the following large external files:

- the LLM model file used for inference
- the raw WikiText-2 source files used to prepare the natural continuation prompts

## Model used

The experiments in the report were run using:

- `Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf`

If you want to rerun the experiments, download the same GGUF model file and place it in a `models/` folder at the same level as the `llama.cpp/` folder, so the commands in this README can use:

`../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf`

Model page:
https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF


## Prompt data used

The prompt files used by the main experiment commands in this folder are already committed under `experiments/prompts/`.

If you only want to inspect the saved results or rerun the listed commands directly, you do not need to regenerate these prompt files.

The raw WikiText-2 files are only needed if you want to rebuild the natural continuation prompt files from scratch. Use `scripts/get-wikitext-2.sh` from the repository root to download the WikiText-2 raw files.


## Reproducing the experiments

To rerun the experiments at a high level:

1. Build the modified `llama.cpp` code in this repository.

   On macOS, the commands used in this project were:

   ```bash
   cmake -B build
   cmake --build build --config Release -j
   ```

2. Download the required GGUF model file and place it in the sibling `models/` folder described above.
3. If needed, regenerate the WikiText-based prompt files using the downloaded raw dataset.
4. Run the commands in this folder to regenerate logs and outputs.

Note that runtime throughput and memory measurements may vary across hardware platforms, but the saved results in this folder correspond to the runs used in the submitted report.

## Notes

- The committed outputs in this folder are the primary reference for the report results.
- Reproducing the exact numbers may depend on using similar hardware, model quantisation, and runtime settings.

## Experiment Commands

### Prepare test prompt files
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


### Commands for baseline test and some results
#### Unbounded Baseline With llama-cli - 3.8k tokens prompt
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

#### Unbounded Baseline With llama-cli - 3.9k tokens prompt
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

#### Unbounded Baseline With llama-cli - 4k tokens prompt
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

#### Unbounded Baseline With llama-cli - 1k tokens prompt
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


#### Sliding Window Baseline With llama-cli - 3.8k tokens
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

#### Sliding Window Baseline With llama-cli - 3.9k tokens
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

#### Sliding Window Baseline With llama-cli - 4k tokens
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

#### Sliding Window Baseline With llama-cli - 1k tokens
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


#### Age-based policy llama-cli - 3.8k tokens
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

#### Age-based policy llama-cli - 3.9k tokens
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

#### Age-based policy llama-cli - 4k tokens
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

#### Age-based policy llama-cli - 1k tokens
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

#### Age-based policy llama-cli - 3.9k tokens but use 32 tokens blocks
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

#### Age-based policy llama-cli - 3.9k tokens but use 128 tokens blocks
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

### Generate the divergence results
#### Output divergence
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


### Needle in a Haystack test
#### Unbounded Baseline
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

#### Sliding Window
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

#### Age-based
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

### Command to test token size in a prompt example
    ./build/bin/llama-tokenize \
    -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
    -f experiments/prompts/wiki_3_9k_needle_start.txt \
    --show-count \
    --log-disable
