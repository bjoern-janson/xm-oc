#!/usr/bin/env bash
set -Eeuo pipefail
# Frozen provenance/audit wrapper for XM-CRCB-001 L3. No scientific logic.
L2_FREEZE_COMMIT=9ded68ec10f7dab8b0de8aeba2ffce1a9bceb7d6
INNER_PATH=infra/kaggle_xm_crcb_001_l3_calibration_frozen.sh
INNER_BLOB=6659a625a56622d6ad7c9151808a649ef6652e3b
L1_FREEZE_PATH=infra/xm_crcb_001_l1_result_freeze.json
L1_FREEZE_BLOB=32c519438c798e903dd37c8718b2be278afeb080
L2_FREEZE_PATH=infra/xm_crcb_001_l2_result_freeze.txt
L2_FREEZE_BLOB=79edf788c5ec4a0a6f7251c8cc1f266bd25bf22a
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$(git -C "$HERE" rev-parse --show-toplevel)"; HEAD="$(git -C "$ROOT" rev-parse HEAD)"
git -C "$ROOT" diff --quiet; git -C "$ROOT" diff --cached --quiet; git -C "$ROOT" merge-base --is-ancestor "$L2_FREEZE_COMMIT" "$HEAD"
[[ "$(git -C "$ROOT" rev-parse "$HEAD:$INNER_PATH")" == "$INNER_BLOB" ]] || { echo FATAL_L3_INNER_BLOB >&2; exit 90; }
[[ "$(git -C "$ROOT" rev-parse "$HEAD:$L1_FREEZE_PATH")" == "$L1_FREEZE_BLOB" ]] || { echo FATAL_L1_FREEZE_BLOB >&2; exit 91; }
[[ "$(git -C "$ROOT" rev-parse "$HEAD:$L2_FREEZE_PATH")" == "$L2_FREEZE_BLOB" ]] || { echo FATAL_L2_FREEZE_BLOB >&2; exit 92; }
python - "$ROOT/$L1_FREEZE_PATH" "$ROOT/$L2_FREEZE_PATH" <<'PY'
import json,sys
l1=json.load(open(sys.argv[1])); t=open(sys.argv[2]).read().splitlines(); l2=dict(z.split('=',1) for z in t if '=' in z)
assert l1['calibration_L1_result_sha256']=='b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7' and l1['frozen_language_classification']=='LANGUAGE_FAIL' and l1['L2_authorized'] is True
assert l2['L2_result_sha256']=='73579a4a5fad030b4f893b64e52fc0ab74a75cca959b133febd218835d43a16f' and l2['classification']=='LANGUAGE_FAIL' and l2['endpoint']=='L2_CALIBRATION_FAIL' and l2['L3_authorized']=='true'
assert l2['factorization_authorized']=='false' and l2['science_authorized']=='false'
print('L3_BRIDGE_PROVENANCE_PREFLIGHT_PASS')
PY
echo "L3_BRIDGE_HEAD $HEAD"; echo "L3_INNER_LAUNCHER_BLOB $INNER_BLOB"; echo 'CLAIM CEILING: bridge audit != L3 calibration result'
bash "$ROOT/$INNER_PATH" "$@"
R=/kaggle/working/xm_crcb_001_l3_calibration/output/L3/calibration_L3_result.json
C=/kaggle/working/xm_crcb_001_l3_calibration/output/L3/custody_manifest.json
E=/kaggle/working/xm_crcb_001_l3_calibration/output/endpoint.json
D=/kaggle/working/xm_crcb_001_l3_calibration/output/L3
[[ -f "$R" && -f "$C" && -f "$E" ]] || { echo FATAL_L3_POST_AUDIT_FILES >&2; exit 93; }
python - "$R" "$C" "$E" "$D" <<'PY'
import hashlib,json,pathlib,re,sys
r,c,e,d=map(pathlib.Path,sys.argv[1:]); x=json.loads(r.read_text()); cm=json.loads(c.read_text()); ep=json.loads(e.read_text())
L1='b111d63df0aa14e4fa6495b4fd9b4f285a295d554f9e43a6c9ec54c41a251bf7'; L2='73579a4a5fad030b4f893b64e52fc0ab74a75cca959b133febd218835d43a16f'
def sh(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''): h.update(b)
 return h.hexdigest()
assert x['schema']=='XM-CRCB-001-CALIBRATION-APPARATUS-v1' and x['kind']=='real_calibration_language_result' and x['source_scientific_sha']=='be7cefd60cf199e9fbabd6110be1254a1756590e' and x['cc_protocol_commit']=='4d0e87613ef1b894d6ebac2400e358a9fd82e5ae' and x['language']=='L3'
assert [(z['file'],z['sha256'],z['classification']) for z in x['prior_results']]==[('calibration_L1_result.json',L1,'LANGUAGE_FAIL'),('calibration_L2_result.json',L2,'LANGUAGE_FAIL')]
assert x['science_reserved_semantic_access'] is False and x['factorization_constructed'] is False and x['authority_metrics_read'] is False and x['calibration_only'] is True
bases=x['base_results']; assert [b['base_seed'] for b in bases]==[606,707]; rows=[]
for b in bases:
 w=b['whitelist']; ns=w['names']; ids={int(m.group(1)) for n in ns for m in [re.match(r'diffusion_transformer\.blocks\.(\d+)\.',n)] if m}
 assert w['language']=='L3' and w['label']=='final_transformer_block_plus_final_layer' and len(ids)==1
 assert any(n.startswith('diffusion_transformer.final_layer.') for n in ns)
 assert all(n.startswith('diffusion_transformer.final_layer.') or n.startswith('diffusion_transformer.blocks.') for n in ns)
 assert b['null_audit']['delta_exact_zero'] is True
 gs=b['groups']; assert sorted(g['target_region'] for g in gs)==[0,5,10,15]
 for g in gs:
  reps=g['replicates']; assert sorted(z['repair_seed'] for z in reps)==[1101,1102,1103] and all(z['language']=='L3' for z in reps); rows+=reps
assert len(rows)==24
for z in rows:
 t=json.loads((d/z['trace_file']).read_text()); assert len(t)==32 and [q['step'] for q in t]==list(range(32)); assert {int(i) for q in t for i in q['construct_indices']}.issubset(set(range(64)))
assert cm['result']['sha256']==sh(r) and ep['result_sha256']==sh(r) and ep['custody_manifest_sha256']==sh(c)
cl=x['decision']['classification']; out=ep['endpoint']
if out=='L3_CALIBRATION_PASS':
 assert cl=='LANGUAGE_PASS' and ep['L_A_star']=='L3' and ep['calibration_closed'] is True and ep['repair_language_insufficient'] is False and ep['factorization_protocol_preparation_authorized'] is True
elif out=='REPAIR_LANGUAGE_INSUFFICIENT':
 assert cl=='LANGUAGE_FAIL' and ep['L_A_star'] is None and ep['calibration_closed'] is True and ep['repair_language_insufficient'] is True and ep['factorization_protocol_preparation_authorized'] is False
elif out=='CALIBRATION_APPARATUS_FAILURE':
 assert ep['calibration_closed'] is False and ep['factorization_protocol_preparation_authorized'] is False
else: raise AssertionError(out)
assert ep['factorization_execution_authorized'] is False and ep['science_authorized'] is False and ep['L1_predecessor_sha256']==L1 and ep['L2_predecessor_sha256']==L2
print('L3_BRIDGE_POST_AUDIT_PASS'); print(out)
PY
