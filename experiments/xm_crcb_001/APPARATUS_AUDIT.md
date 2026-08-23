# XM-CRCB-001 — Calibration Apparatus Audit

Status:

```text
APPARATUS_READY
CALIBRATION RUN = UNRUN
REPAIR-LANGUAGE ADEQUACY = UNKNOWN
SCIENCE RUN = NOT AUTHORIZED
```

This audit records apparatus engineering for the frozen calibration-only repair-language gate. It is not a calibration result and not evidence for repair factorization or `H_CRCB`.

Permanent firewall:

```text
witness pass != repair-language adequacy
```

## 1. Frozen parents

Scientific/apparatus organism parent:

```text
be7cefd60cf199e9fbabd6110be1254a1756590e
```

Frozen Corrigible Compression calibration protocol:

```text
4d0e87613ef1b894d6ebac2400e358a9fd82e5ae
```

Apparatus branch:

```text
xm-crcb-001/calibration-apparatus
```

The branch was created directly from `be7cefd60cf199e9fbabd6110be1254a1756590e`.

No pre-existing XM model, training, winner-selection, observer, optimizer, or dataset-construction source file is modified by this apparatus branch. All apparatus code is added under `experiments/xm_crcb_001*`.

## 2. Apparatus source identities

Exact tested/committed source identities:

| file | Git blob SHA | SHA-256 |
|---|---|---|
| `experiments/xm_crcb_001_calibration.py` | `7c8c6feeadeed3aff0ad9eb071914037eaea2fb8` | `669e0674c800819884b66874ed2135f7aa04eed8f5fba8e47df02aaa3b89d96c` |
| `experiments/xm_crcb_001/core.py` | `e82965c7ef33256cd26c08debc32d3cf1ee767d9` | `1f5872537646d664a2524ed0fc1d90410b42f32a01886998802babad6d71d136` |
| `experiments/xm_crcb_001/real_runner.py` | `5198d56b57f108c6791159c28df84ce4569747b3` | `6284bece93dd7ae0f4c2ce2980d99752b8b28620e540085d56c50f733d902b27` |
| `experiments/xm_crcb_001/witness.py` | `c43f63a29df838713fef6188e105838161c1323c` | `1d220af3dc4438f887b9df6a73f862a05cd031c023c272b64c17beff9ef99032` |

The entrypoint sets `CUBLAS_WORKSPACE_CONFIG=:4096:8` before importing calibration modules. The real runner additionally enables PyTorch deterministic algorithms and disables cuDNN benchmarking.

All four Python source files passed `python -m py_compile` in the engineering environment before this audit was recorded.

## 3. Real calibration runner contract

The real runner is designed to fail closed unless:

- `XM_AUTHORITY_OBS` is disabled;
- CUDA is available;
- the loaded base organism uses velocity / flow-matching supervision;
- `xm_best_of_k == 2` for base training;
- the supplied validation safetensors object has exactly 256 examples of latent shape `(4,32,32)` plus 256 labels;
- the full validation latent-cache SHA-256 equals the already-audited specimen hash `f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99`;
- only semantic validation indices `0..127` are materialized by calibration code;
- base manifests certify seeds `606` / `707`, `K_train=2`, 2049 optimizer steps, batch size 8, exact train/validation latent hashes, and exact checkpoint SHA-256;
- a larger language can execute only after prior declared language-result artifacts certify `LANGUAGE_FAIL` in order.

The calibration evaluator uses fixed private region/time/noise domains and no best-of-K repair search.

Repair construction uses a fresh AdamW instance for each dedicated repair and checks that all non-whitelisted parameter hashes remain exact.

## 4. Synthetic/no-op witness command

The apparatus witness was executed from the repository-shaped layout with:

```bash
python experiments/xm_crcb_001_calibration.py witness --out <fresh-output-dir>
```

It was executed twice into different output directories after the final path-independent custody change.

All three output artifacts were bitwise identical across the two executions.

## 5. Witness custody

Recorded artifacts:

```text
witness_result.json
SHA-256 = 0140e8d77be8e19a4b3ac691a58ce96459643cccdcda62cbaae77e1f282c3714
bytes   = 3875

witness_trace.json
SHA-256 = 0d8515f79dc7e5aac053c7678db5ff29f31761d2eb84e380f685f16a3581a501
bytes   = 1991

witness_custody_manifest.json
SHA-256 = f93501c7c49be1d007938b3af248ebcf4e7c6f80a0523cd77966f23b5f035cfe
bytes   = 493
```

Canonical inner witness payload SHA-256:

```text
97513fcde3ca6051dbf9961b8c4f77b811b5dae67b8df1e295341ef1dfb0151b
```

The result, trace, and manifest are preserved under `experiments/xm_crcb_001/witness/`.

## 6. What the witness validated

### Exact language whitelists

The synthetic model mirrored the relevant DiT names and independently exercised all three declared language scopes.

For every language:

```text
selected parameters changed
AND
all non-selected parameter hashes remained exact
```

The witness therefore validates the whitelist/isolation machinery, not repair adequacy.

### Independent RNG domains

The witness verified:

```text
same private domain -> exact replay
different private domain -> different tensor
witness execution -> global torch RNG state unchanged
```

### Null path

The no-update path verified:

```text
Delta = 0 exactly
parameter hash unchanged
repeated fixed evaluation bitwise identical
```

### Validation partition / science seal

The tracking dataset verified:

```text
construction semantic indices = 0..63
evaluation semantic indices   = 64..127
maximum semantic index read   = 127
science-reserved accesses     = 0
science-region constructor calls = 0
```

No parity factorization object was constructed.

### Sequential stopping rule

A synthetic decision fixture was executed:

```text
L1 = FAIL
L2 = PASS
L3 = MUST_NOT_RUN
```

and the apparatus attempted exactly `L1 -> L2`, selected `L2`, and did not attempt `L3`.

### Reproducible custody

The complete synthetic witness was rerun twice. Canonical result payload, persisted trace, result JSON, and custody manifest reproduced exactly across distinct output paths.

## 7. What the witness did NOT validate

This witness is CPU/synthetic apparatus validation only.

It did **not**:

- load a real XM checkpoint;
- execute the calibration path on CUDA;
- load the real ImageNet latent cache;
- train calibration base seeds 606 or 707;
- evaluate any real calibration region;
- observe any repair-language gain or collateral damage;
- produce a repair-language adequacy decision;
- construct the parity science split;
- construct the five-component repair basis;
- inspect true-code or random-code factorization;
- read `rho` or any authority metric;
- test `H_CRCB`;
- authorize the XM-CRCB-001 science assay.

Therefore:

```text
APPARATUS_READY
!=
REAL_CUDA_PATH_VALIDATED
!=
REPAIR_LANGUAGE_ADEQUATE
```

A real CUDA execution failure would be an apparatus/infrastructure result unless and until the frozen calibration reaches its declared scientific adequacy decision.

## 8. Apparatus classification

The engineering witness supports exactly:

```text
APPARATUS_READY
```

Meaning:

> The frozen calibration machinery has a deterministic synthetic/no-op witness demonstrating exact parameter-scope isolation, private RNG behavior, null-update identity, validation/science partition isolation, sequential stopping semantics, and reproducible custody artifacts.

It does not support any empirical statement about whether `L_A^(1)`, `L_A^(2)`, or `L_A^(3)` can repair the real XM organism.

## 9. Next authorized boundary

Do not run the factorization science assay.

Before calibration can execute, produce the two calibration-only real base checkpoints and manifests for seeds:

```text
606
707
```

on the already frozen `K_train=2` real-ImageNet chassis, with exact data identities and checkpoint custody.

Then invoke **L1 only**. L2 is authorized only if the frozen L1 result is `LANGUAGE_FAIL`; L3 is authorized only after frozen L1 and L2 failures.
