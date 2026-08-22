# AUTHORITY-ALLOCATION-003a — Prospective Freeze

## Status

`FROZEN_UNRUN`

This is a prospective quotient-sufficiency assay derived from the exact construction witness recorded in `experiments/authority_allocation_003a_calibration/AA003A_CONSTRUCTION_CALIBRATION_RESULT.md`.

**Do not execute the post-boundary future until this specification and the executable are frozen in Git.**

## Scientific question

The assay asks whether two developmental histories that are observationally identical under the supplied repair-state quotient can nevertheless have different future repairability under a literally identical future.

Primary quotient:

\[
O_a(H)=(\theta(T),L(T)).
\]

Nested stronger quotient, available from the same witness:

\[
O_b(H)=(\theta(T),L(T),U_{pre}).
\]

The assay tests the single paired witness

\[
O_a(H_1)=O_a(H_2),\qquad O_b(H_1)=O_b(H_2),
\]

while the construction mechanism leaves different persistent optimizer state.

Momentum is a witness-construction mechanism only. It is not named in advance as the missing repair-relevant coordinate.

## Frozen developmental witness

Use exact rational arithmetic throughout.

Dynamics before the boundary:

\[
g_t=2(\theta_t-1),
\]

\[
m_{t+1}=\frac{9}{10}m_t+A_tg_t,
\]

\[
\theta_{t+1}=\theta_t-\frac1{20}m_{t+1},
\]

with

\[
\theta_0=0,\qquad m_0=0.
\]

The two frozen authority histories are:

\[
H_1=(\tfrac12,1),
\qquad
H_2=(1,0).
\]

The executable must assert exactly, before any future is allowed to run:

\[
\theta_1(T)=\theta_2(T)=\frac{19}{100},
\]

\[
L_1(T)=L_2(T)=\frac{6561}{10000},
\]

\[
U_{pre,1}=U_{pre,2}=\frac{19}{100},
\]

and

\[
m_1(T)=-\frac{14}{5}\neq-\frac95=m_2(T).
\]

If any equality or inequality above fails, classification is `APPARATUS_FAILURE` and no scientific interpretation is allowed.

## Literally identical frozen future

At the boundary, both histories are subjected to the exact same deterministic future. There is no stochastic proposal process in this specimen.

Frozen future world:

\[
W_{T:\infty}:\quad y^{future}=-1
\]

for every post-boundary step.

Frozen proposal stream:

\[
P_{T:\infty}=\varnothing
\]

for both histories. No candidate sampling or selection occurs after the boundary.

Frozen authority schedule:

\[
A_t=1
\]

for every post-boundary step and for both histories.

Frozen optimizer hyperparameters:

\[
\beta=\frac9{10},
\qquad
\eta=\frac1{20}.
\]

The carried optimizer state is not reset at the boundary. Each history begins the common future with its own terminal optimizer state produced by the frozen developmental witness.

Future gradient and update rule:

\[
g_t=2(\theta_t-y^{future}),
\]

\[
m_{t+1}=\frac9{10}m_t+g_t,
\]

\[
\theta_{t+1}=\theta_t-\frac1{20}m_{t+1}.
\]

Post-boundary horizon:

\[
D=64.
\]

Recovery threshold:

\[
|\theta_t-y^{future}|\le\frac1{10}.
\]

Recovery latency is

\[
T_{rec}=\min\{d\in\{1,\ldots,64\}:|\theta_{T+d}-y^{future}|\le\tfrac1{10}\}.
\]

If recovery does not occur by step 64, use the frozen censored value

\[
T_{rec}=65.
\]

## Primary comparison

The only primary scientific comparison is

\[
\boxed{T_{rec}(H_1)\stackrel{?}{=}T_{rec}(H_2).}
\]

The full exact post-boundary trajectories may be logged for audit, but no alternative outcome metric may replace the frozen recovery-latency comparison after execution.

## Allowed classifications

### `REPAIR_QUOTIENT_COUNTEREXAMPLE_IN_FROZEN_WITNESS`

Use iff

\[
T_{rec}(H_1)\neq T_{rec}(H_2).
\]

Because the same witness satisfies both quotient equalities, this result earns only the construction-local statements:

\[
(\theta,L)\text{ is insufficient for repairability in this frozen witness,}
\]

and

\[
(\theta,L,U_{pre})\text{ is also insufficient for repairability in this frozen witness.}
\]

It does **not** identify momentum as the generally correct missing coordinate.

### `NO_QUOTIENT_COUNTEREXAMPLE_IN_FROZEN_WITNESS`

Use iff

\[
T_{rec}(H_1)=T_{rec}(H_2).
\]

This means only that this single constructed witness does not falsify either supplied quotient under the frozen future. It does **not** prove global quotient sufficiency or establish that hidden optimizer state is generally irrelevant.

### `APPARATUS_FAILURE`

Use if any frozen witness identity, future identity, arithmetic invariant, or execution contract fails.

## Causal interpretation guardrail

The intended causal structure is

\[
O(H_1)=O(H_2),
\qquad
F_1=F_2,
\qquad
R(H_1)\stackrel{?}{=}R(H_2).
\]

The future is exogenous and deterministic. Therefore the assay must not introduce any path

\[
h_T\to A_{T:\infty}
\]

or

\[
h_T\to P_{T:\infty}.
\]

Any such dependence is apparatus failure rather than evidence about quotient sufficiency.

## Claim ceiling

AA-003a may establish only a counterexample or non-counterexample for this exact deterministic momentum witness and frozen future.

It does not establish:

- a general law of optimizer-state insufficiency;
- that momentum is the missing repair-relevant coordinate;
- that `U_pre` is generally sufficient or insufficient;
- any topology claim;
- any claim about released continuous XM;
- any OpenCore mechanism, implementation, or solution.

## Execution state

At freeze time:

\[
\boxed{\texttt{AA-003a = FROZEN, RECOVERY UNOPENED}.}
\]
