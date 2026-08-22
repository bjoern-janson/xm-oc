# AUTHORITY-ALLOCATION-003r — Prospective Independent-Witness Replication Freeze

## Status

`FROZEN_UNRUN`

This assay is derived from the exact independent construction witness recorded in `experiments/authority_allocation_003r_calibration/AA003R_CONSTRUCTION_CALIBRATION_RESULT.md`.

**Do not execute the post-boundary future until this specification and the executable are frozen in Git.**

## Scientific question

AA-003a established an existence counterexample to the supplied repair-state quotient using a momentum-based witness construction.

AA-003r asks only whether quotient failure replicates under a structurally different witness generator while preserving the same supplied quotient collision and a literally identical future.

The supplied quotient is

\[
O_b(H)=(\theta(T),L(T),U_{pre}).
\]

The frozen witness satisfies

\[
O_b(H_1)=O_b(H_2)
\]

while retaining distinct internal parameter states under a redundant model parameterization.

The hidden parameterization is a witness-construction mechanism only. It is not named in advance as the generally correct missing repair-relevant coordinate.

## Independent witness mechanism

There is no momentum and no optimizer memory.

Visible scalar model state:

\[
\theta=ab.
\]

Developmental target:

\[
y^{pre}=0.
\]

Loss:

\[
L=(\theta-y^{pre})^2.
\]

Parameter gradients:

\[
\frac{\partial L}{\partial a}=2(\theta-y^{pre})b,
\qquad
\frac{\partial L}{\partial b}=2(\theta-y^{pre})a.
\]

Learning rate:

\[
\eta=\frac1{20}.
\]

Initial hidden state:

\[
(a_0,b_0)=(1,1).
\]

Developmental update-routing actions are:

- `A_ONLY`: update `a`, hold `b` fixed;
- `B_ONLY`: update `b`, hold `a` fixed;
- `BOTH`: update both parameters.

## Frozen developmental witness

The two exact developmental histories are:

\[
H_1=(\texttt{A_ONLY},\texttt{BOTH}),
\]

\[
H_2=(\texttt{BOTH},\texttt{A_ONLY}).
\]

The executable must assert exactly, before any future is allowed to run:

\[
(a,b)_1(T)=\left(\frac{81}{100},\frac{919}{1000}\right),
\]

\[
(a,b)_2(T)=\left(\frac{8271}{10000},\frac9{10}\right),
\]

with distinct, non-coordinate-swapped hidden states.

The supplied quotient must collide exactly:

\[
\theta_1(T)=\theta_2(T)=\frac{74439}{100000},
\]

\[
L_1(T)=L_2(T)=\frac{5541164721}{10000000000},
\]

and, with

\[
U_{pre}=\sum_{t<T}|\Delta\theta_t|,
\]

\[
U_{pre,1}=U_{pre,2}=\frac{25561}{100000}.
\]

If any frozen witness identity fails, classification is `APPARATUS_FAILURE` and no scientific interpretation is allowed.

## Literally identical frozen future

At the boundary, both histories receive the same deterministic future.

Future target:

\[
y^{future}=1
\]

at every post-boundary step.

Proposal stream:

\[
P_{T:\infty}=\varnothing.
\]

There is no candidate sampling or adaptive selection.

Future update routing:

\[
M_t=(1,1)
\]

for every post-boundary step, meaning both `a` and `b` receive the standard gradient update.

Future optimizer:

- stateless gradient descent;
- no momentum;
- no optimizer memory;
- learning rate

\[
\eta=\frac1{20}.
\]

The hidden parameter states `(a,b)` produced by the developmental histories are carried across the boundary and are not reset or canonicalized.

At each future step:

\[
\theta_t=a_tb_t,
\]

\[
g^a_t=2(\theta_t-1)b_t,
\qquad
g^b_t=2(\theta_t-1)a_t,
\]

\[
a_{t+1}=a_t-\frac1{20}g^a_t,
\qquad
b_{t+1}=b_t-\frac1{20}g^b_t.
\]

Post-boundary horizon:

\[
D=64.
\]

Recovery threshold:

\[
|\theta_t-1|\le\frac1{10}.
\]

Recovery latency:

\[
T_{rec}=\min\{d\in\{1,\ldots,64\}:|\theta_{T+d}-1|\le\tfrac1{10}\}.
\]

If recovery does not occur by step 64, use censored latency

\[
T_{rec}=65.
\]

## Primary comparison

The only primary scientific comparison is

\[
\boxed{T_{rec}(H_1)\stackrel{?}{=}T_{rec}(H_2).}
\]

Exact future trajectories may be logged for audit, but no alternative outcome metric may replace this comparison after execution.

## Allowed classifications

### `REPAIR_QUOTIENT_FAILURE_REPLICATED_IN_INDEPENDENT_WITNESS`

Use iff

\[
T_{rec}(H_1)\neq T_{rec}(H_2).
\]

This earns only the statement that AA-003a's quotient-failure pattern is witnessed again under this structurally distinct redundant-parameterization construction.

Together with AA-003a, it supports the bounded statement that the supplied quotient

\[
(\theta,L,U_{pre})
\]

has failed in more than one structurally distinct witness construction.

It does not identify the correct finer quotient.

### `NO_REPLICATION_IN_INDEPENDENT_WITNESS`

Use iff

\[
T_{rec}(H_1)=T_{rec}(H_2).
\]

This means only that quotient failure did not replicate in this second witness. AA-003a remains a valid existence counterexample. This outcome does not prove the supplied quotient sufficient.

### `APPARATUS_FAILURE`

Use if any frozen witness identity, future identity, exact-arithmetic invariant, or execution contract fails.

## Causal guardrail

The intended structure is

\[
O_b(H_1)=O_b(H_2),
\qquad
F_1=F_2,
\qquad
R(H_1)\stackrel{?}{=}R(H_2).
\]

The future is exogenous and deterministic. The hidden parameter state may affect future response only through the fixed model dynamics; it may not change future target, update routing, proposals, learning rate, horizon, or recovery criterion.

## Claim ceiling

AA-003r may establish only replication or non-replication for this exact deterministic independent witness and future.

It does not establish:

- that redundant parameterization is the generally missing repair-relevant coordinate;
- a general law of hidden-state insufficiency;
- the correct finer repair-state quotient;
- any topology claim;
- any claim about released continuous XM;
- any OpenCore mechanism, implementation, or solution.

## Execution state

At freeze time:

\[
\boxed{\texttt{AA-003r = FROZEN, RECOVERY UNOPENED}.}
\]
