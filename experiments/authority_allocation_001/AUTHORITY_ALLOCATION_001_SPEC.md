# AUTHORITY-ALLOCATION-001

## Status

Prospective synthetic mechanism assay. This experiment is intentionally external to OpenCore and intentionally does **not** modify XM's shared training kernel. It tests one narrow question before any attempt to touch continuous image/video XM.

## Question

Does winner-take-all candidate selection suppress an initially weak but later consequential coupling region **despite high candidate exposure**, relative to matched balanced or soft update allocation?

The object under test is the separation

\[
\boxed{\text{proposal}\neq\text{selection}\neq\text{update authority}}.
\]

This assay is an existence/mechanism test only. A positive result does **not** establish that the released continuous XM models suffer this pathology, and it does not validate any OpenCore mechanism.

## Synthetic world

Each training example has target

\[
y\in\{-1,+1\}
\]

with equal probability and two candidate coupling regions:

- **Region A — shortcut coupling**: predictor \(\hat y_A=\theta_A c\).
- **Region B — stable coupling**: predictor \(\hat y_B=\theta_B s\).

The stable feature is always

\[
s=y.
\]

Before the environmental shift,

\[
c=y.
\]

After the shift,

\[
c=-y.
\]

Thus A is initially a perfect shortcut but becomes wrong after the shift; B is valid across both phases.

Initial competence is deliberately asymmetric:

\[
\theta_A(0)=1,\qquad \theta_B(0)=0.
\]

This asymmetry is part of the frozen construction: the assay asks whether a currently weak but structurally valid region can be denied enough update authority to create future recovery debt.

## Training loss

For each candidate region \(r\in\{A,B\}\),

\[
L_r=(\hat y_r-y)^2.
\]

Learning rate:

\[
\eta=0.05.
\]

Pre-shift training length: 128 steps.

Post-shift recovery window: 32 steps.

## Candidate proposal process

For all regimes, proposal slots are drawn iid with

\[
P(B)=P(A)=0.5.
\]

The maximum candidate set has

\[
K=8.
\]

For every seed and step, all regimes share the same target stream. The three \(K=8\) regimes share the exact same eight proposal slots. The \(K=1\) baseline uses slot 0 from that same stream.

This pairing is load-bearing: differences among hard, balanced, and soft regimes cannot be attributed to different candidate exposure histories.

## Frozen allocation regimes

### 1. K=1

One candidate is proposed and receives all update authority.

### 2. hard-XM

Eight candidates are proposed. The candidate with minimum current loss receives all update authority:

\[
w_i=\mathbf 1[i=\arg\min_j L_j].
\]

### 3. balanced

Eight candidates are proposed. Candidate slots receive equal update weight:

\[
w_i=1/8.
\]

This is an authority-allocation control, not a claim about a practical generative-model training rule.

### 4. soft-XM

Eight candidates are proposed and receive graded authority

\[
w_i=\frac{\exp(-L_i/\tau)}{\sum_j \exp(-L_j/\tau)},
\qquad \tau=0.5.
\]

## Operational authority measures

For region B at step \(t\):

### Candidate exposure

B is exposed when at least one proposal slot belongs to B.

### Authority mass

\[
A_t(B)=\sum_{i:r_i=B}w_i.
\]

### Realized update magnitude

\[
U_t(B)=|\Delta\theta_B|.
\]

The assay therefore distinguishes a region being present in the candidate set from being allowed to causally alter the parameter state.

## Primary outcome: future recoverability

Region B is considered recovered once

\[
|\theta_B-1|\le 0.1.
\]

Define post-shift recovery latency

\[
T_{rec}(B)=\min\{d\ge1: |\theta_B(t_{shift}+d)-1|\le0.1\}.
\]

If B does not recover within 32 post-shift steps, latency is censored at 33 for paired summary statistics.

The primary estimand is

\[
\boxed{
\Delta T
=
T_{rec}^{hard}-T_{rec}^{balanced}
}.
\]

Secondary paired estimands compare hard-XM against K=1 and soft-XM.

## Mechanism checks

A result is interpretable as authority starvation only if all of the following hold on the confirmatory block:

1. **High proposal reach under hard-XM**: mean pre-shift B exposure-step rate \(\ge0.95\).
2. **Low hard authority despite exposure**: mean pre-shift B authority mass \(\le0.02\).
3. **Matched-proposal comparator**: balanced and soft use exactly the same K=8 proposal stream as hard-XM.
4. **Recovery debt**: hard-XM is slower than balanced on at least 95% of paired confirmatory seeds and the mean paired latency difference is at least 8 steps.

If any of these gates fail, the strong authority-starvation classification is not earned.

## Confirmatory seed freeze

Development used only seeds 0-255 while choosing the toy parameters and thresholds above.

The confirmatory block is frozen as:

\[
\boxed{10000,10001,\ldots,10255}
\]

for 256 paired seeds.

The confirmatory block must not be inspected until this specification and the executable are committed together on the assay branch.

## Allowed result classifications

- `AUTHORITY_STARVATION_SUPPORTED_IN_FROZEN_TOY`
- `AUTHORITY_STARVATION_NOT_SUPPORTED`
- `APPARATUS_FAILURE`

No result from this assay may be promoted to a claim about continuous XM, diffusion/flow training, OpenCore, representation invention, or general learning systems without a separate successor experiment.

## Scope boundary

The coupling regions here are explicit synthetic regions with directly observable competence coordinates. Real XM uses ephemeral latent/noise samples and shared neural parameters. This toy intentionally strips those complications away to test the allocation topology first.

A positive result therefore establishes only:

\[
\boxed{
\text{winner-take-all model-dependent allocation can create recoverability debt
under high proposal exposure in this frozen construction.}
}
\]

That is the entire claim ceiling.