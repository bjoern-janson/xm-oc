#!/usr/bin/env bash
set -Eeuo pipefail

# XM-CRCB-001 calibration-base launcher.
# Custody only:
# base-manifest validity != repair-language adequacy != calibration result.

APPARATUS_FREEZE_SHA="b8caf8ffcc0a3bbd4fabfbc610b0767293e11aff"
SOURCE_SCIENTIFIC_SHA="be7cefd60cf199e9fbabd6110be1254a1756590e"
CC_PROTOCOL_COMMIT="4d0e87613ef1b894d6ebac2400e358a9fd82e5ae"
CACHE_BUILDER_COMMIT="30cacad1aa73b5b860f5057b5e1bb8b75b4b000f"
CACHE_BUILDER_BLOB="940b2fe3b7a2c7f8a282db77b9fd641589a97e14"
REPO_URL="https://github.com/bjoern-janson/xm-oc.git"
HF_DATASET="ILSVRC/imagenet-1k"
HF_DATASET_REV="49e2ee26f3810fb5a7536bbf732a7b07389a47b5"
TRAIN_LATENT_SHA="624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f"
VAL_LATENT_SHA="f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99"
BATCH_SIZE=8
MAX_STEPS=2049
WARMUP_STEPS=20

SEED="${1:-}"
case "$SEED" in
  606|707) ;;
  *) echo "usage: $0 <606|707>" >&2; exit 2 ;;
esac

SCRIPT_PATH="$(python - "$0" <<'PY'
import os,sys
print(os.path.realpath(sys.argv[1]))
PY
)"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
VERIFIER="$SCRIPT_DIR/verify_xm_crcb_001_calibration_base_manifest.py"
[[ -f "$VERIFIER" ]] || { echo "FATAL: sibling verifier missing: $VERIFIER" >&2; exit 3; }

INFRA_REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$INFRA_REPO_ROOT" ]] || { echo "FATAL: launcher must run from a Git checkout" >&2; exit 4; }
INFRA_COMMIT="$(git -C "$INFRA_REPO_ROOT" rev-parse HEAD)"
git -C "$INFRA_REPO_ROOT" diff --quiet
git -C "$INFRA_REPO_ROOT" diff --cached --quiet

ROOT="/kaggle/working/xm_crcb_001_calibration_base_seed${SEED}"
SCI_REPO="$ROOT/xm-oc"
RUNNER_DIR="$ROOT/runner"
CACHE_DIR="$ROOT/cached_latents/imagenet"
OUT_DIR="$ROOT/output"
CKPT_ROOT="$ROOT/checkpoints"
STAGE="$ROOT/archive_stage"
ARCHIVE="/kaggle/working/xm_crcb_001_calibration_base_seed${SEED}.tar.gz"

rm -rf "$ROOT"
rm -f "$ARCHIVE"
mkdir -p "$RUNNER_DIR" "$CACHE_DIR" "$OUT_DIR" "$CKPT_ROOT" "$STAGE"

echo "=== XM-CRCB-001 CALIBRATION BASE ==="
echo "Seed: $SEED"
echo "Apparatus freeze: $APPARATUS_FREEZE_SHA"
echo "Source scientific SHA: $SOURCE_SCIENTIFIC_SHA"
echo "CC protocol: $CC_PROTOCOL_COMMIT"
echo "K_train: 2"
echo "CLAIM CEILING: base-manifest validity != repair-language adequacy != calibration result"
echo "NO REPAIR LANGUAGE IS EVALUATED BY THIS LAUNCHER."
echo "NO FACTORIZATION / PARITY / SCIENCE ENDPOINT IS MATERIALIZED."

sha256sum "$SCRIPT_PATH" "$VERIFIER" | tee "$OUT_DIR/infra-files.sha256"
printf '%s\n' "$INFRA_COMMIT" | tee "$OUT_DIR/infra-commit.txt"

nvidia-smi | tee "$OUT_DIR/nvidia-smi.txt"
python -V | tee "$OUT_DIR/python-version.txt"
python -m pip install -q --upgrade pip setuptools wheel
python -m pip install -q --no-cache-dir torch==2.4.0 torchvision==0.19.0 --index-url https://download.pytorch.org/whl/cu121

python - <<'PY' | tee "$OUT_DIR/cuda-before-repo.txt"
import torch
print("torch", torch.__version__)
print("torch.version.cuda", torch.version.cuda)
print("cuda_available", torch.cuda.is_available())
assert torch.cuda.is_available()
print("device_name", torch.cuda.get_device_name(0))
print("cuda_kernel_witness", (torch.tensor([1.0], device="cuda") + 1).item())
PY

git clone -q "$REPO_URL" "$SCI_REPO"
git -C "$SCI_REPO" checkout -q --detach "$APPARATUS_FREEZE_SHA"
ACTUAL_SHA="$(git -C "$SCI_REPO" rev-parse HEAD)"
[[ "$ACTUAL_SHA" == "$APPARATUS_FREEZE_SHA" ]] || { echo "FATAL: apparatus freeze mismatch" >&2; exit 90; }
git -C "$SCI_REPO" diff --quiet
git -C "$SCI_REPO" diff --cached --quiet
git -C "$SCI_REPO" merge-base --is-ancestor "$SOURCE_SCIENTIFIC_SHA" "$APPARATUS_FREEZE_SHA"

# The apparatus freeze may add only XM-CRCB experiment files over the frozen organism.
python - <<PY
import subprocess
root="$SCI_REPO"
base="$SOURCE_SCIENTIFIC_SHA"
head="$APPARATUS_FREEZE_SHA"
paths=subprocess.check_output(["git","-C",root,"diff","--name-only",base,head],text=True).splitlines()
bad=[p for p in paths if not (p.startswith("experiments/xm_crcb_001/") or p=="experiments/xm_crcb_001_calibration.py")]
if bad:
    raise SystemExit(f"FATAL: apparatus freeze modified pre-existing organism files: {bad}")
print("CAL_BASE_ORGANISM_DIFF_SCOPE_PASS", len(paths))
PY

cd "$SCI_REPO"
python -m pip install -q --no-cache-dir -r requirements.txt
export USE_TORCH=1 USE_TF=0 TRANSFORMERS_NO_TF=1
export HF_HOME="$ROOT/hf_cache"
export HF_HUB_DISABLE_TELEMETRY=1
export PYTHONPATH="$SCI_REPO${PYTHONPATH:+:$PYTHONPATH}"
export WANDB_MODE=offline WANDB_SILENT=true
export XM_AUTHORITY_OBS=0
unset XM_AUTHORITY_REGION_BITS XM_AUTHORITY_REGION_SEED XM_AUTHORITY_HOLDOUT_SEED \
      XM_AUTHORITY_HOLDOUT_EXAMPLES XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS XM_AUTHORITY_OBS_DIR || true
mkdir -p "$HF_HOME"

echo "CAL_BASE_AUTHORITY_OBSERVER_DISABLED" | tee "$OUT_DIR/observer-audit.txt"

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
[[ -n "${HF_TOKEN:-}" ]] || { echo "FATAL: HF_TOKEN missing" >&2; exit 91; }

python - <<PY | tee "$OUT_DIR/environment-audit.txt"
import os, torch, torchvision, pytorch_lightning, datasets, diffusers, transformers
from huggingface_hub import HfApi
print("torch", torch.__version__)
print("torchvision", torchvision.__version__)
print("pytorch_lightning", pytorch_lightning.__version__)
print("datasets", datasets.__version__)
print("diffusers", diffusers.__version__)
print("transformers", transformers.__version__)
print("cuda", torch.version.cuda)
print("device", torch.cuda.get_device_name(0))
info=HfApi().dataset_info("$HF_DATASET",revision="$HF_DATASET_REV",token=os.environ["HF_TOKEN"])
print("hf_dataset_requested_revision","$HF_DATASET_REV")
print("hf_dataset_resolved_sha",info.sha)
assert info.sha=="$HF_DATASET_REV"
print("HF_IMAGENET_ACCESS_AND_REVISION_PASS")
PY
python -m pip freeze > "$OUT_DIR/pip-freeze.txt"

# Fetch only the already-custody-audited real-ImageNet cache builder.
CACHE_BUILDER="$RUNNER_DIR/build_cache.py"
curl -fsSL "https://raw.githubusercontent.com/bjoern-janson/xm-oc/$CACHE_BUILDER_COMMIT/infra/build_real_xm_authority_001_matched_cache.py" -o "$CACHE_BUILDER"
BUILDER_GIT_BLOB="$(git hash-object "$CACHE_BUILDER")"
[[ "$BUILDER_GIT_BLOB" == "$CACHE_BUILDER_BLOB" ]] || {
  echo "FATAL: cache builder blob mismatch: $BUILDER_GIT_BLOB" >&2; exit 92;
}
sha256sum "$CACHE_BUILDER" | tee "$OUT_DIR/cache-builder.sha256"

python "$CACHE_BUILDER" \
  --cache-dir "$CACHE_DIR" \
  --manifest "$OUT_DIR/data-manifest.json" \
  --frozen-sha "$SOURCE_SCIENTIFIC_SHA" \
  2>&1 | tee "$OUT_DIR/cache-build.log"

TRAIN_PART="$CACHE_DIR/imagenet_train_256x256_vae.safetensors.parts/part_00000.safetensors"
VAL_PART="$CACHE_DIR/imagenet_val_256x256_vae.safetensors.parts/part_00000.safetensors"
[[ -f "$TRAIN_PART" && -f "$VAL_PART" ]]
[[ "$(sha256sum "$TRAIN_PART" | awk '{print $1}')" == "$TRAIN_LATENT_SHA" ]]
[[ "$(sha256sum "$VAL_PART" | awk '{print $1}')" == "$VAL_LATENT_SHA" ]]

# Confirm calibration constants only; do not construct any region-conditioned bank.
python - <<'PY' | tee "$OUT_DIR/calibration-constants-audit.json"
import json
from experiments.xm_crcb_001 import core
core.verify_coords()
x={
  "cal_region_seed":core.CAL_REGION_SEED,
  "cal_flat_dim":core.CAL_FLAT_DIM,
  "cal_coords":list(core.CAL_COORDS),
  "cal_targets":list(core.CAL_TARGETS),
  "cal_base_seeds":list(core.CAL_BASE_SEEDS),
  "cal_repair_seeds":list(core.CAL_REPAIR_SEEDS),
  "cal_eval_seed":core.CAL_EVAL_SEED,
  "construct_semantic_indices":[min(core.CONSTRUCT),max(core.CONSTRUCT)],
  "eval_semantic_indices":[min(core.EVAL),max(core.EVAL)],
  "science_reserved_semantic_indices":[min(core.SCIENCE_RESERVED),max(core.SCIENCE_RESERVED)],
  "repair_rng_materialized":False,
  "eval_rng_materialized":False,
  "factorization_constructed":False,
  "parity_split_constructed":False,
  "science_seed_materialized":False,
}
print(json.dumps(x,sort_keys=True,indent=2))
PY

echo "=== TRAIN CALIBRATION BASE seed=$SEED K=2 ==="
set +e
python - "$SEED" \
  --is_random_seed \
  --model_name dit --model_size vit_base \
  --run_prefix "xm-crcb001-cal-base-s${SEED}-k2" \
  --run_name_hparams "img=image_dims,ps=patch_size,enc=backbone_type,xm_k=xm_best_of_k,prec=fp16m" \
  --modality IMG --xm_best_of_k 2 --xm_chunk_bs_mult 1 --xm_save_mem_mode \
  --diffusion_supervision_type velocity --ode_step_size 0.02 --patch_size 2 \
  --image_task class_conditional --num_classes 1000 --cfg_dropout_prob 0.1 \
  --log_image_every_n_steps 10000 --check_val_every_n_epoch 1 --ema_model 0.9999 \
  --gpus 1 --peak_learning_rate 0.0001 --batch_size_per_device "$BATCH_SIZE" --effective_batch_size "$BATCH_SIZE" \
  --gradient_clip_val 1.0 --weight_decay 0.01 --min_lr_scale 10 \
  --max_steps "$MAX_STEPS" --max_scheduling_steps "$MAX_STEPS" --warm_up_steps "$WARMUP_STEPS" \
  --backbone_type vae --use_cached_img_latents --cached_img_latents_dir "$CACHE_DIR" \
  --dataset_name imagenet --num_workers_per_device 2 --image_dims 256 256 \
  --log_gradients --log_every_n_steps 50 --set_matmul_precision medium --float_precision 16-mixed \
  --save_top_k_ckpts 0 --checkpoint_base_dir "$CKPT_ROOT" \
  --wandb_project xm-crcb-001-calibration-bases --wandb_offline \
  2>&1 <<'PY' | tee "$OUT_DIR/train.log"
from __future__ import annotations
import sys

seed=int(sys.argv[1])
remaining=sys.argv[2:]
if seed not in (606,707):
    raise RuntimeError(seed)

import train_model

parser=train_model.get_parser()
args=parser.parse_args(remaining)
if not bool(args.is_random_seed):
    raise RuntimeError("base seed harness requires --is_random_seed")
if int(args.save_top_k_ckpts)!=0:
    raise RuntimeError("base checkpoint policy requires save_top_k_ckpts=0")

orig_randint=train_model.random.randint
orig_mc=train_model.ModelCheckpoint
calls={"seed":0,"checkpoint":0}

def one_shot_randint(a,b):
    calls["seed"]+=1
    train_model.random.randint=orig_randint
    if calls["seed"]!=1:
        raise RuntimeError("seed injection path called more than once")
    if not a <= seed <= b:
        raise RuntimeError((seed,a,b))
    print(f"CAL_BASE_SEED_INJECTION {seed}",flush=True)
    return seed

def audited_model_checkpoint(*a,**kw):
    calls["checkpoint"]+=1
    if int(kw.get("save_top_k",-999))!=0:
        raise RuntimeError("unexpected save_top_k")
    if kw.get("save_last") is not True:
        raise RuntimeError("native save_last=True contract changed")
    print("CAL_BASE_NATIVE_SAVE_LAST_ASSERTED",flush=True)
    return orig_mc(*a,**kw)

print("CAL_BASE_AUTHORITY_OBSERVER_DISABLED",flush=True)
train_model.random.randint=one_shot_randint
train_model.ModelCheckpoint=audited_model_checkpoint
try:
    train_model.main(args)
finally:
    train_model.random.randint=orig_randint
    train_model.ModelCheckpoint=orig_mc

if calls["seed"]!=1:
    raise RuntimeError(f"expected one seed injection, got {calls['seed']}")
if calls["checkpoint"]!=1:
    raise RuntimeError(f"expected one checkpoint callback, got {calls['checkpoint']}")
PY
TRAIN_RC=${PIPESTATUS[0]}
set -e
printf '%s\n' "$TRAIN_RC" > "$OUT_DIR/train-exit-code.txt"
[[ "$TRAIN_RC" -eq 0 ]] || { echo "FATAL: training failed rc=$TRAIN_RC" >&2; exit "$TRAIN_RC"; }

git -C "$SCI_REPO" diff --quiet
git -C "$SCI_REPO" diff --cached --quiet

mapfile -t CKPTS < <(find "$CKPT_ROOT" -type f -name '*.ckpt' -print | sort)
[[ "${#CKPTS[@]}" -eq 1 ]] || {
  printf 'FATAL: expected exactly one checkpoint, found %s\n' "${#CKPTS[@]}" >&2
  printf '%s\n' "${CKPTS[@]}" >&2
  exit 93
}
CKPT="${CKPTS[0]}"
[[ "$(basename "$CKPT")" == "last.ckpt" ]] || { echo "FATAL: expected native last.ckpt, got $CKPT" >&2; exit 94; }

MANIFEST="$OUT_DIR/base_manifest_seed${SEED}.json"
python "$VERIFIER" build \
  --seed "$SEED" \
  --checkpoint "$CKPT" \
  --train-log "$OUT_DIR/train.log" \
  --data-manifest "$OUT_DIR/data-manifest.json" \
  --val-cache-part "$VAL_PART" \
  --infra-commit "$INFRA_COMMIT" \
  --launcher "$SCRIPT_PATH" \
  --verifier "$VERIFIER" \
  --out "$MANIFEST" \
  | tee "$OUT_DIR/manifest-build.txt"

# Independent second verifier pass over persisted bytes.
python "$VERIFIER" verify \
  --manifest "$MANIFEST" \
  --checkpoint "$CKPT" \
  --train-log "$OUT_DIR/train.log" \
  --data-manifest "$OUT_DIR/data-manifest.json" \
  --val-cache-part "$VAL_PART" \
  | tee "$OUT_DIR/manifest-verify.txt"

echo "CALIBRATION_BASE_MANIFEST_VALID $SEED"

# Preserve the exact checkpoint + manifest + validation cache part needed by the
# frozen calibration runner, plus enough provenance to re-audit the base.
BASE_STAGE="$STAGE/base_seed${SEED}"
mkdir -p "$BASE_STAGE"
cp "$CKPT" "$BASE_STAGE/last.ckpt"
cp "$MANIFEST" "$BASE_STAGE/base_manifest_seed${SEED}.json"
cp "$VAL_PART" "$BASE_STAGE/imagenet_val_256x256_vae.part_00000.safetensors"
cp "$OUT_DIR/data-manifest.json" "$BASE_STAGE/"
cp "$OUT_DIR/train.log" "$BASE_STAGE/"
cp "$OUT_DIR/train-exit-code.txt" "$BASE_STAGE/"
cp "$OUT_DIR/environment-audit.txt" "$BASE_STAGE/"
cp "$OUT_DIR/pip-freeze.txt" "$BASE_STAGE/"
cp "$OUT_DIR/calibration-constants-audit.json" "$BASE_STAGE/"
cp "$OUT_DIR/infra-files.sha256" "$BASE_STAGE/"
cp "$OUT_DIR/infra-commit.txt" "$BASE_STAGE/"
cp "$OUT_DIR/cache-builder.sha256" "$BASE_STAGE/"
cp "$OUT_DIR/manifest-build.txt" "$BASE_STAGE/"
cp "$OUT_DIR/manifest-verify.txt" "$BASE_STAGE/"

(
  cd "$BASE_STAGE"
  sha256sum \
    last.ckpt \
    base_manifest_seed${SEED}.json \
    imagenet_val_256x256_vae.part_00000.safetensors \
    data-manifest.json \
    train.log \
    train-exit-code.txt \
    environment-audit.txt \
    pip-freeze.txt \
    calibration-constants-audit.json \
    infra-files.sha256 \
    infra-commit.txt \
    cache-builder.sha256 \
    manifest-build.txt \
    manifest-verify.txt \
    > base-custody.sha256
)

tar -C "$STAGE" -czf "$ARCHIVE" .
sha256sum "$ARCHIVE" | tee "$OUT_DIR/base-archive.sha256"

echo "CALIBRATION_BASE_RECORDED $SEED"
echo "ARCHIVE $ARCHIVE"
echo "CLAIM CEILING: this is a custody-valid calibration base only."
echo "No repair-language adequacy or calibration result has been produced."
