# AUTHORITY-ALLOCATION-003r — Prospective Reproduction Repair Freeze

## Status

`FROZEN_UNRUN`

This is **not a new scientific experiment**. It is a prospective reproduction repair of the AA-003r specimen frozen at:

`4f505a5ac33f5765ee4bcf2a85a989668f6ac4d8`

The original frozen AA-003r execution terminated as `APPARATUS_FAILURE` because exact-rational audit serialization attempted decimal integer-to-string conversion beyond Python's configured digit limit. That failed freeze remains part of the ledger and is not overwritten.

The scientific invariant for this reproduction is:

\[
\boxed{\Delta_{scientific}=0.}
\]

The only admissible change is:

\[
\boxed{\Delta_{implementation}\subseteq\text{serialization / audit representation}.}
\]

**Do not execute recovery until this repaired executable and this specification are frozen in Git.**

## Inherited scientific specimen — unchanged

All scientific objects are inherited exactly from the original AA-003r scientific freeze.

### Developmental witness

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
\]

\[
H_2=(\texttt{BOTH},\texttt{A_ONLY}).
\]

Exact terminal hidden states:

\[
(a,b)_1(T)=\left(\frac{81}{100},\frac{919}{1000}\right),
\]

\[
(a,b)_2(T)=\left(\frac{8271}{10000},\frac9{10}\right).
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

Thus the supplied quotient remains

\[
O_b(H)=(\theta(T),L(T),U_{pre}).
\]

No witness value, update routing rule, loss, learning rate, or quotient definition may change in this reproduction.

## Inherited common future — unchanged

The future remains literally identical and deterministic for both histories.

Future target:

\[
y^{future}=1
\]

at every post-boundary step.

Proposal stream:

\[
P_{T:\infty}=\varnothing.
\]

Future update routing:

\[
M_t=(1,1)
\]

for every post-boundary step, so both parameters receive the standard gradient update.

Optimizer:

- stateless gradient descent;
- no momentum;
- no optimizer memory;
- learning rate \(\eta=1/20\).

Future dynamics remain exactly:

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

Recovery threshold remains:

\[
|\theta_t-1|\le\frac1{10}.
\]

Recovery latency remains:

\[
T_{rec}=\min\{d\in\{1,\ldots,64\}:|\theta_{T+d}-1|\le\tfrac1{10}\},
\]

with censored value \(65\) if recovery does not occur by step 64.

The sole primary comparison remains:

\[
\boxed{T_{rec}(H_1)\stackrel{?}{=}T_{rec}(H_2).}
\]

## Serialization-only repair

Original executable Git blob:

`97541d48dce627a0c3faff34daacbce4d4dbe11b`

Repaired executable Git blob:

`5cb26de2587544633d1df9c1f946f5b62fde137f`

The repaired executable changes only exact-rational audit serialization.

Original audit representation:

- decimal integer conversion embedded in a string of the form `numerator/denominator`.

Repaired audit representation:

- exact structured object with hexadecimal `numerator_hex` and `denominator_hex` fields;
- sign is preserved explicitly in the numerator hexadecimal string;
- denominator remains exact;
- no float conversion, rounding, truncation, altered arithmetic, changed horizon, or changed scientific comparison is introduced.

Hexadecimal integer formatting is used because Python's decimal integer-to-string safety limit does not apply to power-of-two base conversion. The serialized value remains an exact, reconstructable rational representation.

No call to `sys.set_int_max_str_digits()` is used.

## Required implementation-equivalence audit

Before this repaired reproduction may be opened, compare the repaired executable against the original frozen executable and verify:

1. all constants defining `H1`, `H2`, targets, learning rate, horizon, censoring, recovery tolerance, action masks, and expected boundary identities are unchanged;
2. `developmental_run`, `validate_frozen_witness`, `future_contract`, `run_frozen_future`, primary classification logic, and recovery-latency logic are unchanged except for values passed through the audit serializer;
3. the only executable semantic change is the implementation of rational serialization (`frac` plus its serialization helper);
4. no float path is added;
5. no recovery execution occurs during the audit or freeze.

Failure of any item above invalidates this reproduction freeze.

## Allowed classifications after future execution

The allowed scientific classifications are inherited unchanged from AA-003r.

### `REPAIR_QUOTIENT_FAILURE_REPLICATED_IN_INDEPENDENT_WITNESS`

Use iff

\[
T_{rec}(H_1)\neq T_{rec}(H_2).
\]

### `NO_REPLICATION_IN_INDEPENDENT_WITNESS`

Use iff

\[
T_{rec}(H_1)=T_{rec}(H_2).
\]

### `APPARATUS_FAILURE`

Use if any frozen witness identity, future identity, exact-arithmetic invariant, execution contract, or repaired serialization path fails.

## Claim ceiling

The repaired reproduction may establish only replication, non-replication, or apparatus failure for the exact AA-003r scientific specimen already frozen at `4f505a5ac33f5765ee4bcf2a85a989668f6ac4d8`.

It does not establish:

- a new scientific specimen;
- a new hidden-state mechanism;
- the correct finer repair-state quotient;
- that redundant parameterization is the generally missing coordinate;
- any topology claim;
- any released continuous-XM claim;
- any OpenCore mechanism, implementation, or solution.

## Execution state

At this reproduction freeze:

\[
\boxed{\texttt{AA-003r REPRO REPAIR = FROZEN, RECOVERY UNOPENED}.}
\]
