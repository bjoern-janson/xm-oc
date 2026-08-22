# REAL-XM-AUTHORITY-001 — high-K authority/competence coupling replication

Status: **PROSPECTIVE / UNRUN AFTER INFRASTRUCTURE RECOVERY**.

Attempt 1 is preserved in `infra/results/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_ATTEMPT1_INFRA_FAILURE.md`. It failed during the first epoch-end checkpoint write for seed 101 / K=2, before any preregistered late endpoint or seed-block contrast was available. No result from that attempt is replication evidence.

This protocol follows the recorded matched K surface in `infra/results/REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`. It does not modify the frozen observer, region definition, training objective, or PR #9.

Frozen scientific/apparatus SHA: `be7cefd60cf199e9fbabd6110be1254a1756590e`.

## Discovery and claim boundary

The single-seed matched surface did not demonstrate gross or monotonically increasing marginal authority imbalance under the frozen 16-region partition. Its rho dispersion was compatible with the exchangeable-winner finite-count baseline.

It did show a suggestive high-K association between lower regional winner-authority efficiency and worse conditional held-out loss. This replication freezes that observation only as **authority/competence coupling**.

The following remain causally unresolved regardless of replication outcome:

- competence -> winner allocation;
- winner allocation -> competence;
- stable latent-region difficulty -> both.

Replication can establish reproducibility of an association; it cannot identify causal direction.

## Independent replication unit

The independent unit is the **training seed block**. The 16 regions are repeated measurements within one trained model, not independent experiments.

Fresh seeds are fixed prospectively:

`S = {101, 202, 303, 404, 505}`.

Discovery seed 33 is excluded. No seed may be added, removed, replaced, or selectively omitted after results are opened. A runtime failure may only be rerun with the same seed/K/protocol and must be recorded as infrastructure recovery.

The same seed is used across K within a block.

## K regimes

Exactly `K = {2, 8, 12}`:

- K=2: low-pressure anchor;
- K=8: preregistered intermediate regime;
- K=12: high-pressure replication target.

Strict monotonicity is not a confirmatory requirement.

## Frozen organism, data, observer, and training protocol

Everything is identical to the recorded matched K surface except the declared seed and K:

- continuous class-conditional image DiT, `vit_base`, 256x256, patch size 2;
- velocity / flow matching;
- `xm_save_mem_mode` for K>1;
- `xm_chunk_bs_mult=1` for every K;
- 4-bit / 16-region coordinate-sign partition;
- region seed 314159; coordinates `[808,1575,2250,2349]`;
- holdout seed 271828; 8 holdout examples per region;
- no OT-CFM;
- no change to candidate distribution, hard-min winner rule, replay, gradient allocation, optimizer, architecture, CFG sharing, or observer.

Matched ImageNet specimen:

- `ILSVRC/imagenet-1k` at revision `49e2ee26f3810fb5a7536bbf732a7b07389a47b5`;
- train 4096 / validation 256;
- streaming shuffle buffer 10000;
- train selection seed 424242 / validation seed 424243;
- frozen VAE encode path and transform from the prior surface.

Required custody hashes before training:

- train RGB+label: `4c66cdf359d428ba6e037ce8e9d8ae7814d02b4e1c9eb636df86f0c13ec0d3c3`;
- train latent: `624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f`;
- validation RGB+label: `ddb96596358e97db3d5c31579a8376616a3bca481a31f12d92cd97204b042fb7`;
- validation latent: `f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99`.

Training:

- Tesla P100, `16-mixed`;
- batch/effective batch 8/8;
- 2049 optimizer and scheduling steps;
- warmup 20;
- peak LR 1e-4; weight decay 0.01; min LR scale 10; gradient clip 1.0;
- CFG dropout 0.1; EMA 0.9999; ODE step size 0.02;
- validation every 512-step epoch;
- Q_hold at 512, 1024, 1536, 2048;
- online FID disabled; W&B offline.

### Checkpoint-write recovery boundary

Attempt 1 showed that frozen `train_model.py` constructs `ModelCheckpoint(... save_last=True ...)` even with `--save_top_k_ckpts 0`, and the first epoch-end `last.ckpt` exhausted Kaggle working storage before the run could continue.

Checkpoints are **not measurement-bearing artifacts** for this replication: every declared endpoint comes from the frozen observer JSONL, and Q_gen is explicitly out of scope. Therefore the recovered external harness requires `--save_top_k_ckpts 0` and forces only the callback constructor's `save_last` argument to `False`. It retains the native Lightning callback object/hooks but suppresses checkpoint file I/O.

The harness must print `REPLICATION_CHECKPOINT_WRITES_DISABLED`, and the launcher must fail if any `.ckpt` file is produced.

This is an infrastructure/storage recovery. It does not alter model parameters, forward passes, candidate generation, winner selection, replay, optimizer steps, gradients, observer measurements, validation losses, data order, or any preregistered endpoint. The fresh seed set, K set, schedule, and primary contrast remain unchanged.

### Fixed numeric seed boundary

Frozen `train_model.py` exposes default seed 33 and an existing `--is_random_seed` path that obtains a seed from `random.randint(0,1000000)` before calling `seed_everything(...)`; it has no explicit numeric seed argument.

A pinned external harness supplies each preregistered numeric seed through that existing path using a **one-shot** substitution of the first `random.randint` result, restoring the original function immediately on that call before downstream initialization. The frozen trainer file is not edited.

Every member must contain both `REPLICATION_SEED_INJECTION <seed>` and frozen-trainer/Lightning output `Seed set to <seed>`.

## Primary endpoint

For checkpoint `t`, use only train-authority records with `step < t` and define

`rho_{K,s,t}(R) = A_{K,s,<t}(R) / C_slot_{K,s,<t}(R)`.

Then

`r_{K,s,t} = corr_R(rho_{K,s,t}(R), Q_hold_{K,s,t}(R))`.

The primary late-training endpoint is fixed before fresh seeds are opened:

`Z_late(K,s) = [atanh(r_{K,s,1536}) + atanh(r_{K,s,2048})] / 2`.

The discovery peak at K=12, step 1536 is **not** selected as a standalone confirmatory target.

## Primary matched contrast

For each seed block:

`Delta_s^(12-2) = Z_late(12,s) - Z_late(2,s)`.

Primary directional hypothesis:

`mean_s Delta_s^(12-2) < 0`.

Preregistered robustness summaries:

- median `Delta_s^(12-2)`;
- number of seeds with `Delta_s^(12-2) < 0`;
- mean/median `Z_late` separately for K=2,8,12.

No region-level p-value may be treated as replication evidence. K=8 is descriptive/intermediate; strict monotonicity is not required.

## Marginal-topology boundary

For every K and seed, retain the final cumulative 2049-step rho vector and report cross-region SD, min, max, and `max |rho-1|`.

Compare these with the already-defined exchangeable-winner finite-count null. Prospectively fix the reproducible calibration at:

- 200,000 null surfaces per K;
- RNG seed 20260823;
- `N=2049*8`, `p=1/16`;
- `W_R ~ Multinomial(N,p)`;
- `U_R ~ Multinomial(N*(K-1),p)` independently;
- `rho_R = K W_R/(W_R+U_R)`.

Report tail probabilities for rho SD and max absolute deviation. This is a marginal-allocation diagnostic, not a causal test.

## Secondary stable-region diagnostic

To preserve the common-cause alternative, define for each K and seed:

- `rho_late(R) = [rho_1536(R)+rho_2048(R)]/2`;
- `Q_late(R) = [Q_hold_1536(R)+Q_hold_2048(R)]/2`.

With deterministic region-index tie breaking, record the four lowest-rho regions, four highest-Q regions, and their intersection. Across seeds report membership frequencies plus pairwise cross-seed Spearman correlations for the 16-region `rho_late` vectors and separately for `Q_late`.

Stable region identities are consistent with a persistent region property/common cause; moving region identities with reproducible within-run coupling are more suggestive of a dynamic relation. Neither identifies direction.

## Interpretation ceiling

The replication may establish only whether high-K **authority/competence coupling** is reproducible across independent trained systems relative to K=2 while marginal authority remains compatible with its finite-count baseline.

It cannot establish competence -> authority, authority -> competence, a feedback loop, absence/presence of a latent-difficulty common cause, Q_gen/performance effects, or a universal property of XM.

Target hypothesis:

> At high K, marginal winner authority remains near the region-neutral finite-count baseline while small regional authority deviations become reproducibly associated with conditional competence relative to K=2.

No mechanism change, region redefinition, clustering, seed replacement, checkpoint selection, or post-hoc endpoint change is authorized in response to the outcome.
