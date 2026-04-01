
## Prepare test file
for unbounded test
`sed -n '1,20p' wikitext-2-raw/wiki.test.raw > /tmp/prompt_short.txt`
`sed -n '1,75p' wikitext-2-raw/wiki.test.raw > /tmp/prompt_long.txt`


## Commands for baseline test and some results
### Unbounded Baseline With llama-cli
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f /tmp/prompt_long.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --ignore-eos \
        -c 8192 \
        -n 512 \
        2>&1 | tee /tmp/unbounded_cli.txt

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

# Sliding Window Baseline With llama-cli
    /usr/bin/time -l ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f /tmp/prompt_long.txt \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --ignore-eos \
        --sliding-window 4096 \
        -c 8192 \
        -n 512 \
        2>&1 | tee /tmp/sliding_win_cli.txt

Result:
- Prompt throughput: `211.7 t/s`
- Generation throughput: `20.4 t/s`
- Estimated per-token decode latency: `~49.0 ms/token`
- MTL0 memory breakdown:
  - model: `4685 MiB`
  - context: `544 MiB`
  - compute: `258 MiB`
- Host memory breakdown:
  - model: `281 MiB`
  - context: `0 MiB`
  - compute: `24 MiB`
- Peak RSS: `5386780672 bytes` (`~5.39 GB`)
- Peak memory footprint: `682586880 bytes` (`~651.0 MiB`)
