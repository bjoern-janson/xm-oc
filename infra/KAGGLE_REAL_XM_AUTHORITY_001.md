# Kaggle handoff — REAL-XM-AUTHORITY-001

Current status: **GPU apparatus validated; real-data K=2 pilot and matched K surface recorded/reviewed.**

This branch is infrastructure / execution custody only. It does **not** modify or replace draft PR #9.

Frozen scientific/apparatus commit:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

## Completed execution lineage

1. Synthetic CUDA smoke validated the frozen observer path on Tesla P100.
2. Real-ImageNet-subset K=2 pilot was recorded:
   - `infra/results/REAL_XM_AUTHORITY_001_K2_PILOT_RESULT.md`
3. Matched real-data surface `K in {1,2,5,8,12}` was recorded:
   - prospective protocol: `infra/REAL_XM_AUTHORITY_001_K_SURFACE.md`
   - result ledger: `infra/results/REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`
   - post-hoc finite-count null calibration: `infra/results/real_xm_authority_001_k_surface_null.py`

## Current scientific compression

The single-seed matched surface did **not** demonstrate monotonic growth of a persistent marginal authority topology as K increased. Cumulative and windowed rho dispersion was compatible with the finite-count exchangeable-winner baseline.

A suggestive high-K negative association between `rho` and `Q_hold` appeared, strongest at K=12 after step 1024. That is a fresh-seed replication target, not an established causal or mechanism claim.

Claim ceiling:

- small real-ImageNet subset;
- one training seed;
- P100 / `16-mixed` execution regime;
- frozen 16-region coordinate-sign partition;
- no Q_gen result yet;
- no universal conclusion about XM.

## Historical smoke launcher

The original synthetic apparatus smoke remains available for provenance:

```bash
!curl -fsSL https://raw.githubusercontent.com/bjoern-janson/xm-oc/infra/kaggle-real-xm-authority-001/infra/kaggle_real_xm_authority_001_smoke.sh | bash
```

Its output directory is:

`/kaggle/working/real_xm_authority_001_smoke/output`

The smoke is apparatus validation only and must not be cited as real-data evidence.

## Next admissible scientific knife

Do not modify PR #9, the observer, or the region definition in response to the surface.

If continuing, prospectively freeze a fresh-seed replication focused on `K={2,8,12}` using the same data specimen, horizon, observer, region map, and Q_hold bank. Primary replication object: the sign/magnitude trajectory of `corr(rho,Q_hold)` together with null-calibrated rho dispersion.
