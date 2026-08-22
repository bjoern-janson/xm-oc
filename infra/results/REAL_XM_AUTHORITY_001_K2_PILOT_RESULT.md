# REAL-XM-AUTHORITY-001 — real-data K=2 pilot result

Status: **RECORDED / REVIEWED**

Result date: 2026-08-22

This record is post-run. It does **not** modify the frozen scientific/apparatus commit, latent-region definition, training objective, or the prospectively frozen launcher used for the run.

## Provenance

- frozen scientific/apparatus SHA: `be7cefd60cf199e9fbabd6110be1254a1756590e`
- prospectively frozen pilot launcher SHA: `16d0fc921a7e57462efd7e26ee627969fa1dc6af`
- dataset: `ILSVRC/imagenet-1k`
- dataset revision: `49e2ee26f3810fb5a7536bbf732a7b07389a47b5`
- train specimen: 4096 images, deterministic streaming shuffle seed `424242`
- validation specimen: 256 images, deterministic streaming shuffle seed `424243`
- model: continuous class-conditional `vit_base` DiT, 256x256, velocity supervision
- hard XM: `K=2`
- batch/effective batch: 8 / 8
- optimizer steps: 2049
- precision: `16-mixed` on Tesla P100
- region definition: frozen 4-bit coordinate-sign hash, seed `314159`
- realized region coordinates: `[808, 1575, 2250, 2349]` in flattened 4096-d noise
- holdout seed: `271828`
- holdout examples per region: 8
- Q_hold steps: `512, 1024, 1536, 2048`

### Data/cache custody

Train:
- selected RGB+label SHA-256: `4c66cdf359d428ba6e037ce8e9d8ae7814d02b4e1c9eb636df86f0c13ec0d3c3`
- latent cache SHA-256: `624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f`
- latent shape: `[4096, 4, 32, 32]`
- classes present: 987

Validation:
- selected RGB+label SHA-256: `ddb96596358e97db3d5c31579a8376616a3bca481a31f12d92cd97204b042fb7`
- latent cache SHA-256: `f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99`
- latent shape: `[256, 4, 32, 32]`
- classes present: 227

### Output custody

- observer JSONL SHA-256: `5ec566ee647bd56370548912bace1e6ff7d7cb706baa02701a7e79c9a38461d0`
- pilot data manifest SHA-256: `c036e44f01f7c4e1c87948a2e8c6f92065d8b3b55119850dd684be6688d14ff1`
- pilot summary JSON SHA-256: `4e891ab408de6a7a5f19bbec61c26b24ba59129d029aa3191a27555d7b328d1b`
- training log SHA-256: `94071cd7538cba65e48893a717c2e5f4959e0b9625be4ee569171d29b9d284ec`
- final `last.ckpt` SHA-256: `3e012e847c1aee2235152a7d66a045f33bebc79f8ff5f7add357bee33dc8d9ee`

Observer record counts:
- total: 2054
- partition: 1
- train-authority: 2049
- Q_hold: 4

## Frozen primary readout

Overall candidate-slot mass by region:

`C_slot = [0.06240849, 0.06143241, 0.06246950, 0.06356759, 0.06277452, 0.06497072, 0.06146291, 0.06320156, 0.06323206, 0.06195095, 0.06262201, 0.06173743, 0.06265251, 0.06167643, 0.06216447, 0.06167643]`

Overall candidate-set coverage by region:

`C_set = [0.12097365, 0.11999756, 0.12127867, 0.12323084, 0.12164470, 0.12597609, 0.11938751, 0.12201074, 0.12219375, 0.12030259, 0.12140068, 0.11908248, 0.12170571, 0.11993655, 0.12011957, 0.11920449]`

Overall winner authority by region:

`A = [0.06143241, 0.06063934, 0.06533675, 0.06216447, 0.06417765, 0.06539776, 0.06009029, 0.06338458, 0.06387262, 0.06344558, 0.06301855, 0.06167643, 0.06314056, 0.05893119, 0.06009029, 0.06320156]`

Authority efficiency:

`rho = A / C_slot = [0.98436, 0.98709, 1.04590, 0.97793, 1.02235, 1.00657, 0.97767, 1.00290, 1.01013, 1.02413, 1.00633, 0.99901, 1.00779, 0.95549, 0.96663, 1.02473]`

Key descriptive facts:

- `C_slot` is close to the prior-symmetric mass `1/16 = 0.0625` in every region; realized range `0.06143–0.06497`.
- Mean `C_set` is `0.121153`, essentially the iid K=2 symmetric expectation `1-(15/16)^2 = 0.12109375`.
- `A` remains close to `C_slot`; realized `rho` range is `0.95549–1.04590`.
- The strongest cumulative authority deficit is therefore only about 4.45% below parity in this specimen (`R13`, `rho=0.95549`).

## Q_hold

The four frozen Q_hold measurements were recorded at the preregistered steps.

Step 512:
`[1.015753, 1.020730, 1.010806, 1.002288, 0.999279, 0.996640, 0.997405, 1.008829, 1.010568, 1.008539, 1.027296, 0.986190, 1.030244, 0.995510, 1.006063, 1.005950]`

Step 1024:
`[0.976966, 0.962383, 0.960202, 0.943202, 0.947355, 0.948483, 0.970305, 0.974284, 0.961620, 0.963488, 0.987554, 0.935865, 0.995343, 0.938349, 0.956213, 0.952175]`

Step 1536:
`[0.934808, 0.931079, 0.929772, 0.915681, 0.922670, 0.920597, 0.933863, 0.942227, 0.934236, 0.933605, 0.970504, 0.903204, 0.958091, 0.913148, 0.938579, 0.927299]`

Step 2048:
`[0.919338, 0.918439, 0.907398, 0.902580, 0.904323, 0.902152, 0.915532, 0.917725, 0.913285, 0.910643, 0.942030, 0.889859, 0.940067, 0.894921, 0.909428, 0.905102]`

Frozen cumulative `rho` vs `Q_hold` Pearson correlations reported by the launcher:

- step 512: `+0.07241`
- step 1024: `+0.30724`
- step 1536: `-0.02449`
- step 2048: `+0.11138`

The hypothesized starvation signature was `rho down -> Q_hold up`, which would require a systematic negative association. No such persistent association appears in this pilot.

Two regions, `R10` and `R12`, are persistently among the highest-loss Q_hold regions across all four checkpoints, but their overall authority efficiencies are approximately parity (`rho(R10)=1.00633`, `rho(R12)=1.00779`). Conversely, the lowest-rho region `R13` (`rho=0.95549`) is among the easier Q_hold regions, ending at `0.89492` versus the step-2048 cross-region median of about `0.91004`.

Thus conditional competence heterogeneity is visible in this specimen, but it is not preceded by the proposed direct authority-starvation pattern under this frozen partition.

## Classification

`REAL_DATA_K2_PILOT_RECORDED`

Narrow scientific interpretation:

> In this single frozen real-ImageNet-subset K=2 pilot, hard continuous XM did not produce a material separation between proposal-slot mass and winner authority over the preregistered 16 latent regions. The strongest frozen authority-starvation pattern (`C_set` high, `rho << 1`, persistently worse `Q_hold`) was not observed. Persistent Q_hold differences existed, but the hardest regions had approximately parity authority rather than low authority.

Equivalent compression:

`A(R) ≈ C_slot(R)` in this specimen.

Under the predeclared decision framing, this is the branch:

`A ≈ C -> toy authority-starvation does not appear in this specimen.`

## Claim ceiling / non-claims

This result does **not** establish:

- that continuous XM has no authority topology;
- that authority starvation cannot occur at larger K;
- that the 16-cell coordinate-sign partition is sufficient to reveal every relevant topology;
- that shared-parameter transfer is the cause of the absence of starvation;
- that the result replicates across training seeds;
- that it holds under full ImageNet training, upstream batch size, upstream BF16 hardware, or long training horizons;
- any Q_gen result;
- any performance claim about XM.

This result also does not authorize redefining the latent regions around observed hard/easy cells.

The appropriate next scientific action, if continuing the frozen program, is the already-declared matched K surface under the same observer and region definition, not a result-driven apparatus mutation.
