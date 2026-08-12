"""Resumable full-library evaluation. SQLite checkpoints; bounded parallel workers.

Parallel runs measure coverage, not isolated optimization speedups. The small
sequential benchmark remains the timing comparison. No expected label reaches QED.
"""
import argparse
from collections import Counter
from concurrent.futures import ProcessPoolExecutor, wait, FIRST_COMPLETED
from datetime import datetime, timezone
import csv
import gzip
import hashlib
import json
import os
from pathlib import Path
import platform
import signal
import sqlite3
import subprocess
import time

import client
import evaluation as ev
import tptp

ROOT = Path(__file__).resolve().parent
EXPECTED = {**ev.EXPECTED, 'ContradictoryAxioms': 'proved'}
SOURCE_BUDGET = 8 * 1024 * 1024


def timeout(signum, frame):
    raise TimeoutError('Preflight exceeded 15 seconds')


def preflight(item):
    root, descriptor = item
    result = dict(descriptor)
    result['expected'] = None if descriptor.get('known_bug') else EXPECTED.get(descriptor['expected_tptp_status'])
    signal.signal(signal.SIGALRM, timeout)
    signal.setitimer(signal.ITIMER_REAL, 15)
    try:
        p = tptp.load(Path(root) / descriptor['name'], root=root, max_source_bytes=SOURCE_BUDGET)
        client.check_input(p)
        result.update(state='accepted', reason='', input=p)
    except (tptp.Unsupported, ValueError) as error:
        result.update(state='unsupported', reason=str(error))
    except Exception as error:
        result.update(state='preflight_error', reason=f'{type(error).__name__}: {error}')
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
    return result


def prove(item):
    descriptor, seconds, cap, proof_dir = item
    problem = descriptor['input']
    rows = []
    # Balance mode order deterministically across problem names.
    modes = ev.MODES if hashlib.sha256(descriptor['name'].encode()).digest()[0] % 2 == 0 else ev.MODES[::-1]
    for mode in modes:
        try:
            result = client.run({**problem, 'mode': mode, 'seconds': seconds, 'max_clauses': cap})
        except Exception as error:
            result = {'status': 'error', 'reason': f'{type(error).__name__}: {error}', 'metrics': {}}
        row = {'name': descriptor['name'], 'mode': mode, 'status': result['status'],
               'reason': result.get('reason', ''), 'metrics': result.get('metrics', {}),
               **ev.annotate(result, descriptor['expected'])}
        if result.get('proof_checked'):
            filename = Path(descriptor['name']).name + '.' + mode + '.json.gz'
            path = Path(proof_dir) / filename
            content = gzip.compress(json.dumps(result).encode(), mtime=0)
            path.write_bytes(content)
            row.update(proof_artifact='proofs/' + filename, proof_sha256=hashlib.sha256(content).hexdigest())
        rows.append(row)
    return descriptor['name'], rows


def bounded_results(pool, function, items, workers):
    items = iter(items)
    pending = set()
    for _ in range(workers * 2):
        item = next(items, None)
        if item is not None:
            pending.add(pool.submit(function, item))
    while pending:
        done, pending = wait(pending, return_when=FIRST_COMPLETED)
        for future in done:
            yield future.result()
            item = next(items, None)
            if item is not None:
                pending.add(pool.submit(function, item))


def summarize(db, metadata, output, complete=False):
    descriptors = [json.loads(r[0]) for r in db.execute('SELECT descriptor FROM problems ORDER BY name')]
    by_name = {p['name']:p for p in descriptors}
    rows = [json.loads(r[0]) for r in db.execute('SELECT result FROM runs ORDER BY name,mode')]
    states = Counter(p['state'] for p in descriptors)
    report = {**metadata, 'updated_utc': datetime.now(timezone.utc).isoformat(), 'complete': complete,
        'preflight_completed': len(descriptors), 'preflight_states': dict(states),
        'completed_runs': len(rows), 'summary': {},
        'unsupported_reasons': dict(Counter(p['reason'] for p in descriptors if p['state'] != 'accepted'))}
    for mode in ev.MODES:
        rs = [r for r in rows if r['mode'] == mode]
        scored = [p for p in descriptors if p['expected'] is not None]
        positives = sum(p['expected'] == 'proved' for p in scored)
        report['summary'][mode] = {'attempts':len(rs), 'statuses':dict(Counter(r['status'] for r in rs)),
            'correct':sum(r['correct'] for r in rs),
            'correct_proofs':sum(r['correct'] and r['status']=='proved' for r in rs),
            'correct_negative_decisions':sum(r['correct'] and r['status']=='not_entailed' for r in rs),
            'checked_proofs_including_unscored':sum(r['proof_checked'] for r in rs),
            'scored_selected':len(scored), 'positive_selected':positives,
            'mismatches':sum(r['mismatch'] for r in rs),
            'verification_failures':sum(r['verification_failure'] for r in rs),
            'peak_rss_bytes':max((r['metrics'].get('peak_rss_bytes',0) for r in rs),default=0)}
    report['anomalies'] = [r for r in rows if r['mismatch'] or r['verification_failure']]
    temporary = output / 'summary.tmp'
    temporary.write_text(json.dumps(report, indent=2) + '\n')
    temporary.replace(output / 'summary.json')
    lines = ['# Full TPTP 9.3.1 evaluation', '',
        'Status: ' + ('complete' if complete else 'IN PROGRESS — counts below are partial'), '',
        f"Selected {metadata['selected_problems']:,} FOF/CNF files from {metadata['all_problems']:,} total problem files.",
        f"Preflight completed: {len(descriptors):,}; states: {dict(states)}.",
        f"Measured runs completed: {len(rows):,}. One repetition per mode.", '',
        f"Limits: {metadata['seconds']} seconds / {metadata['max_clauses']} clauses; {metadata['workers']} concurrent problem workers.",
        'Parallel wall-clock timings are descriptive, not isolated speedup measurements.', '',
        '| Mode | Correct proofs | Correct negative decisions | Unknown | Errors | Mismatches |',
        '|---|---:|---:|---:|---:|---:|']
    for mode,s in report['summary'].items():
        lines.append(f"| {mode} | {s['correct_proofs']} | {s['correct_negative_decisions']} | {s['statuses'].get('unknown',0)} | {s['statuses'].get('error',0)} | {s['mismatches']} |")
    lines += ['', 'Known bug-list entries and Open/Unknown labels are attempted but excluded from correctness scoring. '
              'Unsupported inputs remain in the selected/scored denominators. ContradictoryAxioms is a positive refutation case. '
              'A timeout is unknown, never a disproof. Internal proof replay checks resolution/factoring, not preprocessing.', '',
              'Per-problem inputs, dependency hashes and raw measurements are checkpointed in results.sqlite3. '
              'The inventory and original source hashes are in manifest.json. Checked proof records are in proofs/.', '',
              '## Unsupported / preflight error reasons', '']
    lines.extend(f'- {n}: {reason}' for reason,n in Counter(report['unsupported_reasons']).most_common())
    (output / 'REPORT.md').write_text('\n'.join(lines)+'\n')
    if complete:
        with (output / 'results.csv').open('w', newline='') as stream:
            fields = ['name','language','library_status','known_bug','preflight_state','preflight_reason',
                      'mode','status','correct','mismatch','proof_checked','reason','elapsed_ms','peak_rss_bytes']
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            for p in descriptors:
                if p['state'] != 'accepted':
                    writer.writerow(dict(name=p['name'],language=p['language'],library_status=p['expected_tptp_status'],
                        known_bug=p['known_bug'],preflight_state=p['state'],preflight_reason=p['reason']))
            for r in rows:
                p = by_name[r['name']]
                writer.writerow(dict(name=p['name'],language=p['language'],library_status=p['expected_tptp_status'],
                    known_bug=p['known_bug'],preflight_state=p['state'],preflight_reason=p['reason'],
                    **{k:r[k] for k in ['mode','status','correct','mismatch','proof_checked','reason']},
                    elapsed_ms=r['metrics'].get('elapsed_ms'),peak_rss_bytes=r['metrics'].get('peak_rss_bytes')))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('library', type=Path)
    parser.add_argument('--output', type=Path, default=ROOT/'benchmarks/full-tptp-9.3.1')
    parser.add_argument('--seconds', type=float, default=2)
    parser.add_argument('--max-clauses', type=int, default=5000)
    parser.add_argument('--workers', type=int, default=4)
    args = parser.parse_args()
    if not 1 <= args.workers <= 8:
        parser.error('Use 1–8 workers')
    client.validate({'goal':'true','seconds':args.seconds,'max_clauses':args.max_clauses})
    library, output = args.library.resolve(), args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    (output/'proofs').mkdir(exist_ok=True)
    manifest = json.loads((library/'manifest.json').read_text())
    descriptors = [p for p in manifest['inventory'] if p['selected']]
    sources = [*sorted((ROOT/'src').glob('*.ml')), ROOT/'client.py',ROOT/'tptp.py',ROOT/'evaluation.py',Path(__file__)]
    metadata = {'corpus':'All untyped FOF/CNF — TPTP 9.3.1','selected_problems':len(descriptors),
        'all_problems':len(manifest['inventory']),'seconds':args.seconds,'max_clauses':args.max_clauses,
        'workers':args.workers,'repeat':1,'source_byte_budget':SOURCE_BUDGET,'preflight_seconds':15,
        'manifest_sha256':ev.digest(library/'manifest.json'),'prover_sha256':ev.digest(ROOT/'bin/qed'),
        'source_hashes':{str(p.relative_to(ROOT)):ev.digest(p) for p in sources},
        'python':platform.python_version(),'platform':platform.platform(),
        'ocaml':subprocess.check_output(['ocamlopt','-version'],text=True).strip()}
    db = sqlite3.connect(output/'results.sqlite3')
    db.execute('PRAGMA journal_mode=WAL')
    db.executescript('CREATE TABLE IF NOT EXISTS metadata (data TEXT); '
        'CREATE TABLE IF NOT EXISTS problems (name TEXT PRIMARY KEY, descriptor TEXT, input TEXT); '
        'CREATE TABLE IF NOT EXISTS runs (name TEXT, mode TEXT, result TEXT, PRIMARY KEY(name,mode));')
    previous = db.execute('SELECT data FROM metadata').fetchone()
    if previous and json.loads(previous[0]) != metadata:
        raise ValueError('Cannot resume: source, corpus, environment or protocol changed. Use a new output directory.')
    if not previous:
        db.execute('INSERT INTO metadata VALUES (?)',(json.dumps(metadata),)); db.commit()
    print('Verifying corpus files and dependencies...', flush=True)
    for name,expected_hash in manifest['files'].items():
        path = (library/name).resolve()
        if not path.is_relative_to(library) or ev.digest(path) != expected_hash:
            raise ValueError('Corpus integrity failure: '+name)
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (output/'BuggedProblems-v9.3.1.txt').write_bytes((library/'BuggedProblems-v9.3.1.txt').read_bytes())
    known = {r[0] for r in db.execute('SELECT name FROM problems')}
    summarize(db,metadata,output)
    last = time.monotonic()
    with ProcessPoolExecutor(max_workers=args.workers) as pool:
        items = ((str(library),p) for p in descriptors if p['name'] not in known)
        for p in bounded_results(pool,preflight,items,args.workers):
            problem = p.pop('input',None)
            db.execute('INSERT INTO problems VALUES (?,?,?)',(p['name'],json.dumps(p),json.dumps(problem)))
            db.commit()
            if time.monotonic()-last >= 20:
                report=summarize(db,metadata,output)
                print(f"Preflight {report['preflight_completed']}/{len(descriptors)}: {report['preflight_states']}",flush=True)
                last=time.monotonic()
    report=summarize(db,metadata,output)
    print('Preflight complete: '+json.dumps(report['preflight_states']),flush=True)
    completed={r[0] for r in db.execute('SELECT name FROM runs GROUP BY name HAVING COUNT(*)=2')}
    todo=[]
    for name,desc,problem in db.execute('SELECT name,descriptor,input FROM problems ORDER BY name'):
        p=json.loads(desc)
        if p['state']=='accepted' and name not in completed:
            todo.append(({**p,'input':json.loads(problem)},args.seconds,args.max_clauses,str(output/'proofs')))
    print(f'Searching {len(todo)} accepted problems in both modes...',flush=True)
    last=time.monotonic()
    with ProcessPoolExecutor(max_workers=args.workers) as pool:
        for name,rows in bounded_results(pool,prove,todo,args.workers):
            for row in rows:
                db.execute('INSERT OR REPLACE INTO runs VALUES (?,?,?)',(name,row['mode'],json.dumps(row)))
            db.commit()
            if time.monotonic()-last>=20:
                report=summarize(db,metadata,output)
                print(f"Runs {report['completed_runs']}: "+json.dumps({m:s['statuses'] for m,s in report['summary'].items()}),flush=True)
                last=time.monotonic()
    report=summarize(db,metadata,output,complete=True)
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)')
    db.close()
    print(json.dumps(report['summary'],indent=2),flush=True)
    if any(s['mismatches'] or s['verification_failures'] for s in report['summary'].values()):
        raise SystemExit(1)

if __name__=='__main__':
    main()
