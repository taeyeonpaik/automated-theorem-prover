"""Sequential development comparison; source inputs frozen before runs."""
import collections
import hashlib
import json
from pathlib import Path
import subprocess
import time

ROOT=Path(__file__).resolve().parents[2]
selection=json.loads((Path(__file__).parent/'selection.json').read_text())
output=ROOT/'outputs/qed/benchmarks/v2-development.json'
binaries={'v1':ROOT/'outputs/qed/benchmarks/v1-source/bin/qed','v2':Path(__file__).parent/'bin/qed'}
report={'complete':False,'selection':selection['selection'],'limits':{'seconds':2,'max_clauses':5000},
        'binary_hashes':{v:hashlib.sha256(p.read_bytes()).hexdigest() for v,p in binaries.items()},
        'problems':selection['problems'],'runs':[]}
def save():
 report['summary']={v:dict(collections.Counter(r['status'] for r in report['runs'] if r['version']==v)) for v in binaries}
 report['mismatches']=sum(r['status'] in {'proved','not_entailed'} and r['status']!=r['expected'] for r in report['runs'])
 report['verification_failures']=sum(r['status']=='proved' and not r.get('proof_checked') for r in report['runs'])
 tmp=output.with_suffix('.tmp');tmp.write_text(json.dumps(report,indent=2)+'\n');tmp.replace(output)
save()
for i,p in enumerate(selection['problems']):
 for v in (list(binaries) if i%2==0 else list(binaries)[::-1]):
  src='\n'.join(p['input']['premises']+['---',p['input']['goal']])+'\n'
  try:
   proc=subprocess.run([str(binaries[v]),'--seconds','2','--max-clauses','5000'],input=src,text=True,capture_output=True,timeout=3)
   r=json.loads(proc.stdout)
  except subprocess.TimeoutExpired:
   r={'status':'unknown','reason':'Hard process time limit'}
  r.update(name=p['name'],version=v,expected=p['expected']);report['runs'].append(r)
 save()
 print(i+1,len(selection['problems']),p['name'],[(r['version'],r['status']) for r in report['runs'][-2:]],flush=True)
report['complete']=True;save()
print(json.dumps(report['summary']),flush=True)
if report['mismatches'] or report['verification_failures']:raise SystemExit(1)
