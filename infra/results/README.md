# REAL-XM-AUTHORITY-001 results index

This directory contains **post-run result records and diagnostic analyses** for the frozen scientific/apparatus commit:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

These files do not modify the frozen observer, training objective, region definition, or PR #9.

## Recorded results

### 1. Real-data K=2 pilot

`REAL_XM_AUTHORITY_001_K2_PILOT_RESULT.md`

Classification:

`REAL_DATA_K2_PILOT_RECORDED`

Narrow result: under the frozen 16-region partition, K=2 did not show the strong toy-style authority-starvation pattern; `A(R)` tracked `C_slot(R)` closely, while Q_hold heterogeneity existed without a low-rho precursor.

### 2. Matched K surface

`REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`

Classification:

`REAL_DATA_MATCHED_K_SURFACE_RECORDED`

Matched surface:

`K in {1,2,5,8,12}`

Narrow result: increasing K did not demonstrate monotonic growth of a persistent marginal authority topology. Observed rho dispersion is compatible with the finite-count exchangeable-winner baseline. A suggestive high-K negative association between rho and Q_hold remains open for fresh-seed replication.

### 3. Post-hoc finite-count calibration

`real_xm_authority_001_k_surface_null.py`

This is a **post-hoc diagnostic**, not preregistered evidence. It calibrates rho dispersion under a region-neutral exchangeable-winner counting null and must not be represented as part of the prospective surface protocol.

## Claim ceiling

Current real-data evidence is limited to:

- a deterministic 4096-train / 256-validation ImageNet subset;
- one training seed per K;
- Tesla P100 / `16-mixed` precision;
- the frozen 16-cell coordinate-sign latent partition;
- 2049 optimizer steps per K;
- Q_hold, not Q_gen.

The results do **not** establish a universal property of Explorative Modeling, absence of authority topology under other partitions/regimes, a causal effect of low winner authority on competence, or any performance claim.

## Next admissible target

Without modifying the frozen instrument, replicate the high-K rho/Q_hold coupling across fresh training seeds with a low-K anchor. A minimal continuation is `K={2,8,12}` with the same data specimen, horizon, observer, partition, and holdout bank.
