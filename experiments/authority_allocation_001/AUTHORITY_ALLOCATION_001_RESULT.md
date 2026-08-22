# AUTHORITY-ALLOCATION-001 Result

## Classification

`AUTHORITY_STARVATION_SUPPORTED_IN_FROZEN_TOY`

## Scientific freeze

Frozen scientific design + executable commit:

`1b134deb26ce343f1e7ec98f9b60e33f10a0ca9f`

Development seeds used before freeze: `0..255`.

Fresh confirmatory seeds opened only after freeze:

`10000..10255` (256 paired seeds).

## Exact-commit execution custody

GitHub Actions workflow run:

`32580616436`

Workflow head SHA:

`802d908fc31ca89469ddc93f04a581b5447130c5`

Result artifact:

`authority-allocation-001-result` / artifact ID `9477685279`

Artifact ZIP digest:

`sha256:ed9af4bb4a9a3bf5e5690b328a06dea77c8b70c94b023958d92f05416594d77e`

The workflow completed successfully and executed the frozen confirmatory block with Python 3.12.

## Confirmatory summary

### Proposal exposure vs update authority

All K=8 regimes received the exact same candidate proposal stream.

For region B before the shift:

| Regime | B candidate-slot rate | B exposure-step rate | B authority mass | B update magnitude |
| --- | ---: | ---: | ---: | ---: |
| hard-XM | 0.499794 | 0.995819 | 0.003418 | 0.042601 |
| balanced | 0.499794 | 0.995819 | 0.499794 | 0.998588 |
| soft-XM | 0.499794 | 0.995819 | 0.439041 | 0.996803 |
| K=1 | 0.497192 | 0.497192 | 0.497192 | 0.998567 |

The primary mechanism separation is therefore:

\[
\boxed{
P(B\text{ exposed under hard-XM})\approx 0.996
\quad\text{while}\quad
\mathbb E[A(B)]\approx 0.00342.
}
\]

B was almost always present in the candidate set while receiving almost no direct update authority.

### Pre-shift competence debt

Mean B error immediately before the shift:

| Regime | Mean B pre-shift error |
| --- | ---: |
| hard-XM | 0.920950 |
| balanced | 0.00000209 |
| soft-XM | 0.00001085 |
| K=1 | 0.00000281 |

### Future recoverability

Recovery criterion:

\[
|\theta_B-1|\le0.1.
\]

Mean censored post-shift recovery latency:

| Regime | Mean | Median | recovered by step 16 | recovered by step 32 |
| --- | ---: | ---: | ---: | ---: |
| hard-XM | 21.625 | 22 | 0 / 256 | 256 / 256 |
| balanced | 1.0 | 1 | 256 / 256 | 256 / 256 |
| soft-XM | 1.0 | 1 | 256 / 256 | 256 / 256 |
| K=1 | 1.0 | 1 | 256 / 256 | 256 / 256 |

Paired hard-XM minus balanced recovery latency:

\[
\boxed{
\Delta T = +20.625\text{ steps}
}
\]

with:

- hard slower: `256 / 256`
- ties: `0 / 256`
- hard faster: `0 / 256`

The same paired count and mean difference held against K=1 and soft-XM.

## Frozen gates

1. Hard-XM B exposure-step rate >= 0.95: **PASS** (`0.995819`).
2. Hard-XM B authority mass <= 0.02: **PASS** (`0.003418`).
3. Balanced/soft use the exact same K=8 proposal stream as hard-XM: **PASS by construction**.
4. Hard-XM slower than balanced on >=95% of paired seeds and mean difference >=8 steps: **PASS** (`256/256`, `+20.625`).

Therefore the frozen classification is earned.

## Claim ceiling

This result establishes only:

\[
\boxed{
\text{winner-take-all model-dependent allocation can create future recoverability debt}
\text{ despite near-complete proposal exposure in this frozen synthetic construction.}
}
\]

It does **not** establish that released continuous XM models exhibit this pathology.

It does **not** validate an OpenCore mechanism.

It does **not** establish a general law of representation learning.

The synthetic regions are explicit and have directly observable competence coordinates; real XM uses ephemeral latent/noise samples with shared neural parameters. A successor experiment must preserve that harder structure before any claim is transported to continuous XM.
