#!/bin/bash
# Copyright (c) The Diem Core Contributors
# SPDX-License-Identifier: Apache-2.0

# Check that the test directory and report path arguments are provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <outdir> [--batch]"
  echo "The resulting coverage report will be stored in <outdir>."
  echo "--batch will skip all prompts."
  exit 1
fi

# User prompts will be skipped if '--batch' is given as the third argument
SKIP_PROMPTS=0
if [ $# -eq 2 ] && [ "$2" == "--batch" ]; then
  SKIP_PROMPTS=1
fi

# Set the directory to which the report will be saved
COVERAGE_DIR=$1

# This needs to run in starcoin
STARCOIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
if [ "$(pwd)" != "$STARCOIN_DIR" ]; then
  echo "Error: This needs to run from starcoin/, not in $(pwd)" >&2
  exit 1
fi

#set -e

# # Check that grcov is installed
# if ! [ -x "$(command -v grcov)" ]; then
#   echo "Error: grcov is not installed." >&2
#   if [ $SKIP_PROMPTS -eq 0 ]; then
#     read -p "Install grcov? [yY/*] " -n 1 -r
#     echo ""
#     if [[ ! $REPLY =~ ^[Yy]$ ]]; then
#       [[ "$0" == "$BASH_SOURCE" ]] && exit 1 || return 1
#     fi
#     cargo install grcov
#   else
#     exit 1
#   fi
# fi

# # Check that lcov is installed
# if ! [ -x "$(command -v lcov)" ]; then
#   echo "Error: lcov is not installed." >&2
#   echo "Documentation for lcov can be found at http://ltp.sourceforge.net/coverage/lcov.php"
#   echo "If on macOS and using homebrew, run 'brew install lcov'"
#   exit 1
# fi

# Warn that cargo clean will happen
if [ $SKIP_PROMPTS -eq 0 ]; then
  read -p "Generate coverage report? This will run cargo clean. [yY/*] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    [[ "$0" == "$BASH_SOURCE" ]] && exit 1 || return 1
  fi
fi

echo --- llvm-cov env ---
cargo llvm-cov show-env
echo --- llvm-cov env end ---

# Set the flags necessary for coverage output
# export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Copt-level=0 -Clink-dead-code -Coverflow-checks=off"
# export RUSTC_BOOTSTRAP=1
# export CARGO_INCREMENTAL=0
export RUST_MIN_STACK=8388608 # 8 * 1024 * 1024

echo check ulimits
ulimit -a

# Clean the project
echo "Cleaning project..."
(
  cd "$TEST_DIR"
  cargo clean
)

source <(cargo llvm-cov show-env --export-prefix) # Set the environment variables needed to get coverage.

export CARGO_LLVM_COV_TARGET_DIR=`pwd`/target
echo 'CARGO_LLVM_COV_TARGET_DIR is' $CARGO_LLVM_COV_TARGET_DIR

echo --- new llvm-cov env ---
cargo llvm-cov show-env
echo --- llvm-cov env end ---

# Run tests
echo "Running tests and collecting coverage data ..."
# cargo llvm-cov -v --lib --ignore-run-fail --workspace --test unit_tests::transaction_test::transaction_payload_bcs_roundtrip --no-run --lcov --jobs 5 --output-path "${COVERAGE_DIR}"/lcov.info || true
# cargo llvm-cov -v --lib --ignore-run-fail  --package starcoin-transactional-test-harness  --lcov --jobs 5 --output-path "${COVERAGE_DIR}"/lcov.info || true
# cargo llvm-cov -v --lib --package starcoin-rpc-api --ignore-run-fail --lcov --jobs 8 --output-path "${COVERAGE_DIR}"/lcov.info || true
# cargo llvm-cov -v --package starcoin-storage --lib --ignore-run-fail --lcov --jobs 8 --output-path "${COVERAGE_DIR}"/lcov.info || true

RUST_BACKTRACE=full cargo llvm-cov -v --lib --ignore-run-fail --lcov --jobs 7 --output-path "${COVERAGE_DIR}"/lcov.info -- -Z unstable-options --report-time || true

echo "Done. Please view report at ${COVERAGE_DIR}/lcov.info"
