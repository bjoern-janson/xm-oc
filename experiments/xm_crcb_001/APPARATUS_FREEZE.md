# XM-CRCB-001 — Calibration Apparatus Freeze

Status:

```text
CALIBRATION APPARATUS = FROZEN / APPARATUS_READY
SYNTHETIC WITNESS     = PASS
REAL CALIBRATION      = UNRUN
SCIENCE ASSAY         = NOT AUTHORIZED
```

This file freezes the calibration apparatus after the synthetic/no-op witness and custody audit.

Frozen scientific/apparatus parent:

```text
be7cefd60cf199e9fbabd6110be1254a1756590e
```

Frozen calibration protocol authority:

```text
corrigible-compression
4d0e87613ef1b894d6ebac2400e358a9fd82e5ae
```

Frozen source blobs:

```text
experiments/xm_crcb_001_calibration.py
Git blob  7c8c6feeadeed3aff0ad9eb071914037eaea2fb8
SHA-256   669e0674c800819884b66874ed2135f7aa04eed8f5fba8e47df02aaa3b89d96c

experiments/xm_crcb_001/core.py
Git blob  e82965c7ef33256cd26c08debc32d3cf1ee767d9
SHA-256   1f5872537646d664a2524ed0fc1d90410b42f32a01886998802babad6d71d136

experiments/xm_crcb_001/real_runner.py
Git blob  5198d56b57f108c6791159c28df84ce4569747b3
SHA-256   6284bece93dd7ae0f4c2ce2980d99752b8b28620e540085d56c50f733d902b27

experiments/xm_crcb_001/witness.py
Git blob  c43f63a29df838713fef6188e105838161c1323c
SHA-256   1d220af3dc4438f887b9df6a73f862a05cd031c023c272b64c17beff9ef99032
```

Frozen witness custody:

```text
witness_result.json
0140e8d77be8e19a4b3ac691a58ce96459643cccdcda62cbaae77e1f282c3714

witness_trace.json
0d8515f79dc7e5aac053c7678db5ff29f31761d2eb84e380f685f16a3581a501

witness_custody_manifest.json
f93501c7c49be1d007938b3af248ebcf4e7c6f80a0523cd77966f23b5f035cfe
```

Classification:

```text
APPARATUS_READY
```

Permanent claim ceiling:

```text
witness pass != repair-language adequacy
```

The synthetic witness validates apparatus mechanics only. In particular, it does not validate the real CUDA calibration path and does not expose any real calibration outcome.

Any change to the frozen source blobs above requires a new apparatus audit/freeze before real calibration execution.

Next boundary:

```text
produce custody-valid calibration base checkpoints for seeds 606 and 707
-> run frozen L1 calibration only
-> advance to L2/L3 solely under the frozen sequential stopping rule
```
