# AA-003r Computational-Equivalence Repair Audit

## Status

`EQUIVALENCE_AUDIT_PASS`

**Recovery remains unopened. No `--execute` invocation was performed during this audit.**

## Compared revisions

Serialization-repair freeze parent:

`15e505c23ae092d29c98adfbb98bf49d13fb2654`

Computational-equivalence candidate before this audit record:

`ab490153d2b51ba8f0aae91d3449c185c61f7b8e`

Candidate executable Git blob:

`f67145290d506b58532df90314510a95738569d7`

## Diff scope

The commit comparison contains only:

1. the new prospective computational-equivalence repair specification;
2. the existing AA-003r executable.

The executable patch is confined to the post-boundary evaluator/audit layer.

There are no patch hunks touching:

- `TARGET_PRE`;
- `TARGET_FUTURE`;
- `ETA`;
- `RECOVERY_TOL`;
- `FUTURE_STEPS`;
- `CENSORED_LATENCY`;
- `H1` or `H2`;
- expected boundary identities;
- `developmental_run`;
- `validate_frozen_witness`;
- `future_contract`;
- the final scientific classification comparison in `main`.

Therefore these frozen scientific objects are unchanged.

## Exact recurrence audit

Inside `run_frozen_future`, the scientific recurrence lines remain literally unchanged:

```python
theta = a * b
error = theta - target
grad_a = 2 * error * b
grad_b = 2 * error * a

a = a - eta * mask_a * grad_a
b = b - eta * mask_b * grad_b
```

Thus:

\[
\boxed{f_{repaired}=f_{frozen}.}
\]

The repaired helper `exact_state` computes only audit quantities from the already-produced exact state:

\[
\theta=ab,
\qquad
|\theta-target|.
\]

It does not alter the recurrence state.

## Recovery-predicate audit

The prior evaluator computed:

```python
abs_error = abs(theta - target)
if recovery_latency is None and abs_error <= tol:
    recovery_latency = d
```

The repaired evaluator computes the exact same value through `exact_state` and tests:

```python
if hit_state["abs_error"] <= tol:
    return ...
```

Because:

\[
hit\_state[\texttt{abs\_error}]=|\theta_d-target|,
\]

and `tol` is unchanged,

\[
\boxed{C_{repaired}=C_{frozen}.}
\]

## First-hit equivalence

Let:

\[
x_0=x_T,
\qquad
x_d=f(x_{d-1}).
\]

The frozen full-horizon evaluator and repaired evaluator generate identical state prefixes by induction because they share the same \(x_0\) and exact recurrence \(f\).

If the first hit occurs at \(d^*\le64\), then both evaluators observe:

\[
C(x_d)=0\quad(d<d^*),
\qquad
C(x_{d^*})=1.
\]

The old evaluator stores \(d^*\) and continues; the repaired evaluator returns \(d^*\) immediately. Later states cannot change the minimum.

If no hit occurs through step 64, both evaluate the same 64-state prefix and return the same censored value 65.

Therefore:

\[
\boxed{
T_{repaired}
=
\operatorname{FirstHit}_{64}(f,x_T,C)
=
T_{full}.
}
\]

## Audit-representation change

The repaired evaluator removes full future trajectory serialization and records only outcome-sufficient exact state:

- the boundary record already contains \(x_T\);
- on a hit at \(d\): exact `pre_hit_state = x_{d-1}` and `hit_state = x_d`;
- on censoring: exact `final_state = x_{64}`.

All rational values use the already-frozen hexadecimal numerator/denominator encoding. No float, rounding, truncation, or alternate arithmetic path is introduced.

## Gate result

All prospective equivalence conditions pass:

\[
\boxed{\Delta_{scientific}=0}
\]

and:

\[
\boxed{
\Delta_{implementation}
\subseteq
\text{first-hit control flow + bounded exact audit representation}.
}
\]

The computational-equivalence repair is therefore admissible for prospective execution, but **has not been executed**.
