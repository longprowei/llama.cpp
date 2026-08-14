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
