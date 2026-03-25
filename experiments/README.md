
## Prepare test file
for unbounded test
`sed -n '1,20p' wikitext-2-raw/wiki.test.raw > /tmp/prompt_short.txt`


## Commands for baseline test and some results
### Unbounded Baseline With llama-cli
    /usr/bin/time -l ./build/bin/llama-cli \
        -m /Users/chenglongwei/Documents/UNSW_study/comp9991/models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f /tmp/prompt_long.txt \
        --no-conversation \
        --single-turn \
        --simple-io \
        --show-timings \
        --perf \
        --temp 0 \
        --top-k 1 \
        --ignore-eos \
        -c 4096 \
        -n 128 \
        2>&1 | tee /tmp/unbounded_cli.txt

Result:
- Prompt throughput: `222.4 t/s`
- Generation throughput: `23.8 t/s`
- Estimated per-token decode latency: `~42.0 ms/token`
- MTL0 memory breakdown:
  - model: `4685 MiB`
  - context: `512 MiB`
  - compute: `258 MiB`
- Host memory breakdown:
  - model: `281 MiB`
  - context: `0 MiB`
  - compute: `24 MiB`
- Peak RSS: `5485707264 bytes` (`~5.49 GB`)
- Peak memory footprint: `640200960 bytes` (`~610.5 MiB`)

### Throughput Benchmark with llama-bench
    ./build/bin/llama-bench \
        -m /Users/chenglongwei/Documents/UNSW_study/comp9991/models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
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
        -m /Users/chenglongwei/Documents/UNSW_study/comp9991/models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
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
