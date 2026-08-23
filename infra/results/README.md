# REAL-XM-AUTHORITY-001 results index

This directory contains **post-run result records and diagnostic analyses** for the frozen scientific/apparatus commit:

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

This is a **post-hoc diagnostic**, not preregistered evidence. It calibrates rho dispersion under a region-neutral exchangeable-winner counting null and must not be represented as part of the prospective surface protocol.

## Replication execution lineage — scientifically unresolved

### Attempt 1

`REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_ATTEMPT1_INFRA_FAILURE.md`

Classification: infrastructure failure during the first epoch-end checkpoint write for seed 101 / K=2. No preregistered late endpoint or complete seed-block contrast existed.

### Recovery v2

`REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_V2_INCOMPLETE.md`

Classification:

`REPLICATION_V2_INCOMPLETE`

Recovery v2 completed and audited 14/15 preregistered members. The only missing member is `(seed=505,K=12)`. The complete console log ends during epoch-0 validation of that member without a Python traceback, shell `FATAL:` marker, or model/observer assertion. The interruption cause is left unknown.

No replication endpoint is opened from the four complete seed blocks.

### Immediate custody gate

Verifier:

`../verify_real_xm_authority_001_high_k_replication_v2_custody.sh`

Frozen verifier commit:

`7a38002e9bb781b9f8e34a12bbfb7a646d9dc5e7`

The verifier performs **no training and no summarization**. It requires the 14 completed members to be byte-identical to the SHA-256 anchors printed by the interrupted v2 run and reruns their structural audits. It also verifies the frozen checkout, execution-bundle files, matched latent cache, and checkpoint-free boundary.

Pass marker:

`CUSTODY_14_PASS_MISSING_505_K12_RECOVERABLE`

Failure marker:

`CUSTODY_FAIL_FULL_15_MEMBER_RERUN_REQUIRED`

If custody passes, only `(505,12)` may be rerun from scratch, followed by member-15 audit and one invocation of the already-frozen summarizer. If custody fails, the scientifically clean fallback is a complete fresh 15-member v2 campaign.

## Frozen replication hypothesis and endpoint

High-K authority/competence coupling protocol:

`../REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md`

Fresh seed blocks `{101,202,303,404,505}` with matched `K={2,8,12}`.

Primary endpoint:

`Z_late(K,s)` = mean Fisher-z of `corr_R(rho,Q_hold)` at steps 1536 and 2048.

Primary contrast:

`Delta_s^(12-2)=Z_late(12,s)-Z_late(2,s)`.

Primary directional hypothesis:

`mean_s Delta_s^(12-2) < 0`.

The discovery is frozen as **authority/competence coupling**, not competence-selective routing. Replication does not identify whether competence affects authority, authority affects competence, or a stable latent-region property affects both.

Marginal rho dispersion remains calibrated against the exchangeable-winner finite-count null. A secondary frozen diagnostic tracks whether the same region identities repeatedly occupy low-rho/high-Q positions across fresh seeds.

## Claim ceiling

Current real-data evidence is limited to a deterministic 4096-train / 256-validation ImageNet subset, one discovery training seed per K in the recorded surface, Tesla P100 / `16-mixed` precision, the frozen 16-cell coordinate-sign partition, 2049 optimizer steps per K, and Q_hold rather than Q_gen.

The recorded results do **not** establish a universal property of Explorative Modeling, absence of authority topology under other partitions/regimes, a causal effect of low winner authority on competence, or any performance claim.

The fresh-seed replication currently has **no scientific result** because one preregistered member is missing.
