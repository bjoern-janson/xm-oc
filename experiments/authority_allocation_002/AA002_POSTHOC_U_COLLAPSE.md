# AA-002 Post-hoc U-collapse analysis

## Status

**POST-CONFIRMATORY DESCRIPTIVE ANALYSIS. NOT PREREGISTERED.**

This note analyzes the already-opened AA-002 confirmatory artifact only. It does not alter the frozen AA-002 result, add a new confirmatory claim, or constitute AA-003.

Input artifact: `authority-allocation-002-result` from hosted run `32582018804`, artifact ID `9478041280`.

Uncompressed result JSON SHA-256:

`b6d2b73c9b36e9b602567e3f14634609e8e50aca86ea6ac0bba2b62eaa8aff25`

The analysis pools all 4096 AA-002 run records (256 seeds x 8 lambda values x 2 placement arms).

## Exact pre-shift collapse

In the frozen toy, B starts at

\[
\theta_B(0)=0
\]

and every pre-shift B update moves monotonically toward 1. Therefore the recorded cumulative realized B update influence

\[
U_{pre}(B)=\sum_{t<T_{pre}} |\Delta\theta_B(t)|
\]

is exactly the net B parameter change. Empirically, for all 4096 records,

\[
\boxed{U_{pre}(B)=\theta_B(T_{pre})}
\]

with maximum absolute discrepancy exactly `0.0` in the stored double-precision records.

Also,

\[
\theta_A(T_{pre})=1
\]

for all 4096 records.

Thus, within this toy, the entire persistent pre-shift competence state is determined by `U_pre(B)`. The authority-placement effect does not leave an additional hidden pre-shift state variable in the model beyond its effect on realized B update influence.

Because

\[
B\text{ pre-shift error}=(1-\theta_B)^2,
\]

we also have exactly

\[
\boxed{E_B^{pre}=(1-U_{pre})^2.}
\]

## Descriptive recovery collapse onto U_pre

Across all 4096 runs, realized pre-shift update influence is extremely predictive of recovery.

For recovery by post-shift step 16:

- ROC AUC using `U_pre(B)` alone: `0.9997197379842837`.
- The best single post-hoc scalar threshold was approximately

\[
U_{pre}\ge 0.504763418125,
\]

which classified `4079/4096` runs correctly (`99.5849609375%`).
- Errors under that post-hoc threshold: 16 false positives and 1 false negative.
- All 17 threshold errors occurred in the `lambda=0.1` transition band.

For censored recovery latency across all runs:

- Spearman correlation with `U_pre(B)`: `-0.964817943828881`.
- Pearson correlation with `U_pre(B)`: `-0.9751180760439025`.

Within `lambda=0.1` alone, where recovery-by-16 is nontrivial:

- ROC AUC using `U_pre(B)` alone: `0.9840250651041668`.
- The same post-hoc threshold `0.504763418125` classified `495/512` arm-runs correctly (`96.6796875%`).

So AA-002 shows an extremely strong descriptive collapse of future recovery onto realized pre-shift developmental influence, but not a mathematically exact scalar collapse across all conditions.

## Why the pooled collapse is not an identification of U sufficiency

AA-002 changes the same `lambda` rule both before and after the environmental shift. Therefore different lambda conditions do not share the same post-shift authority process.

For B after the shift, the scalar error evolves as

\[
e_{t+1}=e_t\left(1-0.1 A_t(B)\right),
\]

where `0.1 = 2 * learning_rate` in the frozen toy.

Since

\[
e_{pre}=1-U_{pre},
\]

a post-shift trajectory through deadline `d` obeys

\[
\boxed{
e_d=(1-U_{pre})\prod_{j=1}^{d}\left(1-0.1A_j(B)\right).
}
\]

Equivalently, define post-shift contraction capacity

\[
G_d=-\sum_{j=1}^{d}\log\left(1-0.1A_j(B)\right).
\]

Then recovery by deadline `d` occurs exactly when

\[
\boxed{
G_d\ge \log\frac{1-U_{pre}}{0.1}.
}
\]

Reconstruction of the frozen dynamics reproduced the stored recovery-by-16 status for all `4096/4096` records, with maximum numerical residual in the multiplicative error identity of approximately `3.03e-16`.

Thus the 17-run non-collapse under a single U threshold is not evidence for hidden pre-shift path memory. It is explained by variation in the post-shift authority/proposal process.

## Quota-placement interpretation sharpened

Across matched informed/random pairs:

- random placement had greater `U_pre` in `1792` pairs;
- equal `U_pre` in `256` pairs (`lambda=0`);
- lower `U_pre` in `0` pairs.

Whenever random placement had greater `U_pre`, it was never slower in recovery:

- random faster: `275` pairs;
- tied: `1517` pairs;
- random slower: `0` pairs.

Therefore the AA-002 placement result can be localized more sharply as:

\[
\boxed{
\text{authority timing}
\rightarrow
\text{different realized }U_{pre}
\rightarrow
\text{different competence at shift}.
}
\]

Within this toy, there is no evidence that pre-shift authority timing has an additional persistent effect after conditioning on the resulting scalar competence state. The experiment was not designed to test such a path-dependent state representation.

## Narrow conclusion

The simplest law already present in AA-002 is:

\[
\boxed{
\text{pre-shift developmental history}
\xrightarrow{\text{in this scalar toy}}
U_{pre}=\theta_B(T_{pre})
}
\]

and future recoverability is then determined by that competence state together with the future post-shift authority/proposal trajectory.

So the strongest earned refinement is not

> realized developmental influence alone universally determines recoverability.

It is:

\[
\boxed{
\text{realized developmental influence is a sufficient statistic for the persistent pre-shift B competence state in AA-002,}
}
\]

while recovery additionally depends on the post-shift learning opportunities supplied by the frozen authority/proposal process.

This is post-hoc and toy-specific. It does not establish dose universality, topology, continuous-XM transfer, or an OpenCore claim.