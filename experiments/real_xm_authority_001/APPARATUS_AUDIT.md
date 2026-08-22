# REAL-XM-AUTHORITY-001 Apparatus Audit

Status: `OBSERVATIONAL_HOOK_AUDIT_PASS_UNRUN`

Base organism: `9d06ced61e2d2775a34782eb5830584ae4ef6094`.

Draft PR: #9.

## Diff scope

The branch changes only:

- `model/flow/flow_matching.py`;
- `model/img/dit_cc.py`;
- observational experiment files under `experiments/real_xm_authority_001/`.

`model/model_utils.py`, including `xm_chunked_best_of_k`, is unchanged.

## K=1 audit

The original flow-matching line

```python
noise = torch.randn_like(x_start, device=x_start.device)
```

is unchanged and remains at the original sampling location.

The only addition immediately after that draw is an optional observer callback. No replacement noise is drawn, no RNG is consumed by the callback, and the sampled tensor is passed unchanged into the original flow-matching dynamics.

## K>1 audit

The released `xm_chunked_best_of_k` function is not modified.

The DiT caller supplies a wrapper around the existing `loss_calc_wrapper`. The wrapper:

1. calls the original loss wrapper with the original arguments;
2. passes detached candidate noise/loss values to the observer;
3. returns the original loss/prediction objects unchanged.

The observer independently reconstructs chunk/global winner regions for measurement only. Its reconstruction is not returned to XM and cannot affect the helper's selection.

If save-memory replay occurs, the replayed latent is used only to check the reconstructed winner region.

## RNG audit

Training-side region assignment uses a private `random.Random(region_seed)` instance only to select fixed coordinate indices.

Held-out validation probes use private CPU `torch.Generator` objects.

No observer code calls the global torch random generator.

## Validation / generation audit

`Q_hold` is no-grad validation-only evaluation.

`Q_gen` is a separate checkpoint-side evaluator and never executes in the training loop.

## Smoke check

A local CPU smoke check of `AuthorityTopologyObserver` with a synthetic B=2, K=2 candidate batch completed successfully and produced internally consistent candidate-slot, candidate-set, and reconstructed winner counts.

This smoke check is apparatus validation only. It is not scientific evidence about XM.

## Execution state

No real-XM scientific training run has been executed from this branch.
