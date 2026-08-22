# AA-003a construction calibration result

## Status

`CONSTRUCTION_COLLISION_FOUND`

**Calibration only. AA-003a has not been frozen or run. No post-boundary future and no recovery outcome have been evaluated.**

## Purpose

The calibration asks only whether momentum can serve as a witness-construction mechanism for two developmental histories with identical present competence but different persistent optimizer state.

Dynamics:

\[
g_t=2(\theta_t-1),
\]

\[
m_{t+1}=0.9m_t+A_tg_t,
\]

\[
\theta_{t+1}=\theta_t-0.05m_{t+1},
\]

with

\[
\theta_0=0,\qquad m_0=0,
\]

and authority alphabet

\[
A_t\in\{0,\tfrac12,1\}.
\]

The search enumerates schedules deterministically using exact rational arithmetic and returns the first exact terminal-theta collision with unequal terminal momentum.

## First exact collision

The first collision occurs at two developmental steps.

### History H1

Authority schedule:

\[
H_1=(\tfrac12,1).
\]

Trace:

1. \(A_1=\tfrac12\): \(g_1=-2\), \(m_1=-1\), \(\theta_1=\tfrac1{20}=0.05\).
2. \(A_2=1\): \(g_2=-\tfrac{19}{10}\), \(m_2=-\tfrac{14}{5}=-2.8\), \(\theta_2=\tfrac{19}{100}=0.19\).

Cumulative realized parameter movement:

\[
U_{pre,1}=\left|\tfrac1{20}\right|+\left|\tfrac{14}{100}\right|=\tfrac{19}{100}.
\]

### History H2

Authority schedule:

\[
H_2=(1,0).
\]

Trace:

1. \(A_1=1\): \(g_1=-2\), \(m_1=-2\), \(\theta_1=\tfrac1{10}=0.1\).
2. \(A_2=0\): \(g_2=-\tfrac95\), \(m_2=-\tfrac95=-1.8\), \(\theta_2=\tfrac{19}{100}=0.19\).

Cumulative realized parameter movement:

\[
U_{pre,2}=\left|\tfrac1{10}\right|+\left|\tfrac9{100}\right|=\tfrac{19}{100}.
\]

## Construction checks

The terminal present competence collides exactly:

\[
\boxed{\theta_1(T)=\theta_2(T)=\tfrac{19}{100}.}
\]

Therefore the terminal squared loss also collides exactly:

\[
\boxed{L_1(T)=L_2(T)=\left(\tfrac{19}{100}-1\right)^2=\tfrac{6561}{10000}.}
\]

The persistent momentum state differs:

\[
\boxed{m_1(T)=-\tfrac{14}{5}\neq-\tfrac95=m_2(T).}
\]

The calibration unexpectedly also produces exact equality of the AA-002 cumulative realized-update scalar:

\[
\boxed{U_{pre,1}=U_{pre,2}=\tfrac{19}{100}.}
\]

Thus the witness satisfies not only the AA-003a construction requirement

\[
(\theta,L)_1=(\theta,L)_2,\qquad m_1\neq m_2,
\]

but also the stronger construction identity

\[
(\theta,L,U_{pre})_1=(\theta,L,U_{pre})_2,\qquad m_1\neq m_2.
\]

This is **not** an AA-003b result because no common future and no recovery outcome have been executed.

## Boundary

The calibration establishes only that the required state collision is constructible cleanly under a momentum witness.

It does not establish:

- unequal future repairability;
- insufficiency of \((\theta,L)\);
- insufficiency of \((\theta,L,U_{pre})\);
- that momentum is the missing repair-relevant coordinate;
- any continuous-XM or OpenCore claim.

The next scientific act, if pursued, is to write the prospective AA-003a freeze around this collision and an exactly paired post-boundary future. That freeze has **not** been written here.