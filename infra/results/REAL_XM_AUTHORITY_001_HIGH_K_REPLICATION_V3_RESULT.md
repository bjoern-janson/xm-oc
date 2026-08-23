# REAL-XM-AUTHORITY-001 — High-K fresh-seed replication v3 result

## Frozen identities

- Scientific/apparatus SHA: `be7cefd60cf199e9fbabd6110be1254a1756590e`
- Execution bundle SHA: `30cacad1aa73b5b860f5057b5e1bb8b75b4b000f`
- Frozen summarizer SHA-256: `e57a58bcda2eb9693d65f374d6464d5c9a381a5047337f7b1a5bfc81e3c6f94b`
- Seeds: `{101,202,303,404,505}`
- K: `{2,8,12}`
- Pre-endpoint custody state: `ASSEMBLED_15_MEMBER_CUSTODY_PASS`
- Frozen summarizer executed exactly once after custody validation.

Machine classification emitted by the frozen summarizer:

`REAL_DATA_HIGH_K_COUPLING_REPLICATION_RECORDED`

Claim ceiling emitted by the frozen summarizer:

> five fresh seed blocks on the same small real-ImageNet subset; observational association only; no causal direction and no Q_gen claim

## Primary endpoint

For each seed,

`Delta_s^(12-2) = Z_late(K=12,s) - Z_late(K=2,s)`

with `Z_late` the mean Fisher-z transform of `corr_R(rho,Q_hold)` at steps 1536 and 2048.

| seed | Z2 | Z8 | Z12 | Delta12-2 |
|---:|---:|---:|---:|---:|
| 101 | -0.329832 | 0.174994 | -0.616134 | -0.286302 |
| 202 | -0.234499 | 0.147643 | 0.019540 | 0.254039 |
| 303 | 0.201757 | -0.007374 | -0.315077 | -0.516834 |
| 404 | -0.115329 | -0.145154 | 0.802848 | 0.918177 |
| 505 | 0.124344 | 0.049811 | 0.031915 | -0.092429 |

Primary preregistered directional criterion:

`mean_s Delta_s^(12-2) < 0`

Observed:

- mean Delta12-2 = `+0.055330143472616`
- median Delta12-2 = `-0.09242902340410744`
- negative Delta count = `3/5`
- mean Z_late K2 = `-0.07071178955643409`
- mean Z_late K8 = `+0.04398416800445396`
- mean Z_late K12 = `-0.01538164608381808`

Therefore:

- `primary_direction_mean_delta_lt_zero = false`
- `robustness_median_delta_lt_zero = true`

Interpretive classification:

`PRIMARY_DIRECTIONAL_REPLICATION_NOT_SUPPORTED_IN_FROZEN_FIVE_SEED_SPECIMEN`

This is not a claim that all authority/competence coupling is absent. It is a failure of the prospectively frozen directional mean replication criterion.

## Prospectively fixed marginal-null calibration

Most marginal authority dispersion measurements remained compatible with the exchangeable-winner finite-count calibration. One isolated tail event occurred at seed 505, K=8 for max absolute rho deviation (`p_null_max_abs_ge_observed = 0.004525`), with the corresponding rho-SD tail probability `0.059820`. K=12 did not show a comparable cross-seed pattern. This does not establish a coherent increasing-K authority-topology effect.

## Secondary stable-region diagnostic

Mean pairwise seed Spearman for late Q_hold region rankings:

- K2: `0.9252941176470589`
- K8: `0.9335294117647057`
- K12: `0.9308823529411765`

Mean pairwise seed Spearman for late rho region rankings:

- K2: `-0.03441176470588235`
- K8: `-0.059705882352941185`
- K12: `-0.08470588235294116`

Narrow reading: the fixed-partition region difficulty/competence ordering is highly stable across seeds, while the authority-ratio ordering is not seed-stable. In this specimen the replication therefore does not support a stable seed-invariant authority topology aligned with the stable Q_hold structure.

## Claim ceiling

The frozen five-seed result supports only the following narrow statements:

1. The preregistered directional mean contrast `mean_s Delta_s^(12-2) < 0` did not replicate.
2. Robustness indicators were mixed: median Delta was negative and 3/5 seed contrasts were negative, but two positive contrasts—especially seed 404—reversed the mean.
3. There was no monotonic K trend in mean Z_late.
4. Q_hold region identity was highly stable across seeds; rho region identity was not.
5. No causal direction is identified.
6. No Q_gen claim is earned.
7. This result does not retroactively establish or erase authority starvation in other specimens.

## Frozen output custody

- `replication-summary.json` SHA-256: `1dcd13780232c3675615a8a0adc46a95581f230cc4db00b5cf1446ee1464fe8e`
- `replication-summary.txt` SHA-256: `fd3c0197fd1f3e621ec87ce6e12ca2bcd93d49d85ebcc28c1e4405768e0cf743`
- Terminal marker: `REAL_DATA_HIGH_K_COUPLING_REPLICATION_OBSERVATION_FROZEN`
