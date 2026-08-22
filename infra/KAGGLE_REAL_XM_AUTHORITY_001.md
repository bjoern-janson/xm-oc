# Kaggle handoff — REAL-XM-AUTHORITY-001

Current status: **GPU apparatus validated; real-data K=2 pilot and matched K surface recorded/reviewed; fresh-seed high-K coupling replication prospectively frozen and scientifically unrun.**

This branch is infrastructure / execution custody only. It does **not** modify or replace draft PR #9.

Frozen scientific/apparatus commit:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

## Completed execution lineage

1. Synthetic CUDA observer smoke: apparatus validated on Tesla P100.
2. Real ImageNet-subset K=2 pilot: recorded.
3. Matched real-data K surface `K={1,2,5,8,12}`: recorded/reviewed.

Recorded results:

- `infra/results/REAL_XM_AUTHORITY_001_K2_PILOT_RESULT.md`
- `infra/results/REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`
- `infra/results/README.md`

Current narrow result: larger K did not demonstrate monotonic growth of a persistent marginal authority topology under the frozen 16-region partition; observed rho dispersion is compatible with the exchangeable-winner finite-count baseline. The high-K negative rho/Q_hold association is a replication target, not an established mechanism.

## Next frozen stage — fresh-seed replication

Prospective protocol:

`infra/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md`

Execution bundle:

`4aa246b5ee80c565d1a8da7d41b4eae083361a2b`

Frozen launcher commit:

`cc7d88f91be2dc0b739acebcc92896e4466694cc`

Replication design:

- fresh training seed blocks `{101,202,303,404,505}`;
- matched `K={2,8,12}` inside each block;
- same ImageNet specimen, observer, region map, holdout bank, architecture, optimizer, and 2049-step schedule;
- primary endpoint: late Fisher-z average of regional `corr(rho,Q_hold)` at steps 1536 and 2048;
- primary seed-block contrast: `Z_late(K=12)-Z_late(K=2)`;
- causal direction explicitly unclaimed;
- marginal rho dispersion calibrated against the fixed finite-count null;
- secondary region-identity stability diagnostic frozen before fresh seeds are run.

The launcher creates/audits/hashes the native `last.ckpt` for each member and then deletes the checkpoint post-training to keep 15 optimizer-bearing checkpoints from exhausting Kaggle storage. Q_gen is out of scope for this replication.

### One-cell launch

Use the commit-pinned launcher:

```bash
!curl -fsSL https://raw.githubusercontent.com/bjoern-janson/xm-oc/cc7d88f91be2dc0b739acebcc92896e4466694cc/infra/kaggle_real_xm_authority_001_high_k_replication.sh | bash
```

Kaggle settings:

- Internet: ON
- Accelerator: Tesla P100
- secret `HF_TOKEN` with accepted ImageNet access

Expected final marker:

`=== REAL_DATA_HIGH_K_COUPLING_REPLICATION_RECORDED ===`

Status: **PROSPECTIVELY FROZEN / SCIENTIFICALLY UNRUN**.
