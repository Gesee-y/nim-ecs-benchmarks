#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

for src in src/*_bench.nim; do
    if ! nim c -r -d:danger --mm:orc --cc:clang --passC:"-flto -march=native" --passL:"-flto" -o:bench_runner "$@" "$src"; then
        echo "!!! Benchmark failed for $src" >&2
        exit 1
    fi
done

nim r src/report.nim
