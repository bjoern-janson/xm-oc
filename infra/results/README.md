# REAL-XM-AUTHORITY-001 results index

This directory contains **post-run result records and diagnostic analyses** for frozen scientific/apparatus commit:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

These files do not modify the frozen observer, training objective, region definition, or PR #9.

## Recorded results

### 1. Real-data K=2 pilot

`REAL_XM_AUTHORITY_001_K2_PILOT_RESULT.md`

Classification: `REAL_DATA_K2_PILOT_RECORDED`.

Narrow result: under the frozen 16-region partition, K=2 did not show the strong toy-style authority-starvation pattern; `A(R)` tracked `C_slot(R)` closely, while Q_hold heterogeneity existed without a low-rho precursor.

### 2. Matched K surface

`REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`

Classification: `REAL_DATA_MATCHED_K_SURFACE_RECORDED`.

Matched surface: `K in {1,2,5,8,12}`.

Narrow result: increasing K did not demonstrate monotonic growth of a persistent marginal authority topology. Observed rho dispersion is compatible with the finite-count exchangeable-winner baseline. A suggestive high-K negative association between rho and Q_hold remains open for fresh-seed replication.

### 3. Post-hoc finite-count calibration

`real_xm_authority_001_k_surface_null.py`

This is a **post-hoc diagnostic**, not preregistered evidence.

## Replication execution lineage — scientifically unresolved

### Attempt 1

`REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_ATTEMPT1_INFRA_FAILURE.md`

Infrastructure failure during the first epoch-end checkpoint write for seed 101 / K=2. No preregistered late endpoint or complete seed-block contrast existed.

### Recovery v2

`REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_V2_INCOMPLETE.md`

Classification: `REPLICATION_V2_INCOMPLETE`.

V2 completed and audited 14/15 preregistered members. Only `(seed=505,K=12)` was incomplete. The console log ended during epoch-0 validation of that member without an internal error marker, so interruption cause remains unknown. No four-seed/partial endpoint was opened.

### Custody gate

Frozen verifier commit:

`7a38002e9bb781b9f8e34a12bbfb7a646d9dc5e7`

The later Kaggle session showed `/kaggle/working` effectively empty and failed immediately at `frozen checkout absent`, emitting:

`CUSTODY_FAIL_FULL_15_MEMBER_RERUN_REQUIRED`.

Therefore the 14 previously completed measurement-bearing artifacts were not available for exact custody recovery. Minimal 14+1 completion is forbidden.

## Fresh full rerun — v3 segmented infrastructure

Scientifically required fallback: a complete fresh 15-member replication under the unchanged frozen protocol.

Execution note:

`../REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_V3_EXECUTION.md`

Frozen v3 script commit:

`411528744cc1b91cb4d252e7ddafacb87b648038`

V3 changes only execution segmentation: one complete training-seed block per Kaggle invocation, with immediate archive preservation. The same seeds `{101,202,303,404,505}`, matched `K={2,8,12}`, data, model, observer, schedule, checkpoint-free boundary, endpoint, and diagnostics are retained.

Each block launcher invocation records all three K members for one seed and emits `real_xm_authority_001_seed<SEED>_block.tar.gz`. It does not run the five-seed summarizer.

After five preserved block archives exist, the frozen assembly script re-audits all 15 and then invokes the already-frozen summarizer once.

Until that assembly succeeds:

`FULL_15_MEMBER_RERUN_REQUIRED / NO REPLICATION RESULT`.

## Frozen replication hypothesis and endpoint

Protocol:

`../REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md`

Primary endpoint:

`Z_late(K,s)` = mean Fisher-z of `corr_R(rho,Q_hold)` at steps 1536 and 2048.

Primary contrast:

`Delta_s^(12-2)=Z_late(12,s)-Z_late(2,s)`.

Primary directional hypothesis:

`mean_s Delta_s^(12-2) < 0`.

The discovery is frozen as **authority/competence coupling**, not competence-selective routing. Replication cannot identify whether competence affects authority, authority affects competence, or a stable latent-region property affects both.

Marginal rho dispersion remains calibrated against the exchangeable-winner finite-count null. The secondary stable-region diagnostic remains frozen.

## Claim ceiling

Current real-data evidence is limited to a deterministic 4096-train / 256-validation ImageNet subset, one discovery training seed per K in the recorded surface, Tesla P100 / `16-mixed` precision, the frozen 16-cell coordinate-sign partition, 2049 optimizer steps per K, and Q_hold rather than Q_gen.

The recorded results do **not** establish a universal property of Explorative Modeling, absence of authority topology under other partitions/regimes, a causal effect of low winner authority on competence, or any performance claim.

The fresh-seed replication currently has **no scientific result**.
