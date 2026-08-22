# REAL-XM-AUTHORITY-001 — Observational Latent Authority Measurement

## Status

`APPARATUS_CONSTRUCTION`

This experiment returns from the frozen AA toy line to the released continuous XM implementation. It is strictly observational.

## Scientific question

Does hard continuous XM create persistent latent regions with high proposal exposure, systematically low winner authority, and measurably worse later conditional competence?

For a fixed latent partition R:

- `C_slot(R)`: fraction of candidate slots whose latent noise lies in R;
- `C_set(R)`: fraction of original examples whose K-candidate set contains at least one latent in R;
- `A(R)`: fraction of original examples whose winning latent lies in R;
- `rho(R) = A(R) / C_slot(R)`;
- `Q_hold(R)`: held-out flow-matching loss under fixed noise conditioned on R (higher is worse);
- `Q_gen(R)`: checkpoint-side generation quality conditioned on inference noise from R, operationalized as per-region FID (lower is better).

Primary empirical pattern of interest:

`C high, A low, Q_hold persistently worse`.

This is not preregistered as an expected outcome. Shared-parameter rescue and approximate proportional allocation are equally admissible outcomes.

## Frozen source organism

Fork base / upstream-equivalent commit:

`9d06ced61e2d2775a34782eb5830584ae4ef6094`

Target implementation:

- IMG class-conditional DiT;
- velocity / flow-matching supervision;
- existing `xm_chunked_best_of_k` hard selection;
- no OT-CFM baseline in this assay.

## No-intervention contract

The observational branch may not change:

- candidate-generation distributions;
- candidate losses;
- winner-selection rule;
- save-memory winner replay;
- optimizer or optimizer hyperparameters;
- gradient allocation;
- model architecture;
- CFG candidate-sharing semantics.

The observer may only read detached candidate tensors/losses, log counts, and run no-grad validation/checkpoint evaluation using private RNG streams.

## K surface

Scientific comparison:

`K in {1, 2, 5, 8, 12}`.

All non-K training settings must be identical across arms. Multiple independent training seeds are required.

K=1 retains the ordinary DiT path; it is not routed through `xm_chunked_best_of_k`.

## Latent partition

Default partition has 16 prior-symmetric regions from four fixed coordinate-sign bits.

- `region_bits = 4`;
- `region_seed = 314159`;
- flattened coordinate indices are sampled once using a private Python `random.Random(region_seed)` instance;
- region id is determined solely by the signs of those four latent coordinates.

The partition does not depend on model loss, winner identity, training history, held-out quality, or global RNG state.

## Training-side observation

### K > 1

The released helper already exposes candidate `rand_inputs` and per-candidate loss before selection. The observer wraps the existing loss calculator, reads only detached values, and independently reconstructs the same chunk/global minima for logging.

It does not modify `xm_chunked_best_of_k`.

When save-memory replay occurs, the observer uses the replayed noise only as an audit check that its reconstructed winner region matches the actual replay region.

### K = 1

The original flow-matching implementation continues to sample noise internally with `torch.randn_like` at the same location. An optional callback observes that tensor immediately after the existing draw. The callback does not draw replacement noise and is not passed any explicit noise by the caller.

For K=1:

`C_slot = A` by construction at the direct-authority level.

## Held-out competence

`Q_hold(R)` is evaluated only in validation mode.

- fixed private holdout seed: `271828`;
- fixed continuous timesteps from a private CPU `torch.Generator`;
- fixed region-conditioned Gaussian noise from private CPU generators;
- no global torch RNG consumption;
- no gradients;
- same validation examples, labels, and timesteps across regions within an evaluation event.

Operational metric:

mean unreduced flow-matching training loss for noise conditioned on R.

## Generation quality

`Q_gen(R)` is evaluated checkpoint-side, outside training.

The evaluator:

- loads a frozen checkpoint;
- generates class-balanced samples with explicit noise conditioned on each region;
- leaves the model and sampler unchanged;
- decodes with the same VAE/RAE path used by the repository;
- computes per-region FID using the repository's existing ADM/ImageNet FID statistics path;
- may additionally record inception score, but FID is the Q_gen quantity.

## Environment activation

Training observation is opt-in only:

`XM_AUTHORITY_OBS=1`

Optional controls:

- `XM_AUTHORITY_REGION_BITS` (default 4)
- `XM_AUTHORITY_REGION_SEED` (default 314159)
- `XM_AUTHORITY_HOLDOUT_SEED` (default 271828)
- `XM_AUTHORITY_OBS_DIR`
- `XM_AUTHORITY_HOLDOUT_EXAMPLES` (default 2)
- `XM_AUTHORITY_HOLDOUT_EVERY_N_VAL_STEPS` (default 1)

When `XM_AUTHORITY_OBS != 1`, the original training semantics must remain unchanged.

## Interpretation ceiling

Possible descriptive outcomes include:

1. high proposal exposure + low authority + worse Q_hold/Q_gen: real-XM analogue of authority starvation in this specimen;
2. low direct authority + normal Q_hold/Q_gen: evidence consistent with shared-parameter rescue in this specimen;
3. A approximately proportional to C_slot: the toy starvation pattern does not appear under this partition/specimen.

None of these outcomes alone establishes a general law, identifies a causal mechanism of shared transfer, justifies changing XM, or transfers an OpenCore mechanism.

## Execution state

No scientific training run has yet been executed from this observational branch.
