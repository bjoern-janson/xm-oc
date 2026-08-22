# AUTHORITY-ALLOCATION-003r — Prospective Computational-Equivalence Repair Freeze

## Status

`FROZEN_UNRUN`

This is **not a new scientific experiment**. It is a second apparatus repair of the exact AA-003r scientific specimen frozen at:

`4f505a5ac33f5765ee4bcf2a85a989668f6ac4d8`

It is layered on the overflow-safe serialization reproduction freeze:

`15e505c23ae092d29c98adfbb98bf49d13fb2654`

The earlier executions remain in the ledger unchanged:

- original AA-003r: `APPARATUS_FAILURE` at decimal integer serialization;
- serialization-repaired reproduction: `APPARATUS_FAILURE` at execution-time tractability.

Neither failure is scientific evidence for or against quotient replication.

The scientific invariant for this repair is:

\[
\boxed{\Delta_{scientific}=0.}
\]

The only admissible implementation change is:

\[
\boxed{\Delta_{implementation}\subseteq\text{control flow / bounded audit representation}.}
\]

**Do not execute recovery until the computational-equivalence proof and executable diff audit below are complete and this artifact is frozen in Git.**

## Inherited scientific specimen — unchanged

All scientific objects are inherited exactly.

Visible scalar state:

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

Learning rate:

\[
\eta=\frac1{20}.
\]

Initial hidden state:

\[
(a_0,b_0)=(1,1).
\]

Developmental histories:

\[
H_1=(\texttt{A_ONLY},\texttt{BOTH}),
\qquad
H_2=(\texttt{BOTH},\texttt{A_ONLY}).
\]

Exact supplied quotient collision:

\[
\theta_1(T)=\theta_2(T)=\frac{74439}{100000},
\]

\[
L_1(T)=L_2(T)=\frac{5541164721}{10000000000},
\]

\[
U_{pre,1}=U_{pre,2}=\frac{25561}{100000}.
\]

Thus the supplied quotient remains:

\[
O_b(H)=(\theta(T),L(T),U_{pre}).
\]

The common future remains literally identical and deterministic.

Future target:

\[
y^{future}=1.
\]

Proposal stream:

\[
P_{T:\infty}=\varnothing.
\]

Future update routing:

\[
M_t=(1,1).
\]

Future recurrence remains exactly:

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

Post-boundary horizon remains:

\[
D=64.
\]

Recovery predicate remains:

\[
C(x_t)=\mathbf 1\left[|\theta_t-1|\le\frac1{10}\right].
\]

Recovery latency remains:

\[
T_{rec}=\min\{d\in\{1,\ldots,64\}:C(x_{T+d})=1\},
\]

with censored value:

\[
T_{rec}=65
\]

iff no hit occurs by step 64.

The sole primary scientific comparison remains:

\[
\boxed{T_{rec}(H_1)\stackrel{?}{=}T_{rec}(H_2).}
\]

## Original full-horizon evaluator semantics

Let:

\[
x_0=x_T,
\qquad
x_d=f(x_{d-1}),\quad d=1,\ldots,64,
\]

where \(f\) is the exact frozen recurrence above.

The prior evaluator generated all 64 states, stored the first \(d\) for which \(C(x_d)=1\), and nevertheless continued computing and serializing later states.

Its scientific output functional is therefore:

\[
T_{full}=
\begin{cases}
\min\{d\le64:C(x_d)=1\}, & \text{if a hit exists},\\
65, & \text{otherwise}.
\end{cases}
\]

Post-hit states cannot alter \(T_{full}\).

## Repaired exact first-hit evaluator

The repaired evaluator computes the same recurrence prefix:

\[
x_d=f(x_{d-1})
\]

using the same exact `Fraction` arithmetic.

After each newly generated state, it applies the same frozen predicate \(C\).

Its control flow is:

\[
C(x_d)=1\Rightarrow\text{return }d.
\]

If no hit occurs for \(d=1,\ldots,64\), it returns 65.

No state after the first hit is computed because those states are not arguments of the frozen recovery-latency functional once the minimum has been attained.

## Prospective computational-equivalence proof

Define the repaired output:

\[
T_{first}=\operatorname{FirstHit}_{64}(f,x_T,C).
\]

We require:

\[
\boxed{T_{first}=T_{full}.}
\]

### Prefix identity

Both evaluators begin from the same exact \(x_0=x_T\) and apply the same deterministic recurrence \(f\).

By induction on \(d\):

1. base: both have identical \(x_0\);
2. induction step: if both have identical \(x_{d-1}\), applying identical \(f\) produces identical \(x_d\).

Therefore every state computed by the repaired evaluator before termination is exactly the corresponding prefix state of the full evaluator.

### Hit case

Suppose the first recovery hit occurs at \(d^*\le64\).

Then:

\[
C(x_d)=0\quad\forall d<d^*,
\qquad
C(x_{d^*})=1.
\]

The full evaluator records \(d^*\) and later computations cannot change the stored minimum.

The repaired evaluator reaches the identical \(x_{d^*}\), observes the identical predicate value, and returns \(d^*\).

Hence:

\[
T_{first}=T_{full}=d^*.
\]

### Censored case

If:

\[
C(x_d)=0\quad\forall d=1,\ldots,64,
\]

then both evaluators compute the same 64-state prefix and return the same censored value:

\[
T_{first}=T_{full}=65.
\]

Thus for every frozen boundary state:

\[
\boxed{
\operatorname{FirstHit}_{64}(f,x_T,C)
=
\min\{d\le64:C(f^d(x_T))=1\}
}
\]

with 65 when the set is empty.

This equivalence does not depend on the AA-003r outcome.

## Bounded exact audit representation

The repaired evaluator performs no per-step serialization during future computation.

All recurrence state remains raw exact `Fraction` objects until the primary latency has been determined.

For a recovery hit at step \(d\), the audit record contains only:

\[
\boxed{x_T,\ T_{rec}=d,\ x_{d-1},\ x_d.}
\]

`x_T` is already present in the frozen boundary record. The future record adds exact `pre_hit_state` and `hit_state` objects.

This permits direct audit of:

\[
C(x_{d-1})=0,
\qquad
C(x_d)=1.
\]

For a censored result, the evaluator records only the exact final state \(x_{64}\) in addition to the boundary state and `T_rec=65`.

All rational audit values retain the previously frozen structured hexadecimal numerator/denominator representation. There is:

- no float conversion;
- no rounding;
- no truncation;
- no changed recurrence;
- no changed horizon;
- no changed recovery predicate.

## Required executable-diff audit

Before the repaired reproduction may be opened, compare the repaired executable against the serialization-repair freeze at:

`15e505c23ae092d29c98adfbb98bf49d13fb2654`

and verify:

1. all constants defining `H1`, `H2`, targets, learning rate, horizon, censoring, recovery tolerance, action masks, and expected boundary identities are unchanged;
2. `developmental_run`, `validate_frozen_witness`, and `future_contract` remain scientifically unchanged;
3. the exact update equations inside `run_frozen_future` are unchanged;
4. the recovery comparison remains `abs_error <= tol` after each exact recurrence step;
5. the classification logic comparing the two recovery latencies is unchanged;
6. the only future-evaluator semantic changes are first-hit termination and removal of scientifically irrelevant full-trajectory logging;
7. no float path or approximate arithmetic is introduced;
8. no recovery execution occurs during the equivalence audit or freeze.

Failure of any item invalidates this repair freeze.

## Allowed classifications after execution

The scientific classifications remain inherited unchanged.

### `REPAIR_QUOTIENT_FAILURE_REPLICATED_IN_INDEPENDENT_WITNESS`

Use iff:

\[
T_{rec}(H_1)\neq T_{rec}(H_2).
\]

### `NO_REPLICATION_IN_INDEPENDENT_WITNESS`

Use iff:

\[
T_{rec}(H_1)=T_{rec}(H_2).
\]

### `APPARATUS_FAILURE`

Use if any frozen witness identity, future identity, exact-arithmetic invariant, execution contract, first-hit equivalence contract, or bounded exact serialization path fails.

## Claim ceiling

This computational-equivalence repair may establish only replication, non-replication, or apparatus failure for the exact AA-003r scientific specimen.

It does not establish:

- a new scientific specimen;
- a new recovery metric;
- a new horizon;
- a new hidden-state mechanism;
- the correct finer repair-state quotient;
- any topology claim;
- any released continuous-XM claim;
- any OpenCore mechanism, implementation, or solution.

## Execution state

At this computational-equivalence repair freeze:

\[
\boxed{\texttt{AA-003r COMPUTATIONAL-EQUIVALENCE REPAIR = FROZEN, RECOVERY UNOPENED}.}
\]
