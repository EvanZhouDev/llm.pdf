<img src="./assets/logo.svg" width="300px">

> Run LLMs inside a PDF file.

Watch how llm.pdf was built [on YouTube](https://youtu.be/4cBom2lAx-g).

## What is llm.pdf?

This is a proof-of-concept project, showing that it's possible to run an entire Large Language Model in nothing but a PDF file.

It uses [Emscripten](https://emscripten.org/) to compile [llama.cpp](https://github.com/ggml-org/llama.cpp?tab=readme-ov-file) into [asm.js](https://en.wikipedia.org/wiki/Asm.js), which can then be run in the PDF using an old PDF JS injection.

Combined with embedding the entire LLM file into the PDF with base64, we are able to run LLM inference in nothing but a PDF.

[Watch the video on YouTube](https://youtu.be/4cBom2lAx-g) to learn the full story!

## Rebuild from Source

The complete build has been tested on Ubuntu 24.04 x86_64. It uses the project's
pinned Emscripten 1.39.20-fastcomp asm.js toolchain and llama.cpp commit.

```sh
# Install OS packages and pinned Python dependencies.
./scripts/setup-build-env.sh

# Download the pinned toolchains and rebuild llama/llama.js.
./llama/build-llama-js.sh

# Download the existing 3M TinyStories demo model and build a PDF.
OUTPUT_DIR="$PWD/rebuilds" ./scripts/build-pdfs.sh tinystories
```

The demo artifact is written to `rebuilds/tinystories-llm.pdf`. To rebuild all
four models listed in `scripts/build-pdfs.sh`, omit the model name (or use
`all`). The model downloads and generated PDFs are large, so they are not
installed as part of the Python environment setup.

Both build scripts can be run from any working directory. Pass an output path
to `llama/build-llama-js.sh` to test the compiler without replacing the checked
in `llama/llama.js`:

```sh
./llama/build-llama-js.sh /tmp/llama.js
```

## Load a Custom Model in the PDF

The `scripts/generatePDF.py` file will help you create a PDF with any compatible LLM.

The easiest way to get started is with the following command:
```sh
./.venv/bin/python scripts/generatePDF.py \
  --model "path/to/model.gguf" \
  --output "path/to/output.pdf"
```

### Choosing a Model

Here's the general guidelines when picking a model:

* Only GGUF quantized models work.
* Generally, try to use Q8 quantized models, as those run the fastest.
* For reference, 135M parameter models take around 5s per token input/output. Anything higher will likely be unreasonably slow.

## Inspiration and Credits

Thank you to the following for inspiration and reference:
* [ading2210's DoomPDF](https://github.com/ading2210/doompdf)
* [rahuldshetty's llm.js](https://github.com/rahuldshetty/llm.js)

Thank you to the following for creating the tiny LLMs that power llm.pdf:
* [EleutherAI's pythia models](https://github.com/EleutherAI/pythia)
* [Ronen Eldan and Yuanzhi Li's TinyStories LLM](https://arxiv.org/abs/2305.07759)
* [arnir0's Tiny-LLM](https://arxiv.org/abs/2305.07759)