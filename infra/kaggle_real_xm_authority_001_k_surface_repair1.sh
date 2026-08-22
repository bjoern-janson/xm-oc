#!/usr/bin/env bash
set -Eeuo pipefail

# Infrastructure-only repair wrapper for REAL-XM-AUTHORITY-001 matched K surface.
# The original prospectively frozen surface launcher remains immutable at:
# 5133647aa5beb50e92e7acdea25e71f7f801fef6
#
# Failure repaired: runner/build_cache.py is executed by absolute path, so Python
# sets sys.path[0] to the runner directory and cannot import the frozen checkout's
# `model` package. Expose that already-frozen checkout root through PYTHONPATH.
# No scientific code, dataset selection, training argument, observer, region,
# optimizer, RNG seed, K value, or readout is changed.

export PYTHONPATH="/kaggle/working/real_xm_authority_001_k_surface/xm-oc${PYTHONPATH:+:$PYTHONPATH}"

curl -fsSL \
  https://raw.githubusercontent.com/bjoern-janson/xm-oc/5133647aa5beb50e92e7acdea25e71f7f801fef6/infra/kaggle_real_xm_authority_001_k_surface.sh \
  | bash
