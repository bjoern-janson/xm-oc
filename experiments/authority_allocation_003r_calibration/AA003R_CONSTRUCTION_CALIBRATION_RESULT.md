# AA-003r independent collision calibration result

## Status

`INDEPENDENT_CONSTRUCTION_COLLISION_FOUND`

**Construction only. No post-boundary future or recovery outcome has been evaluated.**

## Mechanism

This calibration deliberately changes the witness generator from AA-003a.

There is no momentum and no optimizer memory. The visible scalar state is redundantly parameterized as

\[
\theta = ab,
\]

with squared loss around developmental target `0`:

\[
L=(\theta-0)^2.
\]

Development uses stateless gradient descent with

\[
\eta=\frac1{20},
\qquad
(a_0,b_0)=(1,1).
\]

At each developmental step, the update-routing action is one of:

- `A_ONLY`: apply the gradient update to `a` only;
- `B_ONLY`: apply the gradient update to `b` only;
- `BOTH`: apply the gradient update to both parameters.

The calibration deterministically enumerates schedules using exact rational arithmetic and rejects collisions that are merely coordinate swaps.

## First exact collision

The first non-swap collision occurs after two developmental steps.

### H1

\[
H_1=(\texttt{A_ONLY},\texttt{BOTH}).
\]

Terminal hidden parameter state:

\[
(a_1,b_1)=\left(\frac{81}{100},\frac{919}{1000}\right).
\]

### H2

\[
H_2=(\texttt{BOTH},\texttt{A_ONLY}).
\]

Terminal hidden parameter state:

\[
(a_2,b_2)=\left(\frac{8271}{10000},\frac9{10}\right).
\]

These hidden states are distinct and are not coordinate swaps.

## Exact quotient collision

Both histories terminate at exactly

\[
\boxed{\theta_1(T)=\theta_2(T)=\frac{74439}{100000}.}
\]

Therefore the terminal loss is also exactly equal:

\[
\boxed{L_1(T)=L_2(T)=\frac{5541164721}{10000000000}.}
\]

Define cumulative realized visible developmental influence as

\[
U_{pre}=\sum_{t<T}|\Delta\theta_t|.
\]

The two histories also satisfy exactly

\[
\boxed{U_{pre,1}=U_{pre,2}=\frac{25561}{100000}.}
\]

Hence

\[
\boxed{(\theta,L,U_{pre})_1=(\theta,L,U_{pre})_2}
\]

while

\[
\boxed{(a,b)_1\neq(a,b)_2.}
\]

## Boundary

This establishes only that an exact quotient collision is constructible under a witness mechanism structurally distinct from AA-003a's momentum construction.

It does not establish:

- unequal future repairability;
- replication of AA-003a quotient failure;
- that redundant parameterization is a generally missing repair-relevant coordinate;
- any topology claim;
- any continuous-XM claim;
- any OpenCore mechanism or solution.

No post-boundary recovery dynamics are present in the calibration script.
