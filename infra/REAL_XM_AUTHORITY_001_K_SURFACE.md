# REAL-XM-AUTHORITY-001 — matched K surface freeze

Current status: **RECORDED / REVIEWED** (2026-08-22).

Recorded result ledger:

`infra/results/REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`

Recorded classification:

`REAL_DATA_MATCHED_K_SURFACE_RECORDED`

Result compression:

> Larger K produced no demonstrated growth of a persistent marginal authority topology under the frozen 16-region partition; observed rho dispersion is compatible with the finite-count exchangeable-winner baseline. A suggestive high-K negative association between rho and Q_hold remains a fresh-seed replication target, not an established mechanism.

The prospective protocol below is preserved as frozen pre-run provenance. Its original status at creation was **PROSPECTIVE / UNRUN**.

---

This file freezes the matched competition-pressure surface following the recorded real-data K=2 pilot. It does not modify the scientific/apparatus commit or PR #9.

Scientific/apparatus SHA:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

Recorded K=2 pilot result ledger:

`infra/results/REAL_XM_AUTHORITY_001_K2_PILOT_RESULT.md`

## Refined scientific question

Does increasing competitive search pressure itself create a latent authority imbalance that is absent at low K?

The primary object is

`rho_t(R;K) = A_t(R;K) / C_slot,t(R;K)`

with the already-frozen region definition and observer.

The matched surface is:

`K in {1, 2, 5, 8, 12}`

No K value may be added, removed, or selected after looking at results.

## Frozen organism and observer

Identical across K except for the declared `xm_best_of_k` value:

- scientific/apparatus SHA: `be7cefd60cf199e9fbabd6110be1254a1756590e`
- model: continuous class-conditional image DiT
- model size: `vit_base`
- image size: 256x256
- patch size: 2
- supervision: velocity / flow matching
- `xm_save_mem_mode`: enabled for K>1 through the native path
- `xm_chunk_bs_mult`: 1 for every K
- region bits: 4 (16 regions)
- region seed: 314159
- holdout seed: 271828
- holdout examples per region: 8
- no OT-CFM
- no change to candidate distribution, hard-min winner rule, replay, gradient allocation, optimizer, architecture, CFG sharing, or observer

`xm_chunk_bs_mult=1` is held fixed because in save-memory mode it only controls candidate chunking. The native helper still evaluates exactly K candidate draws and carries the global minimum across chunks before one winner replay.

K=1 remains the native direct training path; its original noise draw location is not routed through the K>1 helper.

## Matched real-data specimen

The surface must use exactly the same prospectively selected real ImageNet specimen as the recorded K=2 pilot:

- dataset: `ILSVRC/imagenet-1k`
- dataset revision: `49e2ee26f3810fb5a7536bbf732a7b07389a47b5`
- train count: 4096
- validation count: 256
- deterministic streaming shuffle buffer: 10000
- train selection seed: 424242
- validation selection seed: 424243
- encoder: frozen repo `load_image_encoder('vae', ..., use_ema=True)` (`stabilityai/sd-vae-ft-ema`)
- encoding: frozen repo `get_encoded_images`, including 0.18215 scaling
- transform: `center_crop_arr(256) -> ToTensor -> Normalize(0.5,0.5)`

Before training, the launcher must reproduce and assert the recorded pilot data/cache custody:

Train:
- RGB+label SHA-256: `4c66cdf359d428ba6e037ce8e9d8ae7814d02b4e1c9eb636df86f0c13ec0d3c3`
- latent cache SHA-256: `624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f`

Validation:
- RGB+label SHA-256: `ddb96596358e97db3d5c31579a8376616a3bca481a31f12d92cd97204b042fb7`
- latent cache SHA-256: `f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99`

If any hash differs, the surface fails closed before training.

## Matched training protocol

Identical across K:

- global seed: native repo default 33
- one Tesla P100
- batch size per device: 8
- effective batch size: 8
- optimizer steps: 2049
- max scheduling steps: 2049
- warmup steps: 20
- peak LR: 1e-4
- weight decay: 0.01
- min LR scale: 10
- gradient clip: 1.0
- CFG dropout: 0.1
- EMA: 0.9999
- ODE step size: 0.02
- precision: `16-mixed` (explicit P100 hardware difference from upstream BF16)
- validation every epoch
- 512 optimizer steps per complete epoch
- expected Q_hold checkpoints: global steps 512, 1024, 1536, 2048
- online FID disabled
- W&B offline
- native `save_last=True`; final checkpoint preserved for later Q_gen

Each K is started as a fresh Python process so native seed initialization is reset to 33 for every member of the surface.

## Frozen readout

For every K, retain raw JSONL and compute only the declared descriptive quantities:

- `C_slot(R;K)`
- `C_set(R;K)`
- `A(R;K)`
- `rho(R;K) = A(R;K)/C_slot(R;K)`
- `Q_hold(R,t;K)` at steps 512, 1024, 1536, 2048
- 512-step windows of `C_slot`, `C_set`, `A`, and `rho`, yielding `rho_t(R;K)`

Surface-level descriptive summaries may include:

- min/max/range of cumulative rho for each K
- max absolute deviation `max_R |rho(R;K)-1|`
- standard deviation of rho across regions for each K
- the per-region rho vectors and 512-step temporal windows
- the frozen rho-vs-Q_hold correlations at each checkpoint
- comparison of observed C_set with the iid prior-symmetric expectation `1-(15/16)^K`

These are descriptive readouts, not post-hoc thresholds.

## Decision framing

The surface is intended to discriminate among these broad outcomes:

1. `rho_K(R) ~= 1` across the surface: no material direct authority topology is revealed by this frozen partition in this regime.
2. `rho_K(R)` departs increasingly/persistently from parity as K increases: competitive pressure creates a direct authority topology under this frozen partition.
3. authority imbalance appears but Q_hold does not worsen correspondingly: allocation topology exists without detected competence debt over this horizon.
4. transient rho imbalance appears and later returns toward parity: early specialization is distinguished from persistent starvation.

No result from this surface authorizes redefining latent regions around observed winners, hard/easy cells, or post-hoc clusters.

## Claim ceiling

This surface remains a small real-ImageNet-subset, single-training-seed, P100/FP16 regime. It does not by itself establish a universal property of XM, full-ImageNet behavior, robustness across seeds, an identified causal mechanism for Q_hold differences, or any Q_gen/performance claim.

Q_gen is deferred until the frozen allocation/holdout surface is recorded.
