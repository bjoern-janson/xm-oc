#!/usr/bin/env bash
set -Eeuo pipefail

# REAL-XM-AUTHORITY-001 fresh-seed replication, checkpoint-free recovery.
FROZEN_SHA="be7cefd60cf199e9fbabd6110be1254a1756590e"
EXECUTION_BUNDLE_SHA="30cacad1aa73b5b860f5057b5e1bb8b75b4b000f"
REPO_URL="https://github.com/bjoern-janson/xm-oc.git"
HF_DATASET="ILSVRC/imagenet-1k"
HF_DATASET_REV="49e2ee26f3810fb5a7536bbf732a7b07389a47b5"
SEEDS=(101 202 303 404 505)
K_VALUES=(2 8 12)
BATCH_SIZE=8
MAX_STEPS=2049
WARMUP_STEPS=20

ROOT="/kaggle/working/real_xm_authority_001_high_k_replication"
REPO_DIR="$ROOT/xm-oc"
RUNNER_DIR="$ROOT/runner"
CACHE_DIR="$ROOT/cached_latents/imagenet"
OUT_DIR="$ROOT/output"

rm -rf "$ROOT"
mkdir -p "$RUNNER_DIR" "$CACHE_DIR" "$OUT_DIR"

echo "=== REAL-XM-AUTHORITY-001 HIGH-K COUPLING REPLICATION V2 ==="
echo "Frozen scientific/apparatus commit: $FROZEN_SHA"
echo "Execution bundle commit: $EXECUTION_BUNDLE_SHA"
echo "Dataset: $HF_DATASET @ $HF_DATASET_REV"
echo "Fresh training seeds: ${SEEDS[*]}"
echo "K regimes: ${K_VALUES[*]}"
echo "Matched protocol: train_n=4096 val_n=256 batch=$BATCH_SIZE max_steps=$MAX_STEPS"
echo "CHECKPOINT POLICY: writes disabled; Q_gen out of scope."
echo "PRIMARY: seed-block Delta=Z_late(K12)-Z_late(K2), Fisher-z average at 1536 and 2048."
echo "CLAIM CEILING: association replication only; no causal direction; no Q_gen claim."

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

git clone -q "$REPO_URL" "$REPO_DIR"
git -C "$REPO_DIR" checkout -q --detach "$FROZEN_SHA"
ACTUAL_SHA="$(git -C "$REPO_DIR" rev-parse HEAD)"
[[ "$ACTUAL_SHA" == "$FROZEN_SHA" ]] || { echo "FATAL: frozen SHA mismatch" >&2; exit 91; }
git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet || { echo "FATAL: frozen checkout dirty" >&2; exit 92; }
printf '%s\n' "$ACTUAL_SHA" | tee "$OUT_DIR/frozen-sha.txt"

cd "$REPO_DIR"
python -m pip install -q --no-cache-dir -r requirements.txt
export USE_TORCH=1 USE_TF=0 TRANSFORMERS_NO_TF=1
export HF_HOME="$ROOT/hf_cache" HF_HUB_DISABLE_TELEMETRY=1
export PYTHONPATH="$REPO_DIR${PYTHONPATH:+:$PYTHONPATH}"
mkdir -p "$HF_HOME"

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
[[ -n "${HF_TOKEN:-}" ]] || { echo "FATAL: HF_TOKEN missing" >&2; exit 93; }

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
info = HfApi().dataset_info("$HF_DATASET", revision="$HF_DATASET_REV", token=os.environ["HF_TOKEN"])
print("hf_dataset_requested_revision", "$HF_DATASET_REV")
print("hf_dataset_resolved_sha", info.sha)
assert info.sha == "$HF_DATASET_REV"
print("HF_IMAGENET_ACCESS_AND_REVISION_PASS")
PY
python -m pip freeze > "$OUT_DIR/pip-freeze.txt"

BASE_RAW="https://raw.githubusercontent.com/bjoern-janson/xm-oc/$EXECUTION_BUNDLE_SHA/infra"
curl -fsSL "$BASE_RAW/build_real_xm_authority_001_matched_cache.py" -o "$RUNNER_DIR/build_cache.py"
curl -fsSL "$BASE_RAW/run_real_xm_authority_001_seeded.py" -o "$RUNNER_DIR/run_seeded.py"
curl -fsSL "$BASE_RAW/summarize_real_xm_authority_001_high_k_replication.py" -o "$RUNNER_DIR/summarize_replication.py"
curl -fsSL "$BASE_RAW/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md" -o "$RUNNER_DIR/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md"
sha256sum "$RUNNER_DIR"/* | tee "$OUT_DIR/execution-bundle-files.sha256"

python "$RUNNER_DIR/build_cache.py" --cache-dir "$CACHE_DIR" --manifest "$OUT_DIR/replication-data-manifest.json" --frozen-sha "$FROZEN_SHA" 2>&1 | tee "$OUT_DIR/cache-build.log"

python - <<PY | tee "$OUT_DIR/cache-reader-audit.txt"
from utils.cache_latents import CachedLatentsDataset
train = CachedLatentsDataset("$CACHE_DIR/imagenet_train_256x256_vae.safetensors")
val = CachedLatentsDataset("$CACHE_DIR/imagenet_val_256x256_vae.safetensors")
assert len(train) == 4096 and len(val) == 256
assert tuple(train[0]["latent"].shape) == (4,32,32)
assert tuple(val[0]["latent"].shape) == (4,32,32)
print("FROZEN_CACHE_READER_AUDIT_PASS")
PY

export XM_AUTHORITY_OBS=1
export XM_AUTHORITY_REGION_BITS=4
export XM_AUTHORITY_REGION_SEED=314159
export XM_AUTHORITY_HOLDOUT_SEED=271828
export XM_AUTHORITY_HOLDOUT_EXAMPLES=8
export XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS=1
export WANDB_MODE=offline WANDB_SILENT=true

for SEED in "${SEEDS[@]}"; do
  echo "=== START SEED BLOCK $SEED ==="
  for K in "${K_VALUES[@]}"; do
    MEMBER="$ROOT/seed${SEED}/k${K}"
    OBS_DIR="$MEMBER/observer"
    mkdir -p "$OBS_DIR"
    export XM_AUTHORITY_OBS_DIR="$OBS_DIR"

    echo "=== START seed=$SEED K=$K ==="
    git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet || { echo "FATAL: frozen checkout dirty before member" >&2; exit 100; }

    set +e
    python "$RUNNER_DIR/run_seeded.py" \
      --replication-seed "$SEED" --is_random_seed \
      --model_name dit --model_size vit_base \
      --run_prefix "real-xm-auth001-repl-s${SEED}-k${K}" \
      --run_name_hparams "img=image_dims,ps=patch_size,enc=backbone_type,xm_k=xm_best_of_k,prec=fp16m" \
      --modality IMG --xm_best_of_k "$K" --xm_chunk_bs_mult 1 --xm_save_mem_mode \
      --diffusion_supervision_type velocity --ode_step_size 0.02 --patch_size 2 \
      --image_task class_conditional --num_classes 1000 --cfg_dropout_prob 0.1 \
      --log_image_every_n_steps 10000 --check_val_every_n_epoch 1 --ema_model 0.9999 \
      --gpus 1 --peak_learning_rate 0.0001 --batch_size_per_device "$BATCH_SIZE" --effective_batch_size "$BATCH_SIZE" \
      --gradient_clip_val 1.0 --weight_decay 0.01 --min_lr_scale 10 \
      --max_steps "$MAX_STEPS" --max_scheduling_steps "$MAX_STEPS" --warm_up_steps "$WARMUP_STEPS" \
      --backbone_type vae --use_cached_img_latents --cached_img_latents_dir "$CACHE_DIR" \
      --dataset_name imagenet --num_workers_per_device 2 --image_dims 256 256 \
      --log_gradients --log_every_n_steps 50 --set_matmul_precision medium --float_precision 16-mixed \
      --save_top_k_ckpts 0 --checkpoint_base_dir "$MEMBER/checkpoints-disabled" \
      --wandb_project real-xm-authority-001-high-k-replication --wandb_offline \
      2>&1 | tee "$MEMBER/train.log"
    TRAIN_RC=${PIPESTATUS[0]}
    set -e
    printf '%s\n' "$TRAIN_RC" > "$MEMBER/train-exit-code.txt"
    [[ "$TRAIN_RC" -eq 0 ]] || { echo "FATAL: seed=$SEED K=$K training failed rc=$TRAIN_RC" >&2; exit "$TRAIN_RC"; }

    git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet || { echo "FATAL: frozen checkout changed during member" >&2; exit 101; }
    grep -Fq "REPLICATION_SEED_INJECTION $SEED" "$MEMBER/train.log" || exit 102
    grep -Fq "Seed set to $SEED" "$MEMBER/train.log" || exit 103
    grep -Fq "REPLICATION_CHECKPOINT_WRITES_DISABLED" "$MEMBER/train.log" || exit 104
    if find "$MEMBER" -name '*.ckpt' -type f -print -quit | grep -q .; then
      echo "FATAL: checkpoint file unexpectedly produced seed=$SEED K=$K" >&2
      exit 105
    fi

    python - <<PY | tee "$MEMBER/member-audit.txt"
import json
from pathlib import Path
seed=int($SEED); K=int($K)
obs=Path("$OBS_DIR")/"authority_rank0.jsonl"
records=[json.loads(x) for x in obs.read_text().splitlines() if x.strip()]
parts=[r for r in records if r.get("kind")=="partition"]
train=[r for r in records if r.get("kind")=="train_authority"]
q=[r for r in records if r.get("kind")=="q_hold"]
assert len(parts)==1
assert parts[0]["coord_indices"]==[808,1575,2250,2349]
assert int(parts[0]["region_seed"])==314159
assert len(train)==2049 and sorted(int(r["step"]) for r in train)==list(range(2049))
assert len(q)==4 and [int(r["step"]) for r in q]==[512,1024,1536,2048]
assert all(int(r["k"])==K and int(r["batch_size"])==8 and bool(r.get("replay_checked",False)) for r in train)
assert sum(sum(r["candidate_slot_counts"]) for r in train)==2049*8*K
assert sum(sum(r["winner_counts"]) for r in train)==2049*8
print("REPLICATION_MEMBER_AUDIT_PASS",seed,K)
PY

    sha256sum "$OBS_DIR/authority_rank0.jsonl" "$MEMBER/train.log" "$MEMBER/member-audit.txt" | tee "$MEMBER/custody.sha256"
    echo "=== seed=$SEED K=$K RECORDED ==="
  done
  echo "=== SEED BLOCK $SEED RECORDED ==="
done

python "$RUNNER_DIR/summarize_replication.py" --root "$ROOT" --output "$OUT_DIR/replication-summary.json" --frozen-sha "$FROZEN_SHA" --execution-bundle-sha "$EXECUTION_BUNDLE_SHA" 2>&1 | tee "$OUT_DIR/replication-summary.txt"

find "$ROOT" -path '*/custody.sha256' -type f -print | sort > "$OUT_DIR/member-custody-files.txt"
while IFS= read -r f; do sha256sum "$f"; done < "$OUT_DIR/member-custody-files.txt" > "$OUT_DIR/member-custody-ledgers.sha256"
sha256sum "$OUT_DIR/replication-data-manifest.json" "$OUT_DIR/replication-summary.json" "$OUT_DIR/replication-summary.txt" "$OUT_DIR/environment-audit.txt" "$OUT_DIR/execution-bundle-files.sha256" "$OUT_DIR/member-custody-ledgers.sha256" | tee "$OUT_DIR/replication-custody.sha256"

echo "=== REAL_DATA_HIGH_K_COUPLING_REPLICATION_RECORDED ==="
echo "Artifacts: $ROOT"
echo "Do not modify the frozen instrument or endpoint in response until this replication is recorded/reviewed."
