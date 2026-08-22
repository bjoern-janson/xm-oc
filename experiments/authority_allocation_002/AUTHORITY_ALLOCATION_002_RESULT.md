# AUTHORITY-ALLOCATION-002 Result

## Status

`FINITE_HORIZON_AUTHORITY_SURFACE_RECORDED`

## Scientific freeze

Frozen scientific design + executable commit:

`753db01c05c1ecdaa4f2c0602a3bacb8c92c695d`

Frozen executable Git blob:

`3c674342ba0cfc9f9ecfdb3bbb6dca5ff38ca40b`

Fresh confirmatory seeds:

`20000..20255` (256 paired seeds).

AA-001 confirmatory seeds were not reused.

## Primary preregistered result

The frozen primary estimand was

\[
\hat\lambda^\star_{T=128,grid}
=\min\{\lambda\in\Lambda:P(T_{rec}\le16\mid\lambda)\ge0.95\}.
\]

With 256 seeds, the frozen gate required at least `244/256` informed-arm recoveries by post-shift step 16.

The confirmatory estimate is

\[
\boxed{\hat\lambda^\star_{T=128,grid}=0.3.}
\]

The neighboring tested values were:

- `lambda=0.1`: `91/256` recovered by step 16;
- `lambda=0.3`: `256/256` recovered by step 16.

This is a finite-horizon, grid-relative threshold only. No continuum threshold or topological claim is implied.

## Proposal coverage

Proposal statistics were matched across every lambda and both arms:

\[
\bar C_B=0.99639892578125,
\qquad
\text{B candidate-slot rate}=0.5000190734863281.
\]

Thus the dose surface is not a candidate-exposure surface.

## Informed authority dose / recovery surface

| lambda | mean B authority / step | mean cumulative B update | mean B pre-shift error | rec@1 | rec@4 | rec@8 | rec@16 | rec@32 | mean censored recovery latency |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 0.0038757324 | 0.0483750 | 0.9101475 | 0 | 0 | 0 | 0 | 256 | 21.59765625 |
| 0.001 | 0.0043718758 | 0.0544023 | 0.8986500 | 0 | 0 | 0 | 0 | 256 | 21.59765625 |
| 0.003 | 0.0053641624 | 0.0663434 | 0.8760875 | 0 | 0 | 0 | 0 | 256 | 21.59765625 |
| 0.01 | 0.0088371658 | 0.1069713 | 0.8014732 | 0 | 0 | 0 | 0 | 256 | 21.59765625 |
| 0.03 | 0.0187600327 | 0.2136365 | 0.6213996 | 0 | 0 | 0 | 0 | 256 | 20.59765625 |
| 0.1 | 0.0534900665 | 0.4966833 | 0.2545629 | 0 | 0 | 0 | 91 | 256 | 16.65234375 |
| 0.3 | 0.1527187347 | 0.8605505 | 0.0195821 | 3 | 149 | 256 | 256 | 256 | 4.234375 |
| 1 | 0.5000190735 | 0.9985936 | 0.000002064 | 256 | 256 | 256 | 256 | 256 | 1.0 |

The observed surface is therefore strongly dose-dependent at the frozen horizon, with the preregistered recovery gate first crossed at the tested value `lambda=0.3`.

AA-002 does not classify this descriptive transition as a topological knee.

## Exact quota-matched random-placement control

For every seed and lambda, cumulative pre-shift B authority was matched between the informed and random-placement arms.

Maximum absolute quota mismatch:

\[
1.4210854715202004\times10^{-14},
\]

well inside the frozen tolerance

\[
10^{-10}.
\]

Therefore

\[
\boxed{A_{pre}^{random}(B)=A_{pre}^{informed}(B)}
\]

was satisfied to numerical precision.

### Placement effects

At low authority doses (`lambda <= 0.03`), informed and random placement had identical censored recovery latency on all 256 seeds.

At `lambda=0.1`:

- random placement had `+0.0154564710` greater mean cumulative B update;
- random placement had `-0.0153925286` lower mean B pre-shift error;
- random was faster on `31/256` seeds and tied on `225/256`;
- mean random-minus-informed recovery latency was `-0.12109375` steps.

At `lambda=0.3`:

- random placement had `+0.0113582094` greater mean cumulative B update;
- random placement had `-0.0030567320` lower mean B pre-shift error;
- random was faster on `244/256` seeds and tied on `12/256`;
- random was slower on `0/256` seeds;
- mean random-minus-informed recovery latency was `-0.9765625` steps.

At `lambda=1`, recovery latency was identical (`1` step) despite a very small update-dose difference.

The secondary result therefore establishes, in this frozen toy, that

\[
\boxed{A_{same}\not\Rightarrow U_{same}.}
\]

Where recovery diverged, the random-placement arm also received greater realized B update influence and entered the shift with lower B error. AA-002 therefore does **not** isolate a deeper timing/path effect at equal realized update dose.

It does show that the temporal placement of an exactly matched authority budget can change the realized developmental update dose because gradients are state-dependent.

## Execution custody

The confirmatory block was first executed from the exact frozen executable bytes. The local executable's Git blob hash matched the frozen repository blob:

`3c674342ba0cfc9f9ecfdb3bbb6dca5ff38ca40b`.

A post-open GitHub Actions reproduction then verified that same blob before rerunning the frozen confirmatory block.

Reproduction workflow run:

`32582018804`

Reproduction job:

`97052712318`

Hosted artifact:

`authority-allocation-002-result` / artifact ID `9478041280`

Artifact ZIP digest:

`sha256:55647de544ab5b08136c0dbb3aa5277353815db634f04461f3c048b5d55bc5a2`

The uncompressed hosted result JSON was byte-identical to the first confirmatory execution. Both have SHA-256:

`b6d2b73c9b36e9b602567e3f14634609e8e50aca86ea6ac0bba2b62eaa8aff25`

## Narrow claim ceiling

AA-002 establishes only the following facts in the frozen synthetic construction at `T_pre=128`:

1. Increasing protected B authority produces a strong finite-horizon change in realized B competence and later recoverability.
2. On the frozen grid and deadline, the first tested authority-mixture value meeting the 95% recovery criterion is `lambda=0.3`.
3. Exact equality of cumulative authority does not guarantee equality of realized update influence; authority placement can change update dose through state-dependent gradients.

AA-002 does **not** establish:

- that `lambda=0.3` is a continuum or universal threshold;
- that any nonzero aperture is sufficient;
- that `lambda_T^star T` is constant;
- that cumulative update dose is a universal sufficient statistic;
- a topology of developmental accessibility;
- that released continuous XM exhibits this behavior;
- any OpenCore mechanism or solution.

Those questions remain downstream of this result.