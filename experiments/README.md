# KV-Cache Experiments

This folder contains the scripts, logs, and result files used for the KV-Cache memory management experiments in this project.

## Included results

The experimental results used in the report are stored in this folder. In most cases, it is not necessary to rerun the experiments to inspect the project outcomes. Previous results are stored under `experiments/legacy/`, and the current evaluation results are saved under `experiments/results/`.

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

The prompt files used by the main experiment commands in this folder are stored under `experiments/prompts/`.

If you only want to inspect the saved results or rerun the listed commands directly, you do not need to regenerate these prompt files.

The raw WikiText-2 files are only needed if you want to rebuild the natural continuation prompt files from scratch. Use `scripts/get-wikitext-2.sh` from the repository root to download the WikiText-2 raw files.


## Reproducing the experiments

To rerun the experiments at a high level:

1. Build the modified `llama.cpp` code in this repository.

   On macOS, the commands used in this project were:

       cmake -B build
       cmake --build build --config Release -j 2

2. Download the required GGUF model file and place it in the sibling `models/` folder described above.
3. If needed, regenerate the WikiText-based prompt files using the downloaded raw dataset.
4. Run the evaluation scripts listed below to regenerate logs and outputs.

Note that runtime throughput and memory measurements may vary across hardware platforms.

## Notes

- The previous outputs are stored under `experiments/legacy/`.
- Reproducing the exact numbers may depend on using similar hardware, model quantisation, and runtime settings.

## Experiment Commands

### Prepare test prompt files

#### Family A: 2003 Pacific typhoon season

    sed -n '1497,1506p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_typhoon_c1024.txt
    sed -n '1497,1514p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_typhoon_c2048.txt
    sed -n '1497,1534p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_typhoon_c4096.txt

#### Family B: Brock Lesnar

    sed -n '1834,1839p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_brock_c1024.txt
    sed -n '1834,1860p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_brock_c2048.txt
    sed -n '1834,1868p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_brock_c4096.txt

#### Family C: Manila

    sed -n '2992,3001p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_manila_c1024.txt
    sed -n '2992,3009p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_manila_c2048.txt
    sed -n '2992,3024p' wikitext-2-raw/wiki.test.raw > experiments/prompts/natural_manila_c4096.txt

### Count prompt tokens

    ./experiments/count_tokens.sh

## Token-level NLL drift evaluation

The script records an 8192-context unbounded reference and replays the same token IDs under sliding-window, age-based and H2O. It tests the 1024, 2048 and 4096 context budgets using all nine natural prompts.

Run the full evaluation from the repository root:

    bash experiments/run_nll_evaluation.sh

Run only the 1024-context cases first as a smaller test:

    bash experiments/run_nll_evaluation.sh 1024

Run the 1024-context long-generation test with 1024 output tokens:

    bash experiments/run_nll_evaluation.sh 1024 1024

The optional second argument changes the output length and saves the results in a separate output directory. The script runs one command at a time and checks the CSV token count before it creates a `.done` file, so completed runs are skipped when the script is restarted. Delete the related `.done` file if that command needs to run again.

Results are saved under `experiments/results/nll/`. H2O uses the fixed default recent ratio of 0.5, and flash attention is disabled for every policy to keep the quality comparison controlled. The timings from these NLL runs should not be used for the latency or throughput evaluation.

### H2O ratio 1.0 correctness check

This checks whether H2O with recent ratio 1.0 produces the same result as sliding-window.

    result=experiments/results/nll/natural_brock_c1024_o1024

    ./build/bin/llama-cli \
        -m ../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf \
        -f experiments/prompts/natural_brock_c1024.txt \
        --single-turn \
        --simple-io \
        --temp 0 \
        --seed 42 \
        --ignore-eos \
        --h2o-eviction \
        --h2o-keep-start 0 \
        --h2o-recent-ratio 1.0 \
        -fa off \
        -c 1024 \
        -n 1024 \
        -lv 3 \
        --log-colors off \
        --nll-reference "$result/unbounded.csv" \
        --nll-output "$result/h2o_r100.csv" \
        > "$result/h2o_r100.out" \
        2> "$result/h2o_r100.err"

Check the CSV row count and compare it with sliding-window:

    wc -l "$result/h2o_r100.csv"

    cmp -s "$result/sliding.csv" "$result/h2o_r100.csv" \
        && echo "PASS: H2O ratio 1.0 matches sliding" \
        || echo "DIFFERENT: results need inspection"

The expected result is 1025 lines including the header and `PASS` from the comparison.

### H2O recent-ratio sensitivity

Run H2O with recent ratios 0.25, 0.75 and 0.90 on the three 1024-context long-generation cases:

    bash experiments/run_h2o_ratio_sensitivity.sh

The results are saved beside the existing 1024-context results using the names `h2o_r025`, `h2o_r075` and `h2o_r090`.

### Calculate post-eviction NLL drift

Use the analysis script to calculate the mean, mean absolute, median absolute, P95 absolute and maximum absolute NLL drift after eviction starts:

    python3 experiments/analyze_nll.py 1024 256
    python3 experiments/analyze_nll.py 2048 512
    python3 experiments/analyze_nll.py 4096 1024
    python3 experiments/analyze_nll.py 1024 1024

The two arguments are the context size and output length. The script reads the prompt token count from each saved log and compares the policy CSV files that exist for all three prompts. P95 uses linear interpolation, and every macro value gives each prompt equal weight.

## Free-generation retrieval evaluation

Run the unbounded baselines first:

    bash experiments/run_retrieval_evaluation.sh unbounded

Check that each output has six summary paragraphs with 250 to 350 words, does not mention the classroom in the summary, and has `Ainsworth-G03` in the final answer.

Run the bounded policies:

    bash experiments/run_retrieval_evaluation.sh sliding
    bash experiments/run_retrieval_evaluation.sh age
    bash experiments/run_retrieval_evaluation.sh h2o50

Run H2O with recent ratio 0.9 for sensitivity:

    bash experiments/run_retrieval_evaluation.sh h2o90

Each command runs the early, middle and end prompts. The maximum output length is 1024 tokens. Results are saved under `experiments/results/retrieval/`.

## Performance and memory evaluation

Run all performance cases:

    bash experiments/run_performance_evaluation.sh

Run only one context size if needed:

    bash experiments/run_performance_evaluation.sh 1024

The script runs sliding-window, age-based and H2O with ratio 0.5 once for each bounded context budget, with an 8192-context unbounded comparison. It uses the Manila prompts, runs one command at a time, disables flash attention and does not use NLL.

Results are saved under `experiments/results/performance/`. The `.out` files contain prompt and generation throughput, the `.err` files contain the llama.cpp memory breakdown, and the macOS `.time` files contain wall time and peak memory. Rerunning a case replaces its previous results.

Calculate the performance and memory comparison:

    python3 experiments/analyze_performance.py

### Flash-attention performance comparison

Run the 4096-context Manila comparison with flash attention enabled for unbounded, sliding-window and age-based:

    bash experiments/run_flash_attention_performance.sh

The results are saved beside the existing 4096-context performance results using the suffix `fa_on`. H2O still uses the existing flash-attention-off result.

Calculate the native performance comparison:

    python3 experiments/analyze_flash_attention.py

## Qwen3 cross-model retrieval check

Download the official Qwen3-8B Q4_K_M model from the repository root:

    curl -L -C - --progress-bar \
        -o ../models/Qwen3-8B-Q4_K_M.gguf \
        "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf?download=true"

Run the early-position retrieval test:

    bash experiments/run_qwen_retrieval.sh

The script runs unbounded, sliding-window, age-based and H2O with recent ratio 0.5. Results are saved under `experiments/results/retrieval_qwen/`.
