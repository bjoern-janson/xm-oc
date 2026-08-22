# AUTHORITY-ALLOCATION-003r Reproduction Repair Result

## Status

`APPARATUS_FAILURE`

This record concerns the prospective reproduction repair frozen at:

`15e505c23ae092d29c98adfbb98bf49d13fb2654`

Repaired executable Git blob:

`5cb26de2587544633d1df9c1f946f5b62fde137f`

The local executable bytes were reconstructed from the original frozen executable using the prospectively frozen serialization-only patch and verified with `git hash-object` to equal that exact repaired blob before execution.

## Execution

The repaired frozen executable was invoked with:

`--execute --out /mnt/data/authority_allocation_003r_repro_result.json`

The execution environment terminated the process after its 120-second execution limit was exceeded.

After termination:

- no AA-003r process remained running;
- `authority_allocation_003r_repro_result.json` was absent;
- the frozen executable therefore produced no valid result record containing the primary recovery latencies or scientific classification.

No rerun, alternate implementation, shortened horizon, manual continuation, float substitution, recovery-only computation, or post-hoc extraction of the recovery bit was performed.

## Scientific readout

Because the prospectively frozen repaired reproduction did not complete, it yields no admissible value for

\[
T_{rec}(H_1)\stackrel{?}{=}T_{rec}(H_2).
\]

Therefore neither

`REPAIR_QUOTIENT_FAILURE_REPLICATED_IN_INDEPENDENT_WITNESS`

nor

`NO_REPLICATION_IN_INDEPENDENT_WITNESS`

is assigned.

The only admissible classification for this reproduction attempt is:

`APPARATUS_FAILURE`.

The immediate failure locus is execution infrastructure / computational tractability under the exact-rational 64-step path, not a scientific result about quotient sufficiency.

## Claim ceiling

This reproduction attempt establishes only that the serialization-repaired exact AA-003r specimen did not complete within the available execution limit.

It does not establish:

- replication of AA-003a quotient failure;
- non-replication of AA-003a quotient failure;
- equality or inequality of the two recovery latencies;
- any repair-state refinement;
- any claim about redundant parameterization as the missing coordinate;
- any topology, continuous-XM, or OpenCore claim.

The earlier AA-003r apparatus-failure record remains unchanged and this reproduction attempt does not overwrite it.
