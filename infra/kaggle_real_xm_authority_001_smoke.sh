#!/usr/bin/env bash
set -Eeuo pipefail

# Infrastructure-only wrapper for REAL-XM-AUTHORITY-001 Kaggle CUDA smoke.
# The frozen scientific/apparatus commit remains unchanged. This wrapper pins
# the previously-audited launcher at commit 235895c5... and changes only the
# smoke scheduling so one validation batch is actually reached before stopping.

BASE_LAUNCHER_COMMIT="235895c5cdd068e244f77b581c6126fb361ae461"
BASE_URL="https://raw.githubusercontent.com/bjoern-janson/xm-oc/${BASE_LAUNCHER_COMMIT}/infra/kaggle_real_xm_authority_001_smoke.sh"
TMP="/tmp/kaggle_real_xm_authority_001_smoke_base.sh"

curl -fsSL "$BASE_URL" -o "$TMP"

# `limit_*_batches` are argparse floats in the frozen trainer. A value of 1
# therefore means 100% of the epoch, not one batch. The synthetic split has
# 90,000 train / 10,000 validation samples at batch size 1, so these fractions
# yield 2 train batches and 1 validation batch per epoch. max_steps=3 lets the
# first 2-batch epoch finish and validation run, then stops on the next train
# step. This is apparatus scheduling only; no model/XM/observer code is changed.
sed -e 's/--max_steps 2 \\/--max_steps 3 \\/' \
    -e 's/--max_scheduling_steps 2 \\/--max_scheduling_steps 3 \\/' \
    -e 's/--limit_train_batches 1 \\/--limit_train_batches 0.0000222223 \\/' \
    -e 's/--limit_val_batches 1 \\/--limit_val_batches 0.0001 \\/' \
    "$TMP" > "${TMP}.scheduled"

exec bash "${TMP}.scheduled"
