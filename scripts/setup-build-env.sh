#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v apt-get >/dev/null 2>&1; then
    if [[ "$(id -u)" -eq 0 ]]; then
        APT_GET=(env DEBIAN_FRONTEND=noninteractive apt-get)
    elif command -v sudo >/dev/null 2>&1; then
        APT_GET=(sudo env DEBIAN_FRONTEND=noninteractive apt-get)
    else
        echo "apt-get requires root or sudo to install build prerequisites." >&2
        exit 1
    fi

    "${APT_GET[@]}" update
    "${APT_GET[@]}" install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        g++ \
        git \
        make \
        python3 \
        python3-venv \
        xz-utils
fi

python3 -m venv "$ROOT_DIR/.venv"
"$ROOT_DIR/.venv/bin/python" -m pip install -r "$ROOT_DIR/requirements.txt"

echo
echo "Python build environment is ready at $ROOT_DIR/.venv"
echo "Run $ROOT_DIR/llama/build-llama-js.sh to install Emscripten and rebuild llama.js."
