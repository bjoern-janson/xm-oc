from __future__ import annotations
import hashlib, json, random
from pathlib import Path
from typing import Iterable, Mapping, Optional, Sequence, Tuple
import torch
from torch import nn

SCHEMA='XM-CRCB-001-CALIBRATION-APPARATUS-v1'
SOURCE_SHA='be7cefd60cf199e9fbabd6110be1254a1756590e'
CC_PROTOCOL='4d0e87613ef1b894d6ebac2400e358a9fd82e5ae'
CAL_REGION_SEED=271829; CAL_FLAT_DIM=4096; CAL_COORDS=(651,1449,2382,3402)
CAL_TARGETS=(0,5,10,15); CAL_BASE_SEEDS=(606,707); CAL_REPAIR_SEEDS=(1101,1102,1103); CAL_EVAL_SEED=1201201
EXPECTED_TRAIN_LATENT_SHA='624093703a4a6e24f7dbd663afbb66d6e2b6cea1f820c51e36ead0cb4881b74f'
EXPECTED_VAL_LATENT_SHA='f9f0a5788cc649d523ab35e0c9430d2f23f196ea212221ada4ea3e8594dd8c99'
CONSTRUCT=tuple(range(64)); EVAL=tuple(range(64,128)); SCIENCE_RESERVED=tuple(range(128,256))
LANGUAGES=('L1','L2','L3')
LANGUAGE_LABELS={'L1':'output_projection_only','L2':'full_final_layer','L3':'final_transformer_block_plus_final_layer'}
J=32; BATCH=8; LR=1e-4; BETAS=(0.9,0.95); EPS=1e-8; WD=0.; CLIP=1.
DELTA_G=.020; DELTA_D_MEAN=.005; DELTA_D_MAX=.020; GAIN_SPREAD_MAX=.030

def cjson(x): return (json.dumps(x,sort_keys=True,separators=(',',':'))+'\n').encode()
def sha_bytes(b): return hashlib.sha256(b).hexdigest()
def sha_file(p):
    h=hashlib.sha256()
    with Path(p).open('rb') as f:
        for c in iter(lambda:f.read(1<<20),b''): h.update(c)
    return h.hexdigest()
def write_json(p,x):
    p=Path(p); p.parent.mkdir(parents=True,exist_ok=True); p.write_text(json.dumps(x,sort_keys=True,indent=2)+'\n'); return sha_file(p)
def tensor_bytes(t): return t.detach().cpu().contiguous().view(torch.uint8).numpy().tobytes()
def named_hash(items:Iterable[Tuple[str,torch.Tensor]]):
    h=hashlib.sha256()
    for n,t in sorted(items,key=lambda z:z[0]):
        h.update(n.encode()+b'\0'+str(t.dtype).encode()+b'\0'+json.dumps(list(t.shape)).encode()+b'\0'+tensor_bytes(t))
    return h.hexdigest()
def param_hash(m,names:Optional[Sequence[str]]=None):
    s=None if names is None else set(names); return named_hash((n,p) for n,p in m.named_parameters() if s is None or n in s)
def seed(root,domain,*tokens):
    b='|'.join([str(root),domain,*map(str,tokens)]).encode(); return int.from_bytes(hashlib.sha256(b).digest()[:8],'little')&0x7fffffffffffffff
def gen(s): g=torch.Generator(device='cpu'); g.manual_seed(int(s)); return g
def verify_coords():
    got=tuple(sorted(random.Random(CAL_REGION_SEED).sample(range(CAL_FLAT_DIM),4)))
    if got!=CAL_COORDS: raise AssertionError((got,CAL_COORDS))
def noise(shape,region,s,device,dtype):
    z=torch.randn(tuple(shape),generator=gen(s),dtype=torch.float32); f=z.reshape(shape[0],-1)
    for bit,c in enumerate(CAL_COORDS):
        mag=f[:,c].abs(); f[:,c]=mag if ((region>>bit)&1) else -mag
    return z.to(device=device,dtype=dtype)
def times(n,s,device): return torch.rand((n,),generator=gen(s),dtype=torch.float32).to(device)

def language_names(m,lang):
    names=[n for n,_ in m.named_parameters()]
    if lang=='L1': out=[n for n in names if n.startswith('diffusion_transformer.final_layer.linear.')]
    elif lang=='L2': out=[n for n in names if n.startswith('diffusion_transformer.final_layer.')]
    elif lang=='L3':
        i=len(m.diffusion_transformer.blocks)-1; out=[n for n in names if n.startswith((f'diffusion_transformer.blocks.{i}.','diffusion_transformer.final_layer.'))]
    else: raise ValueError(lang)
    if not out: raise AssertionError('empty whitelist')
    return sorted(out)
def whitelist(m,lang):
    sel=set(language_names(m,lang))
    for n,p in m.named_parameters(): p.requires_grad=n in sel
    actual=sorted(n for n,p in m.named_parameters() if p.requires_grad)
    if actual!=sorted(sel): raise AssertionError('whitelist mismatch')
    return {'language':lang,'label':LANGUAGE_LABELS[lang],'names':actual,'numel':sum(p.numel() for n,p in m.named_parameters() if n in sel),'names_sha256':sha_bytes(cjson(actual))}
def snapshot(m,names):
    s=set(names); return {n:p.detach().cpu().clone() for n,p in m.named_parameters() if n in s}
def restore(m,snap):
    ps=dict(m.named_parameters())
    with torch.no_grad():
        for n,v in snap.items(): ps[n].copy_(v.to(ps[n].device,ps[n].dtype))
def delta(m,snap):
    ps=dict(m.named_parameters()); return {n:ps[n].detach().cpu()-v for n,v in snap.items()}
def zero_delta(d): return all(torch.count_nonzero(v).item()==0 for v in d.values())

def metrics(base,repaired,target):
    g=(base[target]-repaired[target])/base[target]; ds=[max(0.,(r-b)/b) for q,(b,r) in enumerate(zip(base,repaired)) if q!=target]
    dm=sum(ds)/len(ds); dx=max(ds); rec=g>=DELTA_G and dm<=DELTA_D_MEAN and dx<=DELTA_D_MAX
    return {'G_rel':float(g),'D_mean':float(dm),'D_max':float(dx),'Rec_cal_dagger':bool(rec)}
def repeat(reps):
    gs=[float(x['G_rel']) for x in reps]; rs=[bool(x['Rec_cal_dagger']) for x in reps]; spread=max(gs)-min(gs)
    ok=sum(rs)>=2 and all(g>0 for g in gs) and spread<=GAIN_SPREAD_MAX
    return {'replicate_rec_count':sum(rs),'all_gains_positive':all(g>0 for g in gs),'gain_spread':spread,'group_pass':bool(ok)}
def decision(groups,null_ok,custody_ok):
    if len(groups)!=8: raise ValueError('need 8 groups')
    n=sum(bool(g['group_pass']) for g in groups); pb={str(s):0 for s in CAL_BASE_SEEDS}
    for g in groups: pb[str(g['base_seed'])]+=int(bool(g['group_pass']))
    bases=all(pb[str(s)]>=3 for s in CAL_BASE_SEEDS); ok=n>=7 and bases and null_ok and custody_ok
    return {'group_pass_count':n,'group_total':8,'group_pass_fraction':n/8,'per_base_region_pass_count':pb,'per_base_min3_pass':bases,'null_audit_pass':null_ok,'custody_pass':custody_ok,'language_adequate':ok,'classification':'LANGUAGE_PASS' if ok else 'LANGUAGE_FAIL'}
def validate_priors(lang,paths):
    expected={'L1':[],'L2':['L1'],'L3':['L1','L2']}[lang]
    if len(paths)!=len(expected): raise RuntimeError(f'{lang} requires {expected}')
    out=[]
    for p,e in zip(paths,expected):
        x=json.loads(Path(p).read_text())
        if x.get('schema')!=SCHEMA or x.get('language')!=e or x.get('decision',{}).get('classification')!='LANGUAGE_FAIL': raise RuntimeError(f'invalid prior {p}')
        out.append(x)
    return out
