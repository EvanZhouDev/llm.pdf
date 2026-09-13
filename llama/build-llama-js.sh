#!/usr/bin/env bash
set -euo pipefail

# Prepare environment variables
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
LLAMA_HASH="dd047b476c8b904e0c25e5dbc5bee6ffde2f6e17"
LLAMA_DIR="$BUILD_DIR/llama-cpp"
EMSDK_VERSION="1.39.20"
EMSDK_HASH="3249417955d99eb36f92769e3a4f96b134d97326"
EMSDK_DIR="$BUILD_DIR/emsdk"
TARGET_DIR="$BUILD_DIR/llama-bin"
OUTPUT_PATH="${1:-"$ROOT_DIR/llama.js"}"

mkdir -p "$BUILD_DIR"

# Download emsdk
if [[ ! -d "$EMSDK_DIR/.git" ]]; then
    rm -rf "$EMSDK_DIR"
    echo "Downloading emsdk repository..."
    git clone https://github.com/emscripten-core/emsdk.git \
        --branch "$EMSDK_VERSION" \
        "$EMSDK_DIR"
    if [[ $(uname -m) == 'arm64' ]]; then
        echo "Apple Silicon device detected. Applying emsdk patch for Apple Silicon..."
        git -C "$EMSDK_DIR" apply "$ROOT_DIR/patches/emsdk-apple-silicon.patch"
    fi
elif [[ "$(git -C "$EMSDK_DIR" rev-parse HEAD)" != "$EMSDK_HASH" ]]; then
    echo "Existing emsdk checkout is not at $EMSDK_HASH; remove $EMSDK_DIR and retry." >&2
    exit 1
fi

# Actually activate and install emscripten
echo "Downloading and activating Emscripten..."
"$EMSDK_DIR/emsdk" install "${EMSDK_VERSION}-fastcomp"
"$EMSDK_DIR/emsdk" activate "${EMSDK_VERSION}-fastcomp"
source "$EMSDK_DIR/emsdk_env.sh"

# Clone llama.cpp library
if [[ ! -d "$LLAMA_DIR/.git" ]]; then
    rm -rf "$LLAMA_DIR"
    echo "Downloading llama.cpp repository..."
    git init "$LLAMA_DIR"
    git -C "$LLAMA_DIR" remote add origin https://github.com/ggml-org/llama.cpp.git
    git -C "$LLAMA_DIR" fetch --depth 1 origin "$LLAMA_HASH"
    git -C "$LLAMA_DIR" checkout --detach FETCH_HEAD

    # Apply patch
    echo "Applying patch..."
    git -C "$LLAMA_DIR" apply "$ROOT_DIR/patches/llama-cpp-llm-pdf.patch"
elif [[ "$(git -C "$LLAMA_DIR" rev-parse HEAD)" != "$LLAMA_HASH" ]]; then
    echo "Existing llama.cpp checkout is not at $LLAMA_HASH; remove $LLAMA_DIR and retry." >&2
    exit 1
elif ! git -C "$LLAMA_DIR" apply --reverse --check "$ROOT_DIR/patches/llama-cpp-llm-pdf.patch"; then
    echo "Existing llama.cpp checkout does not contain the llm.pdf patch; remove $LLAMA_DIR and retry." >&2
    exit 1
fi

# Set up target directory
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Configure CMake
emcmake cmake "$LLAMA_DIR"

export EMCC_CFLAGS="-O3 -s SINGLE_FILE=1 -fno-rtti -flto=full -s DISABLE_EXCEPTION_CATCHING=0 -sWASM=0 -Wno-fastcomp -Wabsolute-value -static '-sEXPORTED_FUNCTIONS=[_main]' -s INITIAL_MEMORY=1GB -s MAXIMUM_MEMORY=1400MB -s ALLOW_MEMORY_GROWTH -s ASSERTIONS=1 -s --pre-js $ROOT_DIR/polyfill.js"

# Compile llama-cli
cd examples/main
emmake make

# Copy the generated file to the requested output path.
mkdir -p "$(dirname -- "$OUTPUT_PATH")"
cp "$TARGET_DIR/bin/llama-cli.js" "$OUTPUT_PATH"
echo "Built $OUTPUT_PATH"