# Kaggle handoff — REAL-XM-AUTHORITY-001

Current status: **GPU apparatus validated; real-data K=2 pilot and matched K surface recorded/reviewed; high-K replication v2 incomplete; custody failed because the prior Kaggle working state did not survive; a complete fresh 15-member rerun is required.**

This branch is infrastructure / execution custody only. It does **not** modify or replace draft PR #9.

Frozen scientific/apparatus commit:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

## Execution lineage

1. Synthetic CUDA observer smoke: apparatus validated on Tesla P100.
2. Real ImageNet-subset K=2 pilot: recorded.
3. Matched real-data K surface `K={1,2,5,8,12}`: recorded/reviewed.
4. High-K replication attempt 1: infrastructure failure during the first epoch-end `last.ckpt` write for seed 101 / K=2.
5. High-K replication recovery v2: 14/15 members completed and audited; `(seed=505,K=12)` was interrupted during epoch-0 validation without an internal diagnostic.
6. Custody verification in a later Kaggle session found `/kaggle/working` effectively empty and the frozen checkout absent. Therefore none of the 14 retained measurement artifacts survived into the recovery session. Terminal classification: `CUSTODY_FAIL_FULL_15_MEMBER_RERUN_REQUIRED`.

No partial/four-seed replication endpoint has been opened.

Recorded results / failures:

- `infra/results/REAL_XM_AUTHORITY_001_K2_PILOT_RESULT.md`
- `infra/results/REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`
- `infra/results/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_ATTEMPT1_INFRA_FAILURE.md`
- `infra/results/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_V2_INCOMPLETE.md`
- `infra/results/README.md`

Current narrow scientific result remains unchanged: larger K did not demonstrate monotonic growth of a persistent marginal authority topology under the frozen 16-region partition; observed rho dispersion is compatible with the exchangeable-winner finite-count baseline. The high-K negative rho/Q_hold association remains a replication target, not an established mechanism.

## Fresh 15-member fallback — segmented v3 execution

Scientific protocol and endpoint remain unchanged. V3 is infrastructure-only segmentation so one Kaggle runtime no longer has to survive the entire five-seed campaign.

Execution note:

`infra/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_V3_EXECUTION.md`

Frozen v3 script commit:

`411528744cc1b91cb4d252e7ddafacb87b648038`

Seed-block launcher:

`infra/kaggle_real_xm_authority_001_high_k_replication_v3_seed_block.sh`

Run exactly once for each seed `{101,202,303,404,505}`. Each invocation runs all `K={2,8,12}`, audits the three members, and emits:

`/kaggle/working/real_xm_authority_001_seed<SEED>_block.tar.gz`

**Preserve/download that archive before ending the Kaggle session.** The block launcher never runs the five-seed summarizer.

Example for seed 101:

```bash
!curl -fsSL https://raw.githubusercontent.com/bjoern-janson/xm-oc/411528744cc1b91cb4d252e7ddafacb87b648038/infra/kaggle_real_xm_authority_001_high_k_replication_v3_seed_block.sh | bash -s -- 101
```

Repeat only with the preregistered seeds 202, 303, 404, and 505.

After all five archives are preserved, place/upload all five into one Kaggle session and run the assembly script from the same frozen commit:

```bash
!curl -fsSL https://raw.githubusercontent.com/bjoern-janson/xm-oc/411528744cc1b91cb4d252e7ddafacb87b648038/infra/kaggle_real_xm_authority_001_high_k_replication_v3_assemble.sh | bash
```

The assembler requires exactly one archive per seed, re-audits all 15 members, checks exact data/execution identities, and only then invokes the already-frozen summarizer once.

## Frozen replication design

Protocol:

`infra/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md`

Recovered execution bundle used inside every member:

`30cacad1aa73b5b860f5057b5e1bb8b75b4b000f`

Unchanged design:

- fresh training seed blocks `{101,202,303,404,505}`;
- matched `K={2,8,12}` inside each block;
- same ImageNet specimen, observer, region map, holdout bank, architecture, optimizer, and 2049-step schedule;
- primary endpoint: late Fisher-z average of regional `corr(rho,Q_hold)` at steps 1536 and 2048;
- primary seed-block contrast: `Z_late(K=12)-Z_late(K=2)`;
- causal direction explicitly unclaimed;
- marginal rho dispersion calibrated against the fixed finite-count null;
- secondary region-identity stability diagnostic unchanged.

Status: **FULL FRESH 15-MEMBER RERUN REQUIRED / V3 SEGMENTED EXECUTION FROZEN / NO REPLICATION RESULT**.
