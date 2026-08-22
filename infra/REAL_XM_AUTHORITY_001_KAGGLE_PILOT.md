# REAL-XM-AUTHORITY-001 — Kaggle real-data pilot freeze

Status at creation: PROSPECTIVE / UNRUN.

This file freezes the first data-bearing pilot for the already-frozen observational apparatus at scientific/apparatus commit:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

The apparatus commit and PR #9 are not modified by this pilot.

## Purpose / claim ceiling

This is one small real-ImageNet K>1 pilot whose purpose is to establish that the frozen latent-region measurements produce non-degenerate, auditable observations under actual image data and nontrivial training.

It is NOT the matched K={1,2,5,8,12} surface, NOT a full-ImageNet reproduction, NOT an XM performance claim, and NOT by itself sufficient to establish robust authority starvation.

No latent region may be redefined, clustered, filtered, merged, split, or selected after inspecting winners or Q_hold.

## Frozen organism and observer

- XM/scientific code SHA: `be7cefd60cf199e9fbabd6110be1254a1756590e`
- model: continuous class-conditional image DiT
- model size: `vit_base`
- image size: 256x256
- patch size: 2
- supervision: velocity / flow matching
- hard XM K: 2
- `xm_chunk_bs_mult`: 1
- save-memory winner replay: enabled
- region bits: 4 (16 regions)
- region seed: 314159
- holdout seed: 271828
- holdout examples per Q_hold measurement: 8
- region definition remains the frozen sign hash implemented in PR #9.

## Data specimen

The frozen repo's native ImageNet path requires the full Hugging Face dataset to be materialized before subsetting. Kaggle storage makes that inappropriate for this pilot. The training code itself is therefore left unchanged and is supplied an already-existing cache in the exact native `CachedLatentsDataset` sharded-safetensors format that the frozen repo supports.

The cache is constructed prospectively from real ImageNet images using:

- dataset: `ILSVRC/imagenet-1k`
- dataset revision: `49e2ee26f3810fb5a7536bbf732a7b07389a47b5`
- train count: 4096
- validation count: 256
- deterministic streaming shuffle buffer: 10000
- train data seed: 424242
- validation data seed: 424243
- encoder: frozen repo's `load_image_encoder('vae', ..., use_ema=True)`, i.e. `stabilityai/sd-vae-ft-ema`
- encoding: frozen repo's `get_encoded_images`, including 0.18215 scaling
- transform: frozen IMG transform at 256px: `center_crop_arr`, `ToTensor`, Normalize(0.5,0.5)

A SHA-256 digest over the selected RGB pixels, image sizes, and labels is recorded for each split before training. Dataset revision, selection seeds, label histogram, and cache hashes are recorded as provenance.

The external cache construction is data preparation only. It does not modify candidate generation, loss, winner selection, replay, optimizer, model architecture, observer, region definition, or training RNG.

## Training protocol

Upstream XDiT settings preserved where feasible:

- peak LR: 1e-4
- weight decay: 0.01
- min LR scale: 10
- gradient clip: 1.0
- CFG dropout: 0.1
- EMA: 0.9999
- ODE step size: 0.02

Kaggle/P100 pilot-scale settings frozen prospectively:

- one Tesla P100
- batch size per device: 8
- effective batch size: 8
- max optimizer steps: 2049
- max scheduling steps: 2049
- warmup steps: 20 (approximately the upstream 1% warmup fraction)
- validation every epoch
- 4096 train examples / batch 8 = 512 optimizer steps per complete epoch
- therefore expected Q_hold checkpoints at global steps 512, 1024, 1536, 2048 before the final step
- precision: `16-mixed` because P100 does not support upstream BF16; this hardware-forced difference must remain explicit
- online FID disabled in this pilot; Q_gen is deferred
- native Lightning `save_last=True` preserves the final checkpoint for later Q_gen without retraining
- W&B offline

## Frozen readout

Primary raw records:

- `C_slot(R)` from candidate slot counts
- `C_set(R)` from per-example candidate-set hits
- `A(R)` from winner counts
- `rho(R) = A(R) / C_slot(R)` where A and C_slot are normalized masses
- `Q_hold(R,t)` at validation checkpoints

The launcher records totals and 512-step temporal windows. Raw JSONL remains authoritative.

No post-hoc region discovery is authorized. No instrument or training-objective change is authorized in response to this pilot until the pilot result is recorded.
