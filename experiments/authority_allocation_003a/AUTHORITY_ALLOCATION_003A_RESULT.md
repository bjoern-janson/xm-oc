# AUTHORITY-ALLOCATION-003a Result

## Status

`REPAIR_QUOTIENT_COUNTEREXAMPLE_IN_FROZEN_WITNESS`

## Scientific freeze

Frozen scientific commit:

`b6d30344057e9c1a3517dea343e23d5bd8b27274`

Frozen executable Git blob:

`5a26ccd8b02ce4e336089ba218abb06881c2055b`

The executable bytes used for execution were verified to hash to that exact Git blob before `--execute` was invoked.

## Frozen boundary

The two developmental histories are:

- `H1 = (1/2, 1)`
- `H2 = (1, 0)`

The executable revalidated before opening the future that:

\[
\theta_1(T)=\theta_2(T)=\frac{19}{100},
\]

\[
L_1(T)=L_2(T)=\frac{6561}{10000},
\]

\[
U_{pre,1}=U_{pre,2}=\frac{19}{100},
\]

while the carried optimizer states differ:

\[
m_1(T)=-\frac{14}{5},\qquad m_2(T)=-\frac95.
\]

Thus both frozen quotient identities held at the boundary:

\[
O_a(H_1)=O_a(H_2)
\]

and

\[
O_b(H_1)=O_b(H_2).
\]

## Frozen future

The future contract compared literally equal for both histories:

- future target: `-1` at every step;
- proposal stream: empty;
- authority: `1` every step;
- beta: `9/10`;
- eta: `1/20`;
- horizon: 64 steps;
- recovery threshold: `|theta - (-1)| <= 1/10`;
- censoring latency: 65.

No stochasticity or adaptive authority/selection path exists after the boundary.

## Primary frozen comparison

The preregistered primary comparison was:

\[
T_{rec}(H_1)\stackrel{?}{=}T_{rec}(H_2).
\]

Observed:

\[
\boxed{T_{rec}(H_1)=6}
\]

and

\[
\boxed{T_{rec}(H_2)=15}.
\]

Therefore:

\[
\boxed{T_{rec}(H_1)\neq T_{rec}(H_2).}
\]

The frozen classification is therefore:

`REPAIR_QUOTIENT_COUNTEREXAMPLE_IN_FROZEN_WITNESS`

## Narrow earned result

Because the histories were exactly equal under both supplied quotients and then received the literally identical future, the observed recovery divergence is an explicit counterexample in this frozen construction to treating either supplied quotient as sufficient for future repairability:

\[
\boxed{(\theta,L)\text{ is insufficient for repairability in this frozen witness.}}
\]

and, because `U_pre` was also exactly matched,

\[
\boxed{(\theta,L,U_{pre})\text{ is insufficient for repairability in this frozen witness.}}
\]

This result does **not** identify momentum as the generally correct missing coordinate. Momentum was the witness-construction mechanism that produced the colliding histories.

## Execution provenance

The result JSON produced by the frozen executable has SHA-256:

`8d172ee4618c6c0dfbcf553277d03ece9d10085c07bd7675df72339bbaab536a`

and Git blob hash:

`229c0cde3d1cf43e171ee76172c2eea2ae54ab66`

The execution used exact rational arithmetic throughout.

## Claim ceiling

AA-003a establishes only a counterexample for this exact deterministic synthetic witness and future.

It does not establish:

- that momentum is the generally missing repair-relevant coordinate;
- that all hidden optimizer state changes repairability;
- a general law for `(theta,L)` or `(theta,L,U_pre)` across learning systems;
- any topology claim;
- any claim about released continuous XM;
- any OpenCore mechanism, implementation, or solution.

No AA-003b experiment was created or run as part of this execution.