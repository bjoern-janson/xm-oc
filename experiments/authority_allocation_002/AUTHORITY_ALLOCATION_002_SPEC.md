# AUTHORITY-ALLOCATION-002

## Status

**PROSPECTIVELY FROZEN — CONFIRMATORY BLOCK UNOPENED.**

AUTHORITY-ALLOCATION-002 (AA-002) is a synthetic successor to AA-001. It remains a foreign-organism mechanism assay: it does **not** modify XM's shared training kernel, import OpenCore machinery, or make a claim about released continuous XM.

AA-001 established in its frozen toy that high proposal coverage need not imply update authority:

\[
\boxed{C\not\Rightarrow A.}
\]

AA-002 asks only what happens downstream of that separation at a fixed developmental horizon:

\[
\boxed{
C\;(\text{proposal coverage})
\rightarrow
A\;(\text{authority allocation})
\rightarrow
U\;(\text{realized update influence})
\rightarrow
R\;(\text{future recoverability}).
}
\]

It does **not** test whether any nonzero authority aperture is topologically sufficient. That is reserved for a later experiment.

## Frozen inherited world

AA-002 inherits the AA-001 synthetic world and learning parameters unchanged:

- target \(y\in\{-1,+1\}\), equiprobable;
- stable feature \(s=y\) at all times;
- shortcut feature \(c=y\) before the shift and \(c=-y\) after the shift;
- region A predictor \(\hat y_A=\theta_A c\);
- region B predictor \(\hat y_B=\theta_B s\);
- initial competence \(\theta_A(0)=1,\theta_B(0)=0\);
- squared loss \(L_r=(\hat y_r-y)^2\);
- learning rate \(\eta=0.05\);
- \(T_{pre}=128\) pre-shift steps;
- 32 post-shift recovery steps;
- \(K=8\) proposal slots;
- each slot iid with \(P(A)=P(B)=0.5\);
- recovery criterion \(|\theta_B-1|\le0.1\).

For every seed, every AA-002 arm receives the exact same target stream and the exact same K=8 proposal stream.

## Authority sweep

The primary AA-002 intervention is the protected-authority mixture

\[
\boxed{
A_i^{(\lambda)}
=(1-\lambda)\mathbf 1[i=i^\star]+\frac{\lambda}{K},
}
\]

where

\[
i^\star=\arg\min_j L_j.
\]

The total candidate authority remains exactly one per step:

\[
\sum_i A_i^{(\lambda)}=1.
\]

Thus AA-002 redistributes a fixed update-authority budget; it does not add training steps or gradient budget.

The frozen geometric grid is

\[
\boxed{
\lambda\in
\{0,10^{-3},3\times10^{-3},10^{-2},3\times10^{-2},10^{-1},0.3,1\}.
}
\]

Endpoints recover familiar controls:

- \(\lambda=0\): hard winner-take-all XM-like allocation;
- \(\lambda=1\): balanced candidate-slot allocation.

No additional softmax-temperature sweep is part of AA-002.

## Operational quantities

For region B at step \(t\):

### Proposal coverage

\[
C_t(B)=\mathbf 1[B\text{ appears in the candidate set}].
\]

AA-002 also records candidate-slot frequency.

### Authority allocation

\[
A_t(B)=\sum_{i:r_i=B}A_{i,t}.
\]

Primary pre-shift summaries are cumulative and mean B authority:

\[
A_{pre}(B)=\sum_{t<T_{pre}}A_t(B),
\qquad
\bar A_{pre}(B)=\frac{A_{pre}(B)}{T_{pre}}.
\]

### Realized update influence

Because the synthetic regions have separate competence coordinates, B's direct realized update is observable without attribution ambiguity:

\[
U_t(B)=|\Delta\theta_B(t)|.
\]

AA-002 records

\[
U_{pre}(B)=\sum_{t<T_{pre}}U_t(B)
\]

and its mean.

### Future recoverability

\[
T_{rec}(B)=\min\{d\ge1:|\theta_B(T_{pre}+d)-1|\le0.1\}.
\]

Unrecovered runs are censored at 33 for summary statistics.

Frozen recovery deadlines remain

\[
\{1,4,8,16,32\}.
\]

## Primary estimand: finite-horizon authority threshold on the frozen grid

AA-002 does not estimate a continuum threshold. It reports the smallest tested grid value satisfying the frozen deadline/reliability criterion:

\[
\boxed{
\hat\lambda^{\star}_{T=128,\,grid}
=
\min\left\{
\lambda\in\Lambda:
\Pr(T_{rec}\le16\mid\lambda)\ge0.95
\right\}.
}
\]

With 256 confirmatory seeds, the empirical gate is at least 244/256 recoveries by post-shift step 16.

If no grid point meets the criterion, the result is reported as `NONE_ON_GRID`. If \(\lambda=0\) already meets it, the estimate is 0. This object is explicitly finite-horizon and grid-relative.

## Primary readout: full dose/response surface

For every \(\lambda\), AA-002 reports

\[
\boxed{
(\bar C_B,\bar A_B,\bar U_B,T_{rec},P(T_{rec}\le d))
}
\]

rather than reducing the experiment to a single hard-vs-soft comparison.

The pre-specified interpretations are descriptive:

- a gradual recovery change across \(\lambda\) is consistent with an ordinary finite-horizon dose response;
- a narrow transition region is consistent with a finite-horizon knee/threshold;
- matched authority with different realized update or recovery implicates timing/placement rather than authority amount alone.

AA-002 does **not** promote any of those patterns to a topological claim.

## Secondary control: exact quota-matched random placement

A naive "random winner with the same expected B authority" is non-identifying in this toy because pre-shift A has exactly zero loss. The informed winner therefore selects B only when no A candidate is available.

AA-002 instead uses an exact per-seed quota-matched placement control.

For each seed and \(\lambda\):

1. Run the informed \(A_i^{(\lambda)}\) arm and compute its total pre-shift B authority quota

\[
Q_B(\lambda)=\sum_{t<T_{pre}}A_t^{informed}(B).
\]

2. Give the random-placement arm the **same target stream, same proposal stream, same \(\lambda\), and exactly the same cumulative pre-shift B authority quota**.

3. All-B steps necessarily allocate B authority 1; all-A steps allocate B authority 0.

4. The remaining B authority quota is placed on B-exposed mixed A/B steps using a deterministic seed-specific shuffle independent of comparative loss. Whole units are assigned to randomly chosen eligible steps, with at most one fractional remainder step. A receives the complementary authority so total authority remains 1 per step.

5. After the environmental shift, the random-placement arm returns to the same informed \(A_i^{(\lambda)}\) rule as its matched informed arm. Therefore the only manipulation between the pair is **where the same pre-shift B authority quota was spent**.

This is a region-level authority-placement control, not a proposed XM training rule.

The load-bearing apparatus check is

\[
\boxed{
A_{pre}^{random}(B)=A_{pre}^{informed}(B)
}
\]

within numerical tolerance for every paired seed and \(\lambda\).

The random placement RNG may depend on seed and \(\lambda\) index, but not on losses, model parameters, labels, recovery outcomes, or future post-shift state.

## What the quota control can identify

At matched cumulative pre-shift authority:

- similar \(U\) and recovery supports authority **amount** as the dominant variable in this toy;
- different \(U\) shows that authority placement changes realized update dose through state-dependent gradients;
- similar \(A\) and \(U\) but different recovery would implicate a still-deeper timing/path effect.

AA-002 reports these quantities separately and does not infer one from another.

## Confirmatory seed freeze

AA-001 confirmatory seeds `10000..10255` are already opened and are therefore not reused.

AA-002 confirmatory seeds are prospectively frozen as

\[
\boxed{20000,20001,\ldots,20255}
\]

for 256 paired seeds.

Development/debugging may use only seeds below 10000. The confirmatory block must not be executed until this specification, executable, and manual execution workflow are committed together and the scientific freeze SHA is recorded.

## Result status / classification

AA-002 is a surface-mapping experiment, not a broad winner declaration.

Allowed confirmatory statuses are:

- `FINITE_HORIZON_AUTHORITY_SURFACE_RECORDED`
- `APPARATUS_FAILURE`

The result must report \(\hat\lambda^{\star}_{T=128,grid}\) descriptively; it must not invent a post-hoc "sharp knee" classification.

`APPARATUS_FAILURE` is mandatory if any paired informed/random run fails exact pre-shift B-authority quota matching beyond `1e-10`, if authority leaves `[0,1]`, or if per-step total authority differs from 1 beyond numerical tolerance.

## Claim ceiling

AA-002 can establish only a finite-horizon map from protected authority allocation through realized update influence to later recoverability in this frozen synthetic construction:

\[
\boxed{
A\rightarrow U\rightarrow R
\quad\text{at}\quad T_{pre}=128.
}
\]

It cannot establish:

- that any nonzero authority aperture is sufficient;
- that \(\lambda_T^\star T\) is constant;
- that cumulative dose is the only relevant variable;
- a general topology of developmental accessibility;
- that released continuous XM exhibits this behavior;
- that OpenCore supplies a solution.

A later AA-003 may vary developmental horizon and test dose-collapse/topology hypotheses. AA-002 must not do so.