#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

for src in src/*_bench.nim; do
    if ! nim c -r -d:danger -o:bench_runner "$@" "$src"; then
        echo "!!! Benchmark failed for $src" >&2
        exit 1
    fi
done

nim r src/results.nim
