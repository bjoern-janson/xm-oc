#!/usr/bin/env python3
"""XM-CRCB-001 calibration apparatus. Witness pass is apparatus-only."""
import argparse, os
os.environ.setdefault('CUBLAS_WORKSPACE_CONFIG',':4096:8')
from xm_crcb_001.core import LANGUAGES

def main():
    p=argparse.ArgumentParser(); s=p.add_subparsers(dest='mode',required=True); w=s.add_parser('witness'); w.add_argument('--out',required=True); r=s.add_parser('run-language'); r.add_argument('--language',choices=LANGUAGES,required=True); r.add_argument('--checkpoint-606',required=True); r.add_argument('--checkpoint-707',required=True); r.add_argument('--base-manifest-606',required=True); r.add_argument('--base-manifest-707',required=True); r.add_argument('--val-cache-part',required=True); r.add_argument('--prior-result',action='append',default=[]); r.add_argument('--out',required=True); a=p.parse_args()
    if a.mode=='witness':
        from xm_crcb_001.witness import run; return run(a.out)
    from xm_crcb_001.real_runner import run_language
    return run_language(a.language,a.checkpoint_606,a.checkpoint_707,a.base_manifest_606,a.base_manifest_707,a.val_cache_part,a.prior_result,a.out)
if __name__=='__main__': raise SystemExit(main())
