"""Finish the already running evaluation's authorized timing and integrity work."""
import argparse
from datetime import datetime, timezone
import gzip
import hashlib
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import time

root=Path(__file__).resolve().parent
parser=argparse.ArgumentParser(description='Full coverage, sequential timing, and artifact verification.')
parser.add_argument('library',type=Path)
parser.add_argument('--output',type=Path,default=root/'benchmarks/full-tptp-9.3.1-v2')
args=parser.parse_args()
output=args.output.resolve()
output.mkdir(parents=True,exist_ok=True)
def phase(stage, error=None):
    path=output/'pipeline-status.json'
    temp=path.with_suffix('.tmp')
    temp.write_text(json.dumps({'engine_version':'2','stage':stage,'error':error,
        'updated_utc':datetime.now(timezone.utc).isoformat()},indent=2)+'\n')
    temp.replace(path)
phase('coverage')
try:
    previous=output/'summary.json'
    finished=json.loads(previous.read_text()) if previous.exists() else {}
    if finished.get('complete'):
        assert finished['seconds']==2 and finished['max_clauses']==5000 and finished['workers']==4
        assert hashlib.sha256((args.library/'manifest.json').read_bytes()).hexdigest()==finished['manifest_sha256']
        # Do not rewrite the completed coverage report: timing resume pins its hash.
        # The timing runner verifies the executable and every proof-related source.
    else:
        subprocess.run([sys.executable,str(root/'full_evaluation.py'),str(args.library.resolve()),
            '--output',str(output),'--workers','4','--seconds','2','--max-clauses','5000'],check=True,cwd=root)
except Exception as error:
    phase('failed',str(error)); raise
summary=json.loads((output/'summary.json').read_text())
try:
    if summary['anomalies']:
        raise RuntimeError('Coverage anomalies need review before efficiency claims: '+str(len(summary['anomalies'])))
    phase('timing')
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
except Exception as error:
    phase('failed',str(error)); raise
phase('complete')
