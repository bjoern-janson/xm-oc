#!/usr/bin/env bash
set -Eeuo pipefail

# Frozen custody wrapper for XM-CRCB-001 L2 calibration orchestration.
# This wrapper contains no scientific logic. It proves that the invoked bridge
# is descended from the frozen L1 orchestrator and contains the exact audited
# L1 predecessor freeze record + exact L2 inner launcher bytes.

L1_ORCHESTRATOR_COMMIT="f40d06d38bb75ae1f2b6ae1d14e2dca9fad4da8b"
L1_FREEZE_PATH="infra/xm_crcb_001_l1_result_freeze.json"
L1_FREEZE_BLOB="32c519438c798e903dd37c8718b2be278afeb080"
L2_INNER_PATH="infra/kaggle_xm_crcb_001_l2_calibration.sh"
L2_INNER_BLOB="e45352ea5b5d0bb586dbca22ee26ae45635fd5e2"

SCRIPT_PATH="$(python - "$0" <<'PY'
import os,sys
print(os.path.realpath(sys.argv[1]))
PY
)"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO_ROOT" ]] || { echo "FATAL: L2 frozen wrapper must run from a Git checkout" >&2; exit 90; }
HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD)"

git -C "$REPO_ROOT" diff --quiet
git -C "$REPO_ROOT" diff --cached --quiet
git -C "$REPO_ROOT" merge-base --is-ancestor "$L1_ORCHESTRATOR_COMMIT" "$HEAD" || {
  echo "FATAL: L2 bridge does not descend from frozen L1 orchestrator" >&2; exit 91;
}

FREEZE_GOT="$(git -C "$REPO_ROOT" rev-parse "$HEAD:$L1_FREEZE_PATH")"
INNER_GOT="$(git -C "$REPO_ROOT" rev-parse "$HEAD:$L2_INNER_PATH")"
[[ "$FREEZE_GOT" == "$L1_FREEZE_BLOB" ]] || {
  echo "FATAL: immutable L1 predecessor freeze blob mismatch" >&2
  echo "expected=$L1_FREEZE_BLOB actual=$FREEZE_GOT" >&2
  exit 92
}
[[ "$INNER_GOT" == "$L2_INNER_BLOB" ]] || {
  echo "FATAL: L2 inner launcher blob mismatch" >&2
  echo "expected=$L2_INNER_BLOB actual=$INNER_GOT" >&2
  exit 93
}

python - "$REPO_ROOT/$L1_FREEZE_PATH" <<'PY'
import json,sys
x=json.load(open(sys.argv[1]))
required={
 'kind':'XM-CRCB-001-L1-calibration-result-freeze-v1',
 'status':'FROZEN_PREDECESSOR',
 'language':'L1',
 'frozen_language_classification':'LANGUAGE_FAIL',
 'orchestration_endpoint':'L1_CALIBRATION_FAIL',
 'L2_authorized':True,
 'L3_authorized':False,
 'factorization_authorized':False,
 'science_authorized':False,
 'calibration_L1_result_sha256':'b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7',
 'L1_custody_manifest_sha256':'2cdc66502079012ea8fd6d5c81c5dbb0032e12284f240fd938391adc82f952f7',
 'L1_result_archive_sha256':'e5ff8f9cd7d6ffa7d3f6b906e7ea83ce06e3d0bf8f0b7182b808557ae0710fb2',
 'recompute_predecessor':False,
 'reinterpret_predecessor':False,
}
for k,v in required.items():
    if x.get(k)!=v:
        raise SystemExit(f'FATAL: L1 predecessor freeze field mismatch {k}: {x.get(k)!r} != {v!r}')
print('L2_BRIDGE_PROVENANCE_PREFLIGHT_PASS')
PY

INNER="$REPO_ROOT/$L2_INNER_PATH"
[[ -x "$INNER" ]] || chmod +x "$INNER"

echo "L2_BRIDGE_HEAD $HEAD"
echo "L2_PREDECESSOR_FREEZE_BLOB $FREEZE_GOT"
echo "L2_INNER_LAUNCHER_BLOB $INNER_GOT"
echo "CLAIM CEILING: bridge provenance validation != L2 calibration result"

exec "$INNER" "$@"
