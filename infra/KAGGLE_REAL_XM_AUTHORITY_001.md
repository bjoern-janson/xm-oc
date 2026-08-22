# Kaggle handoff — REAL-XM-AUTHORITY-001

This is infrastructure only. It does **not** modify or replace draft PR #9 and does not produce the ImageNet scientific result.

Frozen apparatus commit executed by the launcher:

`be7cefd60cf199e9fbabd6110be1254a1756590e`

## Kaggle settings

- Internet: ON
- Accelerator: GPU P100

## One-cell launch

Run this in the Kaggle notebook:

```bash
!curl -fsSL https://raw.githubusercontent.com/bjoern-janson/xm-oc/infra/kaggle-real-xm-authority-001/infra/kaggle_real_xm_authority_001_smoke.sh | bash
```

The launcher:

1. records `nvidia-smi`;
2. installs the repository-pinned PyTorch 2.4.0 / TorchVision 0.19.0 CUDA 12.1 pair so P100 `sm_60` kernels are available;
3. clones `bjoern-janson/xm-oc` and checks out the exact frozen apparatus SHA in detached-HEAD mode;
4. refuses to run on SHA mismatch or a dirty checkout;
5. installs the frozen repo requirements;
6. enables the frozen authority observer;
7. runs a two-step K=2 CUDA pipeline witness using the upstream built-in `img_synthetic` cached-latent dataset and the upstream-supported `vit_base` 256px continuous DiT architecture;
8. checks that partition, training-authority, replay audit, and Q_hold records exist;
9. prints `APPARATUS_CUDA_SMOKE_PASS` only if all checks pass.

Output directory:

`/kaggle/working/real_xm_authority_001_smoke/output`

This smoke uses synthetic latent data and FP32 because P100 does not provide the upstream H100/BF16 environment. It is therefore apparatus validation only. It earns **zero empirical claim about ImageNet / real-XM authority topology**.

The subsequent scientific run still requires an ImageNet-compatible data source or the upstream cached ImageNet latent representation, followed by a prospectively fixed K-arm execution protocol.
