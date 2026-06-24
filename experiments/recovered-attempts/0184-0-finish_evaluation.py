"""Finish the already running evaluation's authorized timing and integrity work."""
import gzip
import hashlib
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import time

root=Path('<workspace>/outputs/qed')
output=root/'benchmarks/full-tptp-9.3.1'
print('Waiting for the full coverage evaluation before sequential timing.',flush=True)
while True:
    summary=json.loads((output/'summary.json').read_text())
    if summary['complete']:
        break
    time.sleep(30)
if summary['anomalies']:
    raise RuntimeError('Coverage anomalies need review before efficiency claims: '+str(len(summary['anomalies'])))
print('Coverage complete. Starting sequential paired measurements.',flush=True)
subprocess.run([sys.executable,str(root/'tptp_metrics.py'),'--full',str(output),
                '--output',str(output/'paired-metrics.json'),'--repeat','3'],check=True,cwd=root)
with sqlite3.connect((output/'results.sqlite3').as_uri()+'?mode=ro',uri=True) as db:
    assert db.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
    rows=[json.loads(r[0]) for r in db.execute('SELECT result FROM runs')]
    assert len(rows)==summary['preflight_states']['accepted']*2
    checked=0
    for row in rows:
        if row['proof_checked']:
            raw=(output/row['proof_artifact']).read_bytes()
            assert hashlib.sha256(raw).hexdigest()==row['proof_sha256']
            proof=json.loads(gzip.decompress(raw))
            assert proof['proof_checked'] and proof['status']=='proved'
            assert proof['metrics']==row['metrics']
            checked+=1
print(f'Integrity verified: {len(rows)} full-pass rows and {checked} saved proof records.',flush=True)
metrics=json.loads((output/'paired-metrics.json').read_text())
assert metrics['complete']
for line in (output/'paired-metrics.runs.jsonl').read_text().splitlines():
    row=json.loads(line)
    if row['proof_checked']:
        assert hashlib.sha256((output/row['proof_artifact']).read_bytes()).hexdigest()==row['proof_sha256']
(output/'integrity.json').write_text(json.dumps({'complete':True,'full_pass_rows':len(rows),
    'full_pass_proof_records':checked,'sequential_timing_rows':metrics['completed_runs'],
    'all_saved_proof_hashes_verified':True,'sqlite_integrity':'ok'},indent=2)+'\n')
print('Full evaluation, sequential metrics and artifact checks are complete.',flush=True)
