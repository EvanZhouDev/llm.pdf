#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL_DIR="${MODEL_DIR:-"$ROOT_DIR/models"}"
OUTPUT_DIR="${OUTPUT_DIR:-"$ROOT_DIR/builds"}"
PYTHON="${PYTHON:-"$ROOT_DIR/.venv/bin/python"}"
HF="${HF:-"$ROOT_DIR/.venv/bin/hf"}"
MODEL_FILTER="${1:-all}"

if [[ ! -x "$PYTHON" || ! -x "$HF" ]]; then
    echo "Python dependencies are missing. Run ./scripts/setup-build-env.sh first." >&2
    exit 1
fi

process_model() {
    local model_key="$1"
    local model_repo="$2"
    local model_file="$3"
    local new_name="$4"
    local file_name="$5"

    if [[ "$MODEL_FILTER" != "all" && "$MODEL_FILTER" != "$model_key" ]]; then
        return
    fi

    if [[ ! -f "$MODEL_DIR/$new_name" ]]; then
        "$HF" download "$model_repo" "$model_file" --local-dir "$MODEL_DIR"
        mv "$MODEL_DIR/$model_file" "$MODEL_DIR/$new_name"
    else
        echo "models/$new_name exists, skipping download"
    fi
    "$PYTHON" "$ROOT_DIR/scripts/generatePDF.py" \
        --model "$MODEL_DIR/$new_name" \
        --output "$OUTPUT_DIR/$file_name"
}

case "$MODEL_FILTER" in
    all | pythia | smollm | tinyllm | tinystories) ;;
    *)
        echo "Unknown model '$MODEL_FILTER'. Use all, pythia, smollm, tinyllm, or tinystories." >&2
        exit 2
        ;;
esac

mkdir -p "$MODEL_DIR" "$OUTPUT_DIR"
process_model \
    "pythia" \
    "tensorblock/Pythia-31M-Chat-v1-GGUF" \
    "Pythia-31M-Chat-v1-Q8_0.gguf" \
    "pythia-chat-31M-q8.gguf" \
    "pythia-llm.pdf"
process_model \
    "smollm" \
    "unsloth/SmolLM2-135M-Instruct-GGUF" \
    "SmolLM2-135M-Instruct-Q8_0.gguf" \
    "smollm2-it-135M-q8.gguf" \
    "smollm-llm.pdf"
process_model \
    "tinyllm" \
    "mradermacher/Tiny-LLM-GGUF" \
    "Tiny-LLM.Q8_0.gguf" \
    "tinyllm-10M-q8.gguf" \
    "tinyllm-llm.pdf"
process_model \
    "tinystories" \
    "afrideva/Tinystories-gpt-0.1-3m-GGUF" \
    "tinystories-gpt-0.1-3m.Q8_0.gguf" \
    "tinystories-3M-q8.gguf" \
    "tinystories-llm.pdf"
