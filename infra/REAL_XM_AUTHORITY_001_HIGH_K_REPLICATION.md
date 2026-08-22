# REAL-XM-AUTHORITY-001 — high-K authority/competence coupling replication

Status at creation: **PROSPECTIVE / UNRUN**.

This protocol follows the recorded matched K surface in:

`infra/results/REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`

It does not modify the frozen scientific/apparatus commit, observer, region definition, training objective, or PR #9.

Scientific/apparatus SHA:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

## Discovery being replicated

The single-seed matched surface did **not** demonstrate gross or monotonically increasing marginal authority imbalance under the frozen 16-region partition. Its cumulative rho dispersion was compatible with the exchangeable-winner finite-count baseline.

The surface nevertheless showed a suggestive high-K association between lower regional winner-authority efficiency and worse conditional held-out loss, especially at K=12 late in training.

This replication freezes that observation as **authority/competence coupling**, not as a directional mechanism.

The following causal structures remain open regardless of replication outcome:

- competence -> winner allocation;
- winner allocation -> competence;
- stable latent-region difficulty -> both winner allocation and competence.

Replication can establish reproducibility of an association. It does **not** identify causal direction.

## Replication unit

The independent replication unit is the **training seed block**.

The 16 latent regions are repeated measurements within one trained system; they are not treated as 16 independent experiments.

Five fresh training seeds are prospectively fixed:

`S = {101, 202, 303, 404, 505}`

The discovery seed 33 is excluded from the confirmatory replication set.

No seed may be added, removed, replaced, or selectively omitted after results are opened. A runtime failure may be rerun only with the same seed/K/protocol and must be recorded as infrastructure recovery rather than replaced by another seed.

Within each seed block, the same seed is used for all K values so K contrasts are matched by training seed.

## K regimes

The replication surface is exactly:

`K = {2, 8, 12}`

- K=2 is the low-pressure anchor.
- K=8 is a preregistered intermediate regime.
- K=12 is the high-pressure replication target.

Strict monotonicity across 2 -> 8 -> 12 is **not** a confirmatory requirement.

## Frozen organism, observer, data, and training protocol

Everything below is held identical to the recorded matched K surface except the declared training seed and K value:

- model: continuous class-conditional image DiT;
- model size: `vit_base`;
- image size: 256x256;
- patch size: 2;
- supervision: velocity / flow matching;
- `xm_save_mem_mode`: enabled for K>1 through the native path;
- `xm_chunk_bs_mult`: 1 for every K;
- region bits: 4 (16 regions);
- region seed: 314159;
- realized region coordinates: `[808, 1575, 2250, 2349]`;
- holdout seed: 271828;
- holdout examples per region: 8;
- no OT-CFM;
- no change to candidate distribution, hard-min winner rule, replay, gradient allocation, optimizer, architecture, CFG sharing, or observer.

Matched real-data specimen:

- dataset: `ILSVRC/imagenet-1k`;
- dataset revision: `49e2ee26f3810fb5a7536bbf732a7b07389a47b5`;
- train count: 4096;
- validation count: 256;
- deterministic streaming shuffle buffer: 10000;
- train selection seed: 424242;
- validation selection seed: 424243;
- encoder: frozen repo `load_image_encoder('vae', ..., use_ema=True)`;
- encoding: frozen repo `get_encoded_images`, including 0.18215 scaling;
- transform: `center_crop_arr(256) -> ToTensor -> Normalize(0.5,0.5)`.

The cache must reproduce the already-recorded custody hashes before any training begins:

- train RGB+label SHA-256: `4c66cdf359d428ba6e037ce8e9d8ae7814d02b4e1c9eb636df86f0c13ec0d3c3`;
- train latent SHA-256: `624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f`;
- validation RGB+label SHA-256: `ddb96596358e97db3d5c31579a8376616a3bca481a31f12d92cd97204b042fb7`;
- validation latent SHA-256: `f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99`.

Matched training protocol:

- one Tesla P100;
- batch size per device: 8;
- effective batch size: 8;
- optimizer steps: 2049;
- max scheduling steps: 2049;
- warmup steps: 20;
- peak LR: 1e-4;
- weight decay: 0.01;
- min LR scale: 10;
- gradient clip: 1.0;
- CFG dropout: 0.1;
- EMA: 0.9999;
- ODE step size: 0.02;
- precision: `16-mixed` on P100;
- validation every epoch;
- 512 optimizer steps per complete epoch;
- Q_hold checkpoints: 512, 1024, 1536, 2048;
- online FID disabled;
- W&B offline;
- `save_last=True`; checkpoint retained for later Q_gen if separately authorized.

### Seed injection boundary

The frozen trainer exposes default seed 33 and an existing `--is_random_seed` path that calls `random.randint(0,1000000)` before `seed_everything(...)`; it does not expose an explicit numeric seed argument.

The replication execution harness therefore supplies each preregistered numeric seed through that **existing random-seed path** using a one-shot runtime substitution of the first `random.randint` result. The substitution restores the original `random.randint` immediately on that call, before training initialization proceeds. The frozen `train_model.py` file is not edited.

Every member must print and audit both:

- `REPLICATION_SEED_INJECTION <seed>` from the external harness;
- `Seed set to <seed>` from the frozen trainer/Lightning path.

This is an execution-control mechanism for the declared independent variable (training seed), not a change to model or XM semantics.

## Primary endpoint

For each K, seed s, and Q_hold checkpoint t, define cumulative regional authority efficiency using only training records strictly before t:

`rho_{K,s,t}(R) = A_{K,s,<t}(R) / C_slot,K,s,<t(R)`.

Then define the within-trained-system region correlation:

`r_{K,s,t} = corr_R(rho_{K,s,t}(R), Q_hold,K,s,t(R))`.

The primary conceptual object is **late training**, not the most extreme discovery checkpoint.

Freeze:

`Z_late(K,s) = [atanh(r_{K,s,1536}) + atanh(r_{K,s,2048})] / 2`.

The discovery peak at K=12, step 1536 is not singled out as the replication target.

## Primary confirmatory contrast

For each independent seed block:

`Delta_s^(12-2) = Z_late(12,s) - Z_late(2,s)`.

The primary directional hypothesis is:

`mean_s Delta_s^(12-2) < 0`.

Preregistered robustness summaries:

- `median_s Delta_s^(12-2)`;
- count of seeds with `Delta_s^(12-2) < 0`;
- mean and median `Z_late(12,s)` and `Z_late(2,s)` separately.

No region-level p-value may be used as if the 16 regions were independent replication units.

K=8 is retained as the preregistered intermediate regime. Its `Z_late(8,s)` values and paired contrasts may be reported descriptively, but strict monotonicity is not required for the primary hypothesis.

## Marginal-authority topology remains a co-primary boundary

For every K and fresh seed, retain the final cumulative 2049-step regional rho vector and report:

- `sd_R(rho_K,s)`;
- `min_R rho_K,s`;
- `max_R rho_K,s`;
- `max_R |rho_K,s - 1|`.

Compare these with the already-defined region-neutral exchangeable-winner finite-count null. The null model and calibration are diagnostics of marginal allocation dispersion, not evidence about causal direction.

A fixed post-run calibration is prospectively specified here for reproducibility:

- 200,000 exchangeable-null surfaces per K;
- null RNG seed: 20260823;
- N = 2049 * 8 examples per trained model;
- p = 1/16 per region;
- `W_R ~ Multinomial(N,p)`;
- `U_R ~ Multinomial(N*(K-1),p)` independently;
- `rho_R = K W_R/(W_R+U_R)`.

Report tail probabilities for observed cross-region rho SD and max absolute rho deviation. These diagnostics do not convert the replication into a test of a new topology threshold.

## Secondary stable-region diagnostic

A stable region property could generate both lower rho and higher Q_hold across seeds without developmental feedback.

This diagnostic is secondary and must not alter the primary endpoint.

For each K and seed define:

- `rho_late(R) = [rho_1536(R) + rho_2048(R)]/2`;
- `Q_late(R) = [Q_hold,1536(R) + Q_hold,2048(R)]/2`.

Within each trained system identify, with deterministic region-index tie breaking:

- the four regions with lowest `rho_late`;
- the four regions with highest `Q_late`;
- their intersection.

Across fresh seeds report per-region frequencies of low-rho membership, high-Q membership, and joint membership.

Also report pairwise cross-seed Spearman correlations of the 16-region `rho_late` vectors and separately of the `Q_late` vectors.

Interpretation boundary:

- stable region identities across seeds are consistent with a persistent region property/common cause;
- moving region identities with reproducible within-run negative coupling are more consistent with a dynamic relation;
- neither pattern identifies causal direction.

## Decision / interpretation ceiling

The replication may establish only whether the high-K **authority/competence association** is reproducible across independent trained systems and differs directionally from the low-K anchor.

It does not establish:

- competence -> authority;
- authority -> competence;
- a causal feedback loop;
- that latent difficulty is or is not the common cause;
- that continuous XM has or lacks authority topology under another partition or regime;
- any Q_gen/performance result;
- any universal property of Explorative Modeling.

The target hypothesis is:

> At high K, marginal winner authority remains near the region-neutral finite-count baseline while small regional authority deviations become reproducibly associated with conditional competence relative to K=2.

No mechanism change, region redefinition, clustering, seed replacement, checkpoint selection, or post-hoc endpoint change is authorized in response to the replication outcome.
