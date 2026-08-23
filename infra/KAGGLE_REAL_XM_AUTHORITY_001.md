# Kaggle handoff — REAL-XM-AUTHORITY-001

Current status: **GPU apparatus validated; real-data K=2 pilot and matched K surface recorded/reviewed; fresh-seed high-K coupling replication v2 is incomplete at 14/15 members and scientifically unresolved.**

This branch is infrastructure / execution custody only. It does **not** modify or replace draft PR #9.

Frozen scientific/apparatus commit:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

## Completed execution lineage

1. Synthetic CUDA observer smoke: apparatus validated on Tesla P100.
2. Real ImageNet-subset K=2 pilot: recorded.
3. Matched real-data K surface `K={1,2,5,8,12}`: recorded/reviewed.
4. High-K replication attempt 1: infrastructure failure during the first epoch-end `last.ckpt` write for seed 101 / K=2; no preregistered late endpoint or seed-block contrast completed.
5. High-K replication recovery v2: 14/15 members completed and audited; `(seed=505,K=12)` is missing. The full console log ends during epoch-0 validation of that member without an internal error marker. Cause remains unknown.

Recorded results / failures:

- `infra/results/REAL_XM_AUTHORITY_001_K2_PILOT_RESULT.md`
- `infra/results/REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`
- `infra/results/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_ATTEMPT1_INFRA_FAILURE.md`
- `infra/results/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_V2_INCOMPLETE.md`
- `infra/results/README.md`

Current narrow scientific result remains unchanged: larger K did not demonstrate monotonic growth of a persistent marginal authority topology under the frozen 16-region partition; observed rho dispersion is compatible with the exchangeable-winner finite-count baseline. The high-K negative rho/Q_hold association remains a replication target, not an established mechanism.

## Immediate next gate — custody verification

Do **not** open the four-complete-seed result and do not rerun anything yet.

Run the commit-pinned custody verifier. It performs no training and no summarization. It checks:

- frozen checkout SHA and cleanliness;
- exact recovered execution-bundle file hashes;
- exact matched ImageNet latent-cache hashes;
- all 14 completed member observer/train-log/member-audit SHA-256 anchors recorded by v2;
- structural member audits: 2049 authority records, Q_hold at `{512,1024,1536,2048}`, K/batch/replay invariants;
- absence of checkpoint files;
- present partial state of `(505,12)` for non-scientific provenance only.

Custody verifier commit:

`7a38002e9bb781b9f8e34a12bbfb7a646d9dc5e7`

### One-cell custody check

```bash
!curl -fsSL https://raw.githubusercontent.com/bjoern-janson/xm-oc/7a38002e9bb781b9f8e34a12bbfb7a646d9dc5e7/infra/verify_real_xm_authority_001_high_k_replication_v2_custody.sh | bash
```

Successful terminal marker:

`CUSTODY_14_PASS_MISSING_505_K12_RECOVERABLE`

Failure terminal marker:

`CUSTODY_FAIL_FULL_15_MEMBER_RERUN_REQUIRED`

If custody passes, the next authorized recovery is exactly: discard only the incomplete `(505,12)` member after recording its partial hashes/counts, rerun `(505,12)` from scratch under the unchanged v2 protocol, audit it, then run the frozen summarizer once.

If custody fails, minimal recovery is forbidden; the clean fallback is a complete fresh 15-member v2 campaign using launcher `1059bd8e3d307b7718e8f82b9b3057c851e14947`.

## Frozen replication design

Protocol:

`infra/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md`

Recovered execution bundle:

`30cacad1aa73b5b860f5057b5e1bb8b75b4b000f`

Replication design remains unchanged:

- fresh training seed blocks `{101,202,303,404,505}`;
- matched `K={2,8,12}` inside each block;
- same ImageNet specimen, observer, region map, holdout bank, architecture, optimizer, and 2049-step schedule;
- primary endpoint: late Fisher-z average of regional `corr(rho,Q_hold)` at steps 1536 and 2048;
- primary seed-block contrast: `Z_late(K=12)-Z_late(K=2)`;
- causal direction explicitly unclaimed;
- marginal rho dispersion calibrated against the fixed finite-count null;
- secondary region-identity stability diagnostic frozen before completed fresh-seed replication.

Status: **V2 INCOMPLETE / CUSTODY VERIFICATION PENDING / NO REPLICATION RESULT**.
