#!/usr/bin/env bash
set -Eeuo pipefail

# Infrastructure-only CUDA pipeline witness for REAL-XM-AUTHORITY-001.
# This does NOT produce the ImageNet scientific result. It runs the frozen
# observer/model code on the upstream built-in synthetic latent dataset to
# validate CUDA execution and measurement plumbing without modifying PR #9.

FROZEN_SHA="be7cefd60cf199e9fbabd6110be1254a1756590e"
REPO_URL="https://github.com/bjoern-janson/xm-oc.git"
ROOT="/kaggle/working/real_xm_authority_001_smoke"
REPO_DIR="$ROOT/xm-oc"
OUT_DIR="$ROOT/output"
OBS_DIR="$OUT_DIR/observer"
LOG_FILE="$OUT_DIR/train.log"

mkdir -p "$OUT_DIR" "$OBS_DIR"

echo "=== REAL-XM-AUTHORITY-001 Kaggle CUDA smoke ==="
echo "Frozen scientific/apparatus commit: $FROZEN_SHA"
echo "This run is APPARATUS VALIDATION ONLY; dataset=img_synthetic."

echo "=== host GPU ==="
nvidia-smi | tee "$OUT_DIR/nvidia-smi.txt"
python -V | tee "$OUT_DIR/python-version.txt"

# Kaggle's current default CUDA/PyTorch image can be incompatible with P100
# (Pascal). Force the repository-pinned PyTorch/TorchVision pair using cu121,
# which retains sm_60 support.
python -m pip install -q --upgrade pip setuptools wheel
python -m pip install -q --no-cache-dir \
  torch==2.4.0 torchvision==0.19.0 \
  --index-url https://download.pytorch.org/whl/cu121

python - <<'PY' | tee "$OUT_DIR/cuda-before-repo.txt"
import torch
print("torch", torch.__version__)
print("torch.version.cuda", torch.version.cuda)
print("cuda_available", torch.cuda.is_available())
print("device_count", torch.cuda.device_count())
assert torch.cuda.is_available(), "CUDA is not available after installing pinned PyTorch"
print("device_name", torch.cuda.get_device_name(0))
x = torch.tensor([1.0], device="cuda")
print("cuda_kernel_witness", (x + 1).item())
PY

rm -rf "$REPO_DIR"
git clone -q "$REPO_URL" "$REPO_DIR"
git -C "$REPO_DIR" checkout -q --detach "$FROZEN_SHA"
ACTUAL_SHA="$(git -C "$REPO_DIR" rev-parse HEAD)"
if [[ "$ACTUAL_SHA" != "$FROZEN_SHA" ]]; then
  echo "FATAL: checkout mismatch: $ACTUAL_SHA" >&2
  exit 91
fi
if ! git -C "$REPO_DIR" diff --quiet || ! git -C "$REPO_DIR" diff --cached --quiet; then
  echo "FATAL: frozen checkout is dirty before execution" >&2
  exit 92
fi
printf '%s\n' "$ACTUAL_SHA" | tee "$OUT_DIR/frozen-sha.txt"

cd "$REPO_DIR"
python -m pip install -q --no-cache-dir -r requirements.txt

# Kaggle preinstalls TensorFlow. The frozen XM requirements pin protobuf 5.28.1,
# while Kaggle's TensorFlow wheel was generated against protobuf 5.28.3. XM is
# PyTorch-only here, so disable the unused TensorFlow backend instead of changing
# either the frozen repository requirements or the Kaggle TensorFlow/protobuf pair.
export USE_TORCH=1
export USE_TF=0
export TRANSFORMERS_NO_TF=1

python - <<'PY' | tee "$OUT_DIR/environment-audit.txt"
import os
import torch, torchvision, pytorch_lightning
print("torch", torch.__version__)
print("torchvision", torchvision.__version__)
print("pytorch_lightning", pytorch_lightning.__version__)
print("cuda", torch.version.cuda)
print("cuda_available", torch.cuda.is_available())
print("USE_TORCH", os.environ.get("USE_TORCH"))
print("USE_TF", os.environ.get("USE_TF"))
print("TRANSFORMERS_NO_TF", os.environ.get("TRANSFORMERS_NO_TF"))
assert torch.cuda.is_available()
print("device", torch.cuda.get_device_name(0))
y = torch.randn(8, device="cuda")
print("cuda_post_requirements_witness", float(y.square().mean().cpu()))
PY

# Preflight the exact import chain that failed in the first Kaggle attempt.
python - <<'PY' | tee "$OUT_DIR/hf-import-preflight.txt"
from diffusers import AutoencoderKL
from transformers import PreTrainedModel
print("HF_PYTORCH_IMPORT_PREFLIGHT_PASS")
PY

python -m pip freeze > "$OUT_DIR/pip-freeze.txt"

export XM_AUTHORITY_OBS=1
export XM_AUTHORITY_OBS_DIR="$OBS_DIR"
export XM_AUTHORITY_REGION_BITS=4
export XM_AUTHORITY_REGION_SEED=314159
export XM_AUTHORITY_HOLDOUT_SEED=271828
export XM_AUTHORITY_HOLDOUT_EXAMPLES=2
export XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS=1
export HF_HOME="/kaggle/working/hf_cache"
mkdir -p "$HF_HOME"

# P100 has no native BF16 support. This is deliberately 32-true because this
# run is only a CUDA/apparatus witness, not a scientific K-arm result.
# The upstream-supported image architecture (vit_base, 256px, patch=2,
# velocity flow matching) is retained. Built-in cached synthetic latents avoid
# ImageNet materialization for this smoke.
set +e
python train_model.py \
  --model_name "dit" \
  --model_size "vit_base" \
  --run_prefix "kaggle-p100-observer-smoke" \
  --run_name_hparams "img=image_dims,ps=patch_size,xm_k=xm_best_of_k" \
  --modality "IMG" \
  --xm_best_of_k 2 \
  --xm_chunk_bs_mult 1 \
  --xm_save_mem_mode \
  --diffusion_supervision_type "velocity" \
  --ode_step_size 0.02 \
  --patch_size 2 \
  --image_task "class_conditional" \
  --num_classes 1000 \
  --cfg_dropout_prob 0.1 \
  --log_image_every_n_steps 100000 \
  --check_val_every_n_epoch 1 \
  --ema_model 0.9999 \
  --gpus "1" \
  --peak_learning_rate 0.0001 \
  --batch_size_per_device 1 \
  --effective_batch_size 1 \
  --gradient_clip_val 1.0 \
  --weight_decay 0.01 \
  --min_lr_scale 10 \
  --max_steps 2 \
  --max_scheduling_steps 2 \
  --warm_up_steps 1 \
  --backbone_type "vae" \
  --use_cached_img_latents \
  --dataset_name "img_synthetic" \
  --validation_split_pct 0.1 \
  --num_workers_per_device 1 \
  --image_dims 256 256 \
  --log_gradients \
  --log_every_n_steps 1 \
  --set_matmul_precision "medium" \
  --float_precision "32-true" \
  --limit_val_batches 0.0001 \
  --save_top_k_ckpts 0 \
  --checkpoint_base_dir "$OUT_DIR/checkpoints" \
  --debug_mode \
  2>&1 | tee "$LOG_FILE"
TRAIN_RC=${PIPESTATUS[0]}
set -e
printf '%s\n' "$TRAIN_RC" > "$OUT_DIR/train-exit-code.txt"

python - <<'PY' | tee "$OUT_DIR/observer-summary.txt"
import json
from pathlib import Path

root = Path("/kaggle/working/real_xm_authority_001_smoke/output/observer")
files = sorted(root.glob("authority_rank*.jsonl"))
print("observer_files", [str(p) for p in files])
if not files:
    raise SystemExit("NO_OBSERVER_OUTPUT")
records = []
for p in files:
    for line in p.read_text().splitlines():
        if line.strip():
            records.append(json.loads(line))
print("record_count", len(records))
print("kinds", sorted({r.get('kind') for r in records}))
parts = [r for r in records if r.get("kind") == "partition"]
auth = [r for r in records if r.get("kind") == "train_authority"]
qhold = [r for r in records if r.get("kind") == "q_hold"]
print("partition_records", len(parts))
print("train_authority_records", len(auth))
print("q_hold_records", len(qhold))
if parts:
    print("partition", parts[0])
for r in auth:
    print("authority_step", r["step"], "k", r["k"], "slots", sum(r["candidate_slot_counts"]), "sets", sum(r["candidate_set_hits"]), "winners", sum(r["winner_counts"]), "replay_checked", r["replay_checked"])
for r in qhold:
    print("q_hold_step", r["step"], "regions", len(r["loss_by_region"]), "min", min(r["loss_by_region"]), "max", max(r["loss_by_region"]))

assert parts, "partition record missing"
assert auth, "train_authority record missing"
assert all(r["k"] == 2 for r in auth), "unexpected K in smoke"
assert all(r["replay_checked"] for r in auth), "winner replay audit did not pass"
assert all(sum(r["winner_counts"]) == r["batch_size"] for r in auth)
assert qhold, "Q_hold validation record missing"
print("APPARATUS_CUDA_SMOKE_PASS")
PY
SUMMARY_RC=${PIPESTATUS[0]}
printf '%s\n' "$SUMMARY_RC" > "$OUT_DIR/summary-exit-code.txt"

if [[ "$TRAIN_RC" -ne 0 ]]; then
  echo "TRAINING_PIPELINE_FAILED rc=$TRAIN_RC; inspect $LOG_FILE" >&2
  exit "$TRAIN_RC"
fi
if [[ "$SUMMARY_RC" -ne 0 ]]; then
  echo "OBSERVER_SUMMARY_FAILED rc=$SUMMARY_RC" >&2
  exit "$SUMMARY_RC"
fi

echo "=== APPARATUS_CUDA_SMOKE_PASS ==="
echo "Artifacts: $OUT_DIR"
echo "No ImageNet/real-XM scientific claim is earned by this smoke run."
