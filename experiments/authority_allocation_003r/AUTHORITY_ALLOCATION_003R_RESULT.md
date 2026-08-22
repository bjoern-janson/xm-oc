# AUTHORITY-ALLOCATION-003r Result

## Status

`APPARATUS_FAILURE`

## Scientific freeze

Frozen scientific commit:

`4f505a5ac33f5765ee4bcf2a85a989668f6ac4d8`

Frozen executable Git blob:

`97541d48dce627a0c3faff34daacbce4d4dbe11b`

Before execution, the local executable bytes were verified with `git hash-object` to match that exact frozen blob.

## Execution

The frozen executable was invoked exactly once with `--execute`.

The frozen program returned:

`APPARATUS_FAILURE`

with the recorded exception:

`ValueError('Exceeds the limit (4300 digits) for integer string conversion; use sys.set_int_max_str_digits() to increase the limit')`

The failure occurred during exact-rational future execution/serialization when converting a very large integer to a string. Under the preregistered classification rule, this is an apparatus failure and no recovery comparison is scientifically interpretable from this freeze.

No repair, rerun, alternative arithmetic path, shortened horizon, or manual continuation was performed after the failure.

## Frozen scientific readout

Because execution failed before a valid primary record containing both frozen recovery latencies was produced, AA-003r yields no admissible value for

\[
T_{rec}(H_1)\stackrel{?}{=}T_{rec}(H_2).
\]

Therefore neither

`REPAIR_QUOTIENT_FAILURE_REPLICATED_IN_INDEPENDENT_WITNESS`

nor

`NO_REPLICATION_IN_INDEPENDENT_WITNESS`

is assigned.

The only frozen classification is:

`APPARATUS_FAILURE`.

## Result custody

Raw frozen-program output:

`experiments/authority_allocation_003r/authority_allocation_003r_result.json`

Raw result JSON SHA-256:

`a12521a6b8ba9205aa3d904e7f157e3adda948cf584e6ba5430d31a18a1e78e5`

Raw result JSON Git blob hash:

`10c86642510d069e46830da1ed3331934107aef3`

## Claim ceiling

This run establishes only that the prospectively frozen AA-003r apparatus failed under its exact-rational 64-step execution path because Python refused integer-to-string conversion above its configured digit limit.

It does not establish:

- replication of AA-003a quotient failure;
- non-replication of AA-003a quotient failure;
- equality or inequality of the two recovery latencies;
- that redundant parameterization is or is not repair-relevant;
- any finer repair-state quotient;
- any topology claim;
- any continuous-XM claim;
- any OpenCore mechanism or solution.
