# REAL-XM-AUTHORITY-001 — matched K-surface result

Status: **RECORDED / REVIEWED**

Result date: 2026-08-22

This record is post-run. It does **not** modify the frozen scientific/apparatus commit, observer, region definition, training objective, dataset specimen, or prospectively frozen K-surface execution bundle.

## Provenance

- frozen scientific/apparatus SHA: `be7cefd60cf199e9fbabd6110be1254a1756590e`
- frozen execution bundle SHA: `77af49e51e04eac730f8e3303551a9645e58210e`
- original frozen surface launcher SHA: `5133647aa5beb50e92e7acdea25e71f7f801fef6`
- infrastructure-only import-path repair wrapper SHA: `3d4da27a09c6676081a0c459584292903e52587d`
- dataset: `ILSVRC/imagenet-1k`
- dataset revision: `49e2ee26f3810fb5a7536bbf732a7b07389a47b5`
- train specimen: 4096 images
- validation specimen: 256 images
- batch/effective batch: 8 / 8
- optimizer steps per K: 2049
- precision: `16-mixed` on Tesla P100
- K surface: `{1,2,5,8,12}`
- region definition: frozen 4-bit coordinate-sign hash, seed `314159`
- realized region coordinates: `[808, 1575, 2250, 2349]`
- holdout seed: `271828`
- holdout examples per region: 8
- Q_hold checkpoints: `512, 1024, 1536, 2048`

The rebuilt data specimen reproduced the previously recorded K=2 pilot custody hashes before any surface member was trained:

- train RGB+label SHA-256: `4c66cdf359d428ba6e037ce8e9d8ae7814d02b4e1c9eb636df86f0c13ec0d3c3`
- train latent SHA-256: `624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f`
- validation RGB+label SHA-256: `ddb96596358e97db3d5c31579a8376616a3bca481a31f12d92cd97204b042fb7`
- validation latent SHA-256: `f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99`

All five members passed the frozen member audit: one partition record, 2049 train-authority records, four Q_hold records at the preregistered steps, replay/direct audit pass on every train record, and one `last.ckpt`.

Observer JSONL SHA-256 by K:

- K=1: `944848f50f6e29bd902ac9e090cf3d442895caa9e2d2ac1ded648dfedc17c500`
- K=2: `5ec566ee647bd56370548912bace1e6ff7d7cb706baa02701a7e79c9a38461d0`
- K=5: `8ecba1b499861c1225090f355f712308e991257a0af5f6b0b0f595bf32893a54`
- K=8: `0783bc3738e940011ba3b99de94ba90e08d0ae7e620e9412b96f0056bae34d69`
- K=12: `571937f663b66d0b189c0558d421b50e09ec733e3f07251773338d938191f9d8`

Surface output custody:

- surface data manifest SHA-256: `c4818634079b0ee88bb2584a0c2e5c2f347ec229eeec4f1b762b262464200bc3`
- surface summary JSON SHA-256: `992558dddf6b453358e81ee32095ed361685df1119d0df4a4e0ce8dcfb2ff1c8`
- surface summary text SHA-256: `fd9fe36a17c9065fadc0654c0fb9731c94cded78f529f99247e47b82d3c451ea`

## Frozen primary surface readout

| K | rho_min | rho_max | rho_std | max |rho-1| | mean C_set | symmetric E[C_set] |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1.000000 | 1.000000 | 0.000000 | 0.000000 | 0.062500 | 0.062500 |
| 2 | 0.955490 | 1.045898 | 0.023113 | 0.045898 | 0.121153 | 0.121094 |
| 5 | 0.956952 | 1.064284 | 0.025724 | 0.064284 | 0.275744 | 0.275804 |
| 8 | 0.925301 | 1.057949 | 0.028545 | 0.074699 | 0.403379 | 0.403281 |
| 12 | 0.966561 | 1.041539 | 0.023251 | 0.041539 | 0.538887 | 0.539048 |

Candidate-set coverage tracks the prior-symmetric expectation extremely closely for every K.

The cumulative rho spread rises modestly from K=2 to K=8 and then contracts at K=12. There is therefore **no monotonic increase in persistent marginal authority imbalance with K** in this specimen.

## Temporal windows

Frozen complete 512-step-window rho spreads:

- K=1: rho_std = `0, 0, 0, 0`
- K=2: `0.040212, 0.047261, 0.043077, 0.038607`
- K=5: `0.053773, 0.051026, 0.033843, 0.058039`
- K=8: `0.049989, 0.056661, 0.071616, 0.060333`
- K=12: `0.050471, 0.055037, 0.059020, 0.051390`

Transient per-window rho extrema can be farther from 1 than cumulative extrema (for example K=8 reaches `rho_min=0.842912` in `[1024,1536)` and K=5 reaches `rho_max=1.168262` in `[1536,2048)`). Those excursions must not be interpreted as developmental specialization without comparison to the finite-count null.

## Finite-count null calibration (post-hoc diagnostic, not preregistered evidence)

The matched surface creates a K-dependent counting-noise baseline even when winner selection is region-neutral.

Let p=1/16 and N=2049*8=16392 examples. Under a region-neutral exchangeable-winner null, for each region R:

- winner count `W_R` has marginal Binomial/Multinomial mass `p` over N examples;
- the remaining nonwinner candidate slots `U_R` have mass `p` over `N(K-1)` slots and are independent of `W_R` under the exchangeable-candidate null;
- candidate slot count is `S_R=W_R+U_R`;
- `rho_R = (W_R/N)/(S_R/(NK)) = K W_R/S_R`.

A first-order approximation gives

`sd_null(rho_R) ~= sqrt((1-p)(1-1/K)/(N p))`.

For this run:

| K | approximate per-region null SD | observed cross-region rho_std |
|---:|---:|---:|
| 2 | 0.02139 | 0.02311 |
| 5 | 0.02706 | 0.02572 |
| 8 | 0.02830 | 0.02855 |
| 12 | 0.02896 | 0.02325 |

For a 512-step window (4096 examples), the corresponding approximate null SDs are `0.04279, 0.05413, 0.05661, 0.05794` for K=`2,5,8,12`, again matching the scale of the observed windowed spreads.

A fixed-seed post-hoc Monte Carlo calibration with 200,000 exchangeable-null surfaces found no unusual cumulative rho dispersion:

| K | P(null rho_std >= observed) | P(null max|rho-1| >= observed) |
|---:|---:|---:|
| 2 | 0.289 | 0.400 |
| 5 | 0.559 | 0.243 |
| 8 | 0.433 | 0.124 |
| 12 | 0.840 | 0.922 |

Thus the apparent increase in raw rho spread through K=8 is quantitatively compatible with the finite-count baseline induced by K itself. The endpoint allocation spread is **not evidence, by itself, for a real authority topology**.

## rho vs Q_hold

Frozen cumulative rho-vs-Q_hold Pearson correlations:

| K | step 512 | step 1024 | step 1536 | step 2048 |
|---:|---:|---:|---:|---:|
| 1 | n/a | n/a | n/a | n/a |
| 2 | +0.072 | +0.307 | -0.024 | +0.111 |
| 5 | +0.339 | +0.249 | +0.322 | +0.162 |
| 8 | +0.287 | -0.267 | -0.183 | -0.262 |
| 12 | -0.075 | -0.456 | -0.656 | -0.491 |

The preregistered starvation direction is `rho down -> Q_hold up`, i.e. a negative association. K=2 does not show it; K=5 is positive at all checkpoints; K=8 turns weakly/moderately negative after step 512; K=12 is negative at all checkpoints and becomes strongest at steps 1024-2048.

This high-K association is the most interesting signal in the surface, but it is **not sufficient to establish an authority topology or competence debt**:

- one training seed;
- 16 regions;
- four repeated, strongly temporally dependent Q_hold checkpoints;
- multiple K values/checkpoints were inspected;
- cumulative marginal rho dispersion at K=12 is actually smaller than its region-neutral finite-count expectation.

Therefore the correct status is **suggestive high-K coupling requiring fresh-seed replication**, not a positive mechanism claim.

## Classification

`REAL_DATA_MATCHED_K_SURFACE_RECORDED`

Narrow scientific interpretation:

> In this single-seed matched real-ImageNet-subset surface, increasing hard-XM competition from K=1 to K=12 did not produce a gross or monotonically increasing persistent marginal authority imbalance over the preregistered 16 latent regions. The observed cumulative and windowed rho dispersion is compatible with the finite-count exchangeable-winner baseline. However, at high K the preregistered directional association between lower rho and worse Q_hold becomes negative, especially at K=12 after step 1024. That association is a replication target, not an established topology.

Equivalent compression:

`larger K -> no demonstrated marginal authority-topology growth; possible high-K authority/competence coupling remains open.`

## Claim ceiling / non-claims

This result does **not** establish:

- that continuous XM has no authority topology;
- that hard-XM competition cannot create latent specialization under another partition, longer horizon, larger model/data scale, or other seed;
- that the K=12 rho/Q_hold correlation is causal;
- that low direct winner authority causes the observed Q_hold differences;
- that shared-parameter transfer explains the negative result;
- any Q_gen result;
- any performance claim about XM;
- any universal conclusion about Explorative Modeling.

It also does not authorize redefining or clustering the latent regions around the observed high-K correlations.

## Next admissible scientific knife

Do not modify the observer or region definition.

If continuing, prospectively freeze a fresh-seed replication targeted at the high-K coupling while retaining a low-K anchor. A minimal informative follow-up is K=`{2,8,12}` across multiple fresh training seeds with the same data specimen, training horizon, observer, region map, and Q_hold bank. The primary replication object should be the preregistered sign and magnitude trajectory of `corr(rho,Q_hold)` together with null-calibrated rho dispersion.
