#!/usr/bin/env bash
set -Eeuo pipefail

# REAL-XM-AUTHORITY-001 matched K surface launcher.
# Scientific code remains detached at FROZEN_SHA. Runner/data helpers are pinned
# independently at EXECUTION_BUNDLE_SHA. See infra/REAL_XM_AUTHORITY_001_K_SURFACE.md.

FROZEN_SHA="be7cefd60cf199e9fbabd6110be1254a1756590e"
EXECUTION_BUNDLE_SHA="77af49e51e04eac730f8e3303551a9645e58210e"
REPO_URL="https://github.com/bjoern-janson/xm-oc.git"
HF_DATASET="ILSVRC/imagenet-1k"
HF_DATASET_REV="49e2ee26f3810fb5a7536bbf732a7b07389a47b5"
K_VALUES=(1 2 5 8 12)
BATCH_SIZE=8
MAX_STEPS=2049
WARMUP_STEPS=20

ROOT="/kaggle/working/real_xm_authority_001_k_surface"
REPO_DIR="$ROOT/xm-oc"
RUNNER_DIR="$ROOT/runner"
CACHE_DIR="$ROOT/cached_latents/imagenet"
OUT_DIR="$ROOT/output"

# Clean custody: every invocation is a standalone surface.
rm -rf "$ROOT"
mkdir -p "$RUNNER_DIR" "$CACHE_DIR" "$OUT_DIR"

echo "=== REAL-XM-AUTHORITY-001 MATCHED K SURFACE ==="
echo "Frozen scientific/apparatus commit: $FROZEN_SHA"
echo "Execution bundle commit: $EXECUTION_BUNDLE_SHA"
echo "Dataset: $HF_DATASET @ $HF_DATASET_REV"
echo "K surface: ${K_VALUES[*]}"
echo "Matched protocol: train_n=4096 val_n=256 batch=$BATCH_SIZE max_steps=$MAX_STEPS"
echo "CLAIM CEILING: single-seed small real-ImageNet-subset matched K surface; descriptive only."

echo "=== host GPU ==="
nvidia-smi | tee "$OUT_DIR/nvidia-smi.txt"
python -V | tee "$OUT_DIR/python-version.txt"

# P100-compatible repository-pinned torch pair.
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
assert torch.cuda.is_available()
print("device_name", torch.cuda.get_device_name(0))
x = torch.tensor([1.0], device="cuda")
print("cuda_kernel_witness", (x + 1).item())
PY

# Reproduce the frozen scientific organism exactly.
git clone -q "$REPO_URL" "$REPO_DIR"
git -C "$REPO_DIR" checkout -q --detach "$FROZEN_SHA"
ACTUAL_SHA="$(git -C "$REPO_DIR" rev-parse HEAD)"
[[ "$ACTUAL_SHA" == "$FROZEN_SHA" ]] || { echo "FATAL: frozen SHA mismatch: $ACTUAL_SHA" >&2; exit 91; }
git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet || { echo "FATAL: frozen checkout dirty" >&2; exit 92; }
printf '%s\n' "$ACTUAL_SHA" | tee "$OUT_DIR/frozen-sha.txt"

cd "$REPO_DIR"
python -m pip install -q --no-cache-dir -r requirements.txt

# Kaggle preinstalls TensorFlow; XM is PyTorch-only. Keep TF out of import graph.
export USE_TORCH=1
export USE_TF=0
export TRANSFORMERS_NO_TF=1
export HF_HOME="$ROOT/hf_cache"
export HF_HUB_DISABLE_TELEMETRY=1
mkdir -p "$HF_HOME"

# Retrieve HF_TOKEN from Kaggle Secrets if not already present.
if [[ -z "${HF_TOKEN:-}" ]]; then
  set +e
  HF_TOKEN="$(python - <<'PY'
try:
    from kaggle_secrets import UserSecretsClient
    print(UserSecretsClient().get_secret("HF_TOKEN"))
except Exception:
    pass
PY
)"
  set -e
  export HF_TOKEN
fi
if [[ -z "${HF_TOKEN:-}" ]]; then
  echo "FATAL: HF_TOKEN missing. Add Kaggle Secret HF_TOKEN with accepted ImageNet access." >&2
  exit 93
fi

# Environment + gated dataset revision preflight.
python - <<PY | tee "$OUT_DIR/environment-audit.txt"
import os
import torch, torchvision, pytorch_lightning, datasets, diffusers, transformers
from huggingface_hub import HfApi
print("torch", torch.__version__)
print("torchvision", torchvision.__version__)
print("pytorch_lightning", pytorch_lightning.__version__)
print("datasets", datasets.__version__)
print("diffusers", diffusers.__version__)
print("transformers", transformers.__version__)
print("cuda", torch.version.cuda)
print("cuda_available", torch.cuda.is_available())
print("device", torch.cuda.get_device_name(0))
assert torch.cuda.is_available()
info = HfApi().dataset_info("$HF_DATASET", revision="$HF_DATASET_REV", token=os.environ["HF_TOKEN"])
print("hf_dataset_requested_revision", "$HF_DATASET_REV")
print("hf_dataset_resolved_sha", info.sha)
assert info.sha == "$HF_DATASET_REV", (info.sha, "$HF_DATASET_REV")
print("HF_IMAGENET_ACCESS_AND_REVISION_PASS")
PY
python -m pip freeze > "$OUT_DIR/pip-freeze.txt"

# Retrieve the prospectively frozen runner helpers and protocol from an immutable commit.
BASE_RAW="https://raw.githubusercontent.com/bjoern-janson/xm-oc/$EXECUTION_BUNDLE_SHA/infra"
curl -fsSL "$BASE_RAW/build_real_xm_authority_001_matched_cache.py" -o "$RUNNER_DIR/build_cache.py"
curl -fsSL "$BASE_RAW/summarize_real_xm_authority_001_k_surface.py" -o "$RUNNER_DIR/summarize_surface.py"
curl -fsSL "$BASE_RAW/REAL_XM_AUTHORITY_001_K_SURFACE.md" -o "$RUNNER_DIR/REAL_XM_AUTHORITY_001_K_SURFACE.md"
sha256sum \
  "$RUNNER_DIR/build_cache.py" \
  "$RUNNER_DIR/summarize_surface.py" \
  "$RUNNER_DIR/REAL_XM_AUTHORITY_001_K_SURFACE.md" \
  | tee "$OUT_DIR/execution-bundle-files.sha256"

# Build the exact K=2 pilot ImageNet specimen once, then require exact custody hashes.
python "$RUNNER_DIR/build_cache.py" \
  --cache-dir "$CACHE_DIR" \
  --manifest "$OUT_DIR/surface-data-manifest.json" \
  --frozen-sha "$FROZEN_SHA" \
  2>&1 | tee "$OUT_DIR/cache-build.log"

# Verify the frozen repo's own cache reader sees the matched specimen.
python - <<PY | tee "$OUT_DIR/cache-reader-audit.txt"
from utils.cache_latents import CachedLatentsDataset
train = CachedLatentsDataset("$CACHE_DIR/imagenet_train_256x256_vae.safetensors")
val = CachedLatentsDataset("$CACHE_DIR/imagenet_val_256x256_vae.safetensors")
print("train_len", len(train))
print("val_len", len(val))
print("train_latent_shape", tuple(train[0]["latent"].shape))
print("val_latent_shape", tuple(val[0]["latent"].shape))
assert len(train) == 4096
assert len(val) == 256
assert tuple(train[0]["latent"].shape) == (4, 32, 32)
assert tuple(val[0]["latent"].shape) == (4, 32, 32)
print("FROZEN_CACHE_READER_AUDIT_PASS")
PY

# Frozen observer settings shared by every member of the K surface.
export XM_AUTHORITY_OBS=1
export XM_AUTHORITY_REGION_BITS=4
export XM_AUTHORITY_REGION_SEED=314159
export XM_AUTHORITY_HOLDOUT_SEED=271828
export XM_AUTHORITY_HOLDOUT_EXAMPLES=8
export XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS=1

# Native W&B logger in offline mode avoids TensorBoard/TensorFlow path.
export WANDB_MODE=offline
export WANDB_SILENT=true

for K in "${K_VALUES[@]}"; do
  K_OUT="$ROOT/k${K}"
  OBS_DIR="$K_OUT/observer"
  mkdir -p "$OBS_DIR" "$K_OUT/checkpoints"
  export XM_AUTHORITY_OBS_DIR="$OBS_DIR"

  echo "=== START K=$K ==="
  echo "scientific_sha $FROZEN_SHA"
  echo "execution_bundle_sha $EXECUTION_BUNDLE_SHA"

  # No tracked scientific file may have changed before a surface member starts.
  git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet || {
    echo "FATAL: scientific checkout dirty before K=$K" >&2
    exit 100
  }

  set +e
  python train_model.py \
    --model_name "dit" \
    --model_size "vit_base" \
    --run_prefix "real-xm-auth001-surface-k${K}" \
    --run_name_hparams "img=image_dims,ps=patch_size,enc=backbone_type,xm_k=xm_best_of_k,prec=fp16m" \
    --modality "IMG" \
    --xm_best_of_k "$K" \
    --xm_chunk_bs_mult 1 \
    --xm_save_mem_mode \
    --diffusion_supervision_type "velocity" \
    --ode_step_size 0.02 \
    --patch_size 2 \
    --image_task "class_conditional" \
    --num_classes 1000 \
    --cfg_dropout_prob 0.1 \
    --log_image_every_n_steps 10000 \
    --check_val_every_n_epoch 1 \
    --ema_model 0.9999 \
    --gpus "1" \
    --peak_learning_rate 0.0001 \
    --batch_size_per_device "$BATCH_SIZE" \
    --effective_batch_size "$BATCH_SIZE" \
    --gradient_clip_val 1.0 \
    --weight_decay 0.01 \
    --min_lr_scale 10 \
    --max_steps "$MAX_STEPS" \
    --max_scheduling_steps "$MAX_STEPS" \
    --warm_up_steps "$WARMUP_STEPS" \
    --backbone_type "vae" \
    --use_cached_img_latents \
    --cached_img_latents_dir "$CACHE_DIR" \
    --dataset_name "imagenet" \
    --num_workers_per_device 2 \
    --image_dims 256 256 \
    --log_gradients \
    --log_every_n_steps 50 \
    --set_matmul_precision "medium" \
    --float_precision "16-mixed" \
    --save_top_k_ckpts 0 \
    --checkpoint_base_dir "$K_OUT/checkpoints" \
    --wandb_project "real-xm-authority-001-k-surface" \
    --wandb_offline \
    2>&1 | tee "$K_OUT/train.log"
  TRAIN_RC=${PIPESTATUS[0]}
  set -e
  printf '%s\n' "$TRAIN_RC" > "$K_OUT/train-exit-code.txt"
  if [[ "$TRAIN_RC" -ne 0 ]]; then
    echo "FATAL: K=$K training failed with exit code $TRAIN_RC" >&2
    exit "$TRAIN_RC"
  fi

  # Scientific code must still be unchanged after training.
  git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet || {
    echo "FATAL: scientific checkout changed during K=$K" >&2
    exit 101
  }

  # Fail closed unless this member has the complete frozen record structure.
  python - <<PY | tee "$K_OUT/member-audit.txt"
import json
from pathlib import Path
K = int($K)
obs = Path("$OBS_DIR") / "authority_rank0.jsonl"
assert obs.exists(), obs
records = [json.loads(x) for x in obs.read_text().splitlines() if x.strip()]
parts = [r for r in records if r.get("kind") == "partition"]
train = [r for r in records if r.get("kind") == "train_authority"]
q = [r for r in records if r.get("kind") == "q_hold"]
print("record_count", len(records))
print("partition_records", len(parts))
print("train_authority_records", len(train))
print("q_hold_records", len(q))
print("q_hold_steps", [r["step"] for r in q])
assert len(parts) == 1
assert parts[0]["coord_indices"] == [808, 1575, 2250, 2349]
assert len(train) == 2049
assert len(q) == 4
assert [int(r["step"]) for r in q] == [512, 1024, 1536, 2048]
assert all(int(r["k"]) == K for r in train)
assert all(int(r["batch_size"]) == 8 for r in train)
assert all(bool(r.get("replay_checked", False)) for r in train)
assert sum(sum(r["candidate_slot_counts"]) for r in train) == 2049 * 8 * K
assert sum(sum(r["winner_counts"]) for r in train) == 2049 * 8
ckpts = sorted(Path("$K_OUT/checkpoints").rglob("last.ckpt"))
print("last_ckpts", [str(p) for p in ckpts])
assert len(ckpts) == 1
print("K_MEMBER_AUDIT_PASS", K)
PY

  CKPT="$(find "$K_OUT/checkpoints" -name last.ckpt -type f -print -quit)"
  sha256sum \
    "$OBS_DIR/authority_rank0.jsonl" \
    "$K_OUT/train.log" \
    "$CKPT" \
    | tee "$K_OUT/custody.sha256"

  echo "=== K=$K RECORDED ==="
done

# Frozen descriptive surface summary. Raw JSONL files remain authoritative.
python "$RUNNER_DIR/summarize_surface.py" \
  --root "$ROOT" \
  --output "$OUT_DIR/surface-summary.json" \
  --frozen-sha "$FROZEN_SHA" \
  --execution-bundle-sha "$EXECUTION_BUNDLE_SHA" \
  2>&1 | tee "$OUT_DIR/surface-summary.txt"

sha256sum \
  "$OUT_DIR/surface-data-manifest.json" \
  "$OUT_DIR/surface-summary.json" \
  "$OUT_DIR/surface-summary.txt" \
  "$OUT_DIR/environment-audit.txt" \
  "$OUT_DIR/execution-bundle-files.sha256" \
  | tee "$OUT_DIR/surface-custody.sha256"

echo "=== REAL_DATA_MATCHED_K_SURFACE_RECORDED ==="
echo "Artifacts: $ROOT"
echo "Do not modify the frozen instrument in response until this surface is recorded/reviewed."
