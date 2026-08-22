#!/usr/bin/env bash
set -Eeuo pipefail

# REAL-XM-AUTHORITY-001 first real-data pilot.
# This launcher does NOT modify the frozen scientific/apparatus commit or PR #9.
# Protocol: infra/REAL_XM_AUTHORITY_001_KAGGLE_PILOT.md

FROZEN_SHA="be7cefd60cf199e9fbabd6110be1254a1756590e"
REPO_URL="https://github.com/bjoern-janson/xm-oc.git"
HF_DATASET="ILSVRC/imagenet-1k"
HF_DATASET_REV="49e2ee26f3810fb5a7536bbf732a7b07389a47b5"
TRAIN_N=4096
VAL_N=256
DATA_SEED_TRAIN=424242
DATA_SEED_VAL=424243
SHUFFLE_BUFFER=10000
K=2
BATCH_SIZE=8
MAX_STEPS=2049
WARMUP_STEPS=20

ROOT="/kaggle/working/real_xm_authority_001_pilot"
REPO_DIR="$ROOT/xm-oc"
OUT_DIR="$ROOT/output"
OBS_DIR="$OUT_DIR/observer"
CACHE_DIR="$ROOT/cached_latents/imagenet"
LOG_FILE="$OUT_DIR/train.log"

# Clean custody: every invocation is a standalone run.
rm -rf "$ROOT"
mkdir -p "$OUT_DIR" "$OBS_DIR" "$CACHE_DIR"

echo "=== REAL-XM-AUTHORITY-001 REAL-DATA PILOT ==="
echo "Frozen scientific/apparatus commit: $FROZEN_SHA"
echo "Dataset: $HF_DATASET @ $HF_DATASET_REV"
echo "Pilot: K=$K train_n=$TRAIN_N val_n=$VAL_N batch=$BATCH_SIZE max_steps=$MAX_STEPS"
echo "CLAIM CEILING: one real-data descriptive K=2 pilot; NOT the matched K surface."

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

# Reproduce the frozen organism exactly.
git clone -q "$REPO_URL" "$REPO_DIR"
git -C "$REPO_DIR" checkout -q --detach "$FROZEN_SHA"
ACTUAL_SHA="$(git -C "$REPO_DIR" rev-parse HEAD)"
[[ "$ACTUAL_SHA" == "$FROZEN_SHA" ]] || { echo "FATAL: frozen SHA mismatch: $ACTUAL_SHA" >&2; exit 91; }
git -C "$REPO_DIR" diff --quiet && git -C "$REPO_DIR" diff --cached --quiet || { echo "FATAL: frozen checkout dirty" >&2; exit 92; }
printf '%s\n' "$ACTUAL_SHA" | tee "$OUT_DIR/frozen-sha.txt"

cd "$REPO_DIR"
python -m pip install -q --no-cache-dir -r requirements.txt

# Kaggle preinstalls TensorFlow; XM is PyTorch-only. Keep TF out of the import graph.
export USE_TORCH=1
export USE_TF=0
export TRANSFORMERS_NO_TF=1
export HF_HOME="$ROOT/hf_cache"
export HF_HUB_DISABLE_TELEMETRY=1
mkdir -p "$HF_HOME"

# Retrieve HF_TOKEN from Kaggle Secrets if it is not already an environment variable.
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
  echo "FATAL: HF_TOKEN is missing. Add a Kaggle Secret named HF_TOKEN whose Hugging Face account has accepted ILSVRC/imagenet-1k access terms." >&2
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

# Build a small, prospectively selected real-ImageNet cache in the exact native
# CachedLatentsDataset sharded-safetensors format. This is data preparation only.
python - <<PY | tee "$OUT_DIR/cache-build.log"
import hashlib
import json
import os
from collections import Counter
from itertools import islice
from pathlib import Path

import torch
from datasets import load_dataset
from safetensors.torch import save_file, load_file
from torchvision import transforms

from model.model_utils import center_crop_arr, load_image_encoder, get_encoded_images

ROOT = Path("$ROOT")
CACHE_DIR = Path("$CACHE_DIR")
CACHE_DIR.mkdir(parents=True, exist_ok=True)
DATASET = "$HF_DATASET"
REV = "$HF_DATASET_REV"
BUFFER = int($SHUFFLE_BUFFER)
TOKEN = os.environ["HF_TOKEN"]

transform = transforms.Compose([
    transforms.Lambda(lambda pil_image: center_crop_arr(pil_image, 256)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5], inplace=True),
])

vae = load_image_encoder("vae", "base", device="cuda", use_ema=True)
vae.eval()
for p in vae.parameters():
    p.requires_grad = False


def build(split, count, seed, stem):
    print(f"BUILDING {split}: count={count} seed={seed} buffer={BUFFER}")
    stream = load_dataset(
        DATASET,
        split=split,
        streaming=True,
        revision=REV,
        token=TOKEN,
        trust_remote_code=True,
    )
    stream = stream.shuffle(seed=seed, buffer_size=BUFFER)

    latents = []
    labels = []
    pixel_digest = hashlib.sha256()
    label_hist = Counter()
    batch_images = []
    batch_labels = []
    seen = 0

    def flush():
        nonlocal batch_images, batch_labels
        if not batch_images:
            return
        x = torch.stack([transform(im) for im in batch_images], dim=0).to("cuda")
        with torch.no_grad():
            z = get_encoded_images(x, "vae", vae, sdxl_vae_standardization=True).cpu().contiguous()
        latents.append(z)
        labels.extend(batch_labels)
        batch_images = []
        batch_labels = []

    for sample in islice(iter(stream), count):
        image = sample["image"].convert("RGB")
        label = int(sample["label"])
        w, h = image.size
        pixel_digest.update(label.to_bytes(4, "little", signed=True))
        pixel_digest.update(w.to_bytes(4, "little", signed=False))
        pixel_digest.update(h.to_bytes(4, "little", signed=False))
        pixel_digest.update(image.tobytes())
        label_hist[label] += 1
        batch_images.append(image)
        batch_labels.append(label)
        seen += 1
        if len(batch_images) == 16:
            flush()
        if seen % 256 == 0:
            print(f"{split}: selected+encoded {seen}/{count}")
    flush()
    if seen != count:
        raise RuntimeError(f"{split}: expected {count} samples, got {seen}")

    z = torch.cat(latents, dim=0)
    y = torch.tensor(labels, dtype=torch.long)
    if z.shape[0] != count or y.shape[0] != count:
        raise AssertionError((z.shape, y.shape, count))

    cache_file = CACHE_DIR / f"{stem}.safetensors"
    parts_dir = cache_file.with_suffix(cache_file.suffix + ".parts")
    parts_dir.mkdir(parents=True, exist_ok=True)
    part = parts_dir / "part_00000.safetensors"
    save_file({"latents": z, "labels": y}, str(part))
    (parts_dir / "manifest.json").write_text(json.dumps({
        "parts_dir": parts_dir.name,
        "parts": [{"file": part.name, "size": count}],
    }, sort_keys=True, indent=2))
    cache_file.write_text("sharded")

    part_sha = hashlib.sha256(part.read_bytes()).hexdigest()
    return {
        "split": split,
        "count": count,
        "selection_seed": seed,
        "shuffle_buffer": BUFFER,
        "rgb_label_sha256": pixel_digest.hexdigest(),
        "latent_part_sha256": part_sha,
        "latent_shape": list(z.shape),
        "num_classes_present": len(label_hist),
        "label_histogram": {str(k): int(v) for k, v in sorted(label_hist.items())},
        "cache_file": str(cache_file),
        "part_file": str(part),
    }

train = build("train", int($TRAIN_N), int($DATA_SEED_TRAIN), "imagenet_train_256x256_vae")
val = build("validation", int($VAL_N), int($DATA_SEED_VAL), "imagenet_val_256x256_vae")

manifest = {
    "kind": "REAL-XM-AUTHORITY-001-real-data-pilot-cache",
    "frozen_sha": "$FROZEN_SHA",
    "dataset": DATASET,
    "dataset_revision": REV,
    "selection_method": "HF streaming deterministic shuffle then first N",
    "encoder": "stabilityai/sd-vae-ft-ema via frozen load_image_encoder(use_ema=True)",
    "encoding": "frozen get_encoded_images with 0.18215 scaling",
    "transform": "center_crop_arr(256)->ToTensor->Normalize(0.5,0.5)",
    "train": train,
    "validation": val,
}
manifest_path = Path("$OUT_DIR") / "pilot-data-manifest.json"
manifest_path.write_text(json.dumps(manifest, sort_keys=True, indent=2))
print(json.dumps(manifest, sort_keys=True, indent=2))
print("REAL_IMAGENET_PILOT_CACHE_READY")
PY

# Verify the frozen repo's own cache reader sees exactly the frozen specimen.
python - <<PY | tee "$OUT_DIR/cache-reader-audit.txt"
from utils.cache_latents import CachedLatentsDataset
train = CachedLatentsDataset("$CACHE_DIR/imagenet_train_256x256_vae.safetensors")
val = CachedLatentsDataset("$CACHE_DIR/imagenet_val_256x256_vae.safetensors")
print("train_len", len(train))
print("val_len", len(val))
print("train_latent_shape", tuple(train[0]["latent"].shape))
print("val_latent_shape", tuple(val[0]["latent"].shape))
assert len(train) == int($TRAIN_N)
assert len(val) == int($VAL_N)
assert tuple(train[0]["latent"].shape) == (4, 32, 32)
assert tuple(val[0]["latent"].shape) == (4, 32, 32)
print("FROZEN_CACHE_READER_AUDIT_PASS")
PY

# Frozen observer settings. No result-dependent region changes are permitted.
export XM_AUTHORITY_OBS=1
export XM_AUTHORITY_OBS_DIR="$OBS_DIR"
export XM_AUTHORITY_REGION_BITS=4
export XM_AUTHORITY_REGION_SEED=314159
export XM_AUTHORITY_HOLDOUT_SEED=271828
export XM_AUTHORITY_HOLDOUT_EXAMPLES=8
export XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS=1

# Native W&B logger in offline mode avoids Kaggle TensorBoard/TF import path.
export WANDB_MODE=offline
export WANDB_SILENT=true

# First data-bearing K=2 specimen. Upstream scientific settings are preserved where
# feasible; hardware/scale differences are explicit in the frozen pilot protocol.
set +e
python train_model.py \
  --model_name "dit" \
  --model_size "vit_base" \
  --run_prefix "real-xm-auth001-kaggle-pilot-k2" \
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
  --checkpoint_base_dir "$OUT_DIR/checkpoints" \
  --wandb_project "real-xm-authority-001-pilot" \
  --wandb_offline \
  2>&1 | tee "$LOG_FILE"
TRAIN_RC=${PIPESTATUS[0]}
set -e
printf '%s\n' "$TRAIN_RC" > "$OUT_DIR/train-exit-code.txt"

# Freeze the first real-data observation before any instrument change.
python - <<'PY' | tee "$OUT_DIR/pilot-summary.txt"
import hashlib
import json
import math
from pathlib import Path

root = Path("/kaggle/working/real_xm_authority_001_pilot/output")
obs_dir = root / "observer"
files = sorted(obs_dir.glob("authority_rank*.jsonl"))
print("observer_files", [str(p) for p in files])
if not files:
    raise SystemExit("NO_OBSERVER_OUTPUT")
records = []
for p in files:
    for line in p.read_text().splitlines():
        if line.strip():
            records.append(json.loads(line))
parts = [r for r in records if r.get("kind") == "partition"]
auth = [r for r in records if r.get("kind") == "train_authority"]
qhold = [r for r in records if r.get("kind") == "q_hold"]
print("record_count", len(records))
print("partition_records", len(parts))
print("train_authority_records", len(auth))
print("q_hold_records", len(qhold))
print("q_hold_steps", [r["step"] for r in qhold])

assert len(parts) == 1, f"expected one partition record, got {len(parts)}"
assert len(auth) == 2049, f"expected 2049 train authority records, got {len(auth)}"
assert len(qhold) == 4, f"expected four Q_hold records, got {len(qhold)}"
assert [r["step"] for r in qhold] == [512, 1024, 1536, 2048], [r["step"] for r in qhold]
assert all(r["k"] == 2 for r in auth)
assert all(r["batch_size"] == 8 for r in auth)
assert all(r["replay_checked"] for r in auth)
assert all(sum(r["candidate_slot_counts"]) == 16 for r in auth)
assert all(sum(r["winner_counts"]) == 8 for r in auth)

num_regions = parts[0]["num_regions"]

def aggregate(rows):
    slots = [0] * num_regions
    sets = [0] * num_regions
    wins = [0] * num_regions
    sample_den = 0
    for r in rows:
        sample_den += r["batch_size"]
        for i in range(num_regions):
            slots[i] += r["candidate_slot_counts"][i]
            sets[i] += r["candidate_set_hits"][i]
            wins[i] += r["winner_counts"][i]
    slot_den = sum(slots)
    win_den = sum(wins)
    c_slot = [x / slot_den for x in slots]
    c_set = [x / sample_den for x in sets]
    a = [x / win_den for x in wins]
    rho = [(a[i] / c_slot[i]) if c_slot[i] > 0 else None for i in range(num_regions)]
    return {
        "num_train_records": len(rows),
        "sample_denominator": sample_den,
        "candidate_slot_denominator": slot_den,
        "candidate_slot_counts": slots,
        "candidate_set_hits": sets,
        "winner_counts": wins,
        "C_slot": c_slot,
        "C_set": c_set,
        "A": a,
        "rho": rho,
    }

def pearson(xs, ys):
    n = len(xs)
    mx = sum(xs)/n
    my = sum(ys)/n
    dx = [x-mx for x in xs]
    dy = [y-my for y in ys]
    den = math.sqrt(sum(x*x for x in dx) * sum(y*y for y in dy))
    if den == 0:
        return None
    return sum(x*y for x,y in zip(dx,dy))/den

summary = {
    "classification": "REAL_DATA_K2_PILOT_RECORDED",
    "claim_ceiling": "descriptive one-K real-ImageNet-subset pilot; not matched K-surface and not robust authority-starvation evidence",
    "partition": parts[0],
    "overall": aggregate(auth),
    "windows": [],
    "q_hold": qhold,
    "cumulative_rho_vs_qhold_pearson": [],
}

for start in [0, 512, 1024, 1536, 2048]:
    end = min(start + 512, 2049)
    rows = [r for r in auth if start <= r["step"] < end]
    summary["windows"].append({"start_step": start, "end_step_exclusive": end, **aggregate(rows)})

for q in qhold:
    rows = [r for r in auth if r["step"] < q["step"]]
    agg = aggregate(rows)
    rho = [float(x) for x in agg["rho"]]
    losses = [float(x) for x in q["loss_by_region"]]
    summary["cumulative_rho_vs_qhold_pearson"].append({
        "q_hold_step": q["step"],
        "pearson_rho_vs_loss": pearson(rho, losses),
    })

out = root / "pilot-summary.json"
out.write_text(json.dumps(summary, sort_keys=True, indent=2))
print(json.dumps(summary, sort_keys=True, indent=2))
print("REAL_DATA_K2_PILOT_OBSERVATION_FROZEN")

# Custody hashes for primary records.
for path in [files[0], root / "pilot-data-manifest.json", root / "pilot-summary.json", root / "train.log"]:
    h = hashlib.sha256(path.read_bytes()).hexdigest()
    print("sha256", h, path)
PY
SUMMARY_RC=${PIPESTATUS[0]}
printf '%s\n' "$SUMMARY_RC" > "$OUT_DIR/summary-exit-code.txt"

# Record the native last checkpoint path and hash if training reached it.
LAST_CKPT="$(find "$OUT_DIR/checkpoints" -name 'last.ckpt' -type f | head -n 1 || true)"
if [[ -n "$LAST_CKPT" ]]; then
  printf '%s\n' "$LAST_CKPT" | tee "$OUT_DIR/last-checkpoint-path.txt"
  sha256sum "$LAST_CKPT" | tee "$OUT_DIR/last-checkpoint-sha256.txt"
else
  echo "WARNING: native last.ckpt not found" | tee "$OUT_DIR/last-checkpoint-sha256.txt"
fi

if [[ "$TRAIN_RC" -ne 0 ]]; then
  echo "TRAINING_PIPELINE_FAILED rc=$TRAIN_RC; scientific pilot result is NOT valid. Inspect $LOG_FILE" >&2
  exit "$TRAIN_RC"
fi
if [[ "$SUMMARY_RC" -ne 0 ]]; then
  echo "PILOT_SUMMARY_FAILED rc=$SUMMARY_RC; do not interpret partial records" >&2
  exit "$SUMMARY_RC"
fi

echo "=== REAL_DATA_K2_PILOT_RECORDED ==="
echo "Artifacts: $OUT_DIR"
echo "Do not modify the frozen instrument in response until this result is recorded/reviewed."
