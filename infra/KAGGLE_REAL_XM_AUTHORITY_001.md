# Kaggle handoff — REAL-XM-AUTHORITY-001

Current status: **GPU apparatus validated; real-data K=2 pilot and matched K surface recorded/reviewed; fresh-seed high-K coupling replication prospectively frozen, attempt 1 failed on checkpoint I/O, recovery v2 scientifically unrun.**

This branch is infrastructure / execution custody only. It does **not** modify or replace draft PR #9.

Frozen scientific/apparatus commit:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

## Completed execution lineage

1. Synthetic CUDA observer smoke: apparatus validated on Tesla P100.
2. Real ImageNet-subset K=2 pilot: recorded.
3. Matched real-data K surface `K={1,2,5,8,12}`: recorded/reviewed.
4. High-K replication attempt 1: infrastructure failure during the first epoch-end `last.ckpt` write for seed 101 / K=2; no preregistered late endpoint or seed-block contrast completed.

Recorded results / failures:

- `infra/results/REAL_XM_AUTHORITY_001_K2_PILOT_RESULT.md`
- `infra/results/REAL_XM_AUTHORITY_001_K_SURFACE_RESULT.md`
- `infra/results/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION_ATTEMPT1_INFRA_FAILURE.md`
- `infra/results/README.md`

Current narrow scientific result remains unchanged: larger K did not demonstrate monotonic growth of a persistent marginal authority topology under the frozen 16-region partition; observed rho dispersion is compatible with the exchangeable-winner finite-count baseline. The high-K negative rho/Q_hold association is a replication target, not an established mechanism.

## Next frozen stage — fresh-seed replication recovery v2

Prospective protocol:

`infra/REAL_XM_AUTHORITY_001_HIGH_K_REPLICATION.md`

Recovered execution bundle:

`30cacad1aa73b5b860f5057b5e1bb8b75b4b000f`

Frozen v2 launcher commit:

`1059bd8e3d307b7718e8f82b9b3057c851e14947`

Replication design remains unchanged:

- fresh training seed blocks `{101,202,303,404,505}`;
- matched `K={2,8,12}` inside each block;
- same ImageNet specimen, observer, region map, holdout bank, architecture, optimizer, and 2049-step schedule;
- primary endpoint: late Fisher-z average of regional `corr(rho,Q_hold)` at steps 1536 and 2048;
- primary seed-block contrast: `Z_late(K=12)-Z_late(K=2)`;
- causal direction explicitly unclaimed;
- marginal rho dispersion calibrated against the fixed finite-count null;
- secondary region-identity stability diagnostic frozen before completed fresh-seed runs.

### Infrastructure recovery

Frozen `train_model.py` hard-codes `save_last=True`; attempt 1 exhausted Kaggle working storage while writing the first checkpoint. Because Q_gen is out of scope and all declared replication endpoints come from the observer JSONL, v2 suppresses checkpoint file writes in the **external execution harness only** while retaining the native callback object/hooks. The launcher requires `--save_top_k_ckpts 0`, audits `REPLICATION_CHECKPOINT_WRITES_DISABLED`, and fails if any `.ckpt` file appears.

No model/XM/observer/training file or scientific endpoint changed.

### One-cell launch

```bash
!curl -fsSL https://raw.githubusercontent.com/bjoern-janson/xm-oc/1059bd8e3d307b7718e8f82b9b3057c851e14947/infra/kaggle_real_xm_authority_001_high_k_replication_v2.sh | bash
```

Kaggle settings:

- Internet: ON
- Accelerator: Tesla P100
- secret `HF_TOKEN` with accepted ImageNet access

Expected final marker:

`=== REAL_DATA_HIGH_K_COUPLING_REPLICATION_RECORDED ===`

Status: **RECOVERY V2 PROSPECTIVELY FROZEN / SCIENTIFICALLY UNRUN**.
