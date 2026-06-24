"""Paired metrics on real TPTP problems, with optional sequential remeasurement."""
import argparse
from collections import defaultdict
from datetime import datetime, timezone
import gzip
import hashlib
import json
from pathlib import Path
import sqlite3
import statistics

import client
import evaluation as ev


def aggregate(comparisons):
    result = {'problems': len(comparisons), 'fields': {}}
    for field in ('median_ms', 'median_pair_checks'):
        values = {mode: [p[field][mode] for p in comparisons] for mode in ev.MODES}
        summary = {}
        for label, func in [('median', statistics.median), ('mean', statistics.mean)]:
            b, o = (func(values[m]) if comparisons else None for m in ev.MODES)
            summary[label] = {'baseline': b, 'optimized': o,
                             'reduction_percent': 100*(1-o/b) if b else None}
        reductions = [100*(1-p[field]['optimized']/p[field]['baseline'])
                      for p in comparisons if p[field]['baseline'] > 0]
        summary['median_per_problem_reduction_percent'] = statistics.median(reductions) if reductions else None
        summary['paired_reduction_denominator'] = len(reductions)
        result['fields'][field] = summary
    return result


def save(output, data):
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp=output.with_suffix('.tmp')
    tmp.write_text(json.dumps(data,indent=2)+'\n'); tmp.replace(output)
    stats=data['aggregate']
    lines=['# Paired TPTP efficiency metrics','',data['corpus'],'',
           'Status: '+('complete' if data['complete'] else 'partial — do not cite as final'),'',
           f"{stats['problems']} problems proved and internally checked by both modes in every measured repetition.",
           f"{data['repeat']} repetitions per problem and mode; sequential execution.",'',
           '| Metric | Baseline median | Optimized median | Reduction |',
           '|---|---:|---:|---:|']
    for key,label in [('median_ms','OCaml pipeline time (ms)'),('median_pair_checks','Candidate literal comparisons')]:
        s=stats['fields'][key]['median']
        if s['baseline'] is not None:
            reduction=f"{s['reduction_percent']:.2f}%" if s['reduction_percent'] is not None else 'undefined'
            lines.append(f"| {label} | {s['baseline']:,.4f} | {s['optimized']:,.4f} | {reduction} |")
    lines+=['','First take the median of repeated runs for each problem/mode, then the median across '
        'the same problems for both modes. Reduction = 100 × (1 − optimized median / baseline median). '
        'This is not the median of per-problem percentage reductions; the JSON includes that separate statistic '
        'and arithmetic means as well. Timeouts, unsupported files, unscored labels, and one-mode-only successes '
        'are excluded from the paired efficiency cohort, but remain in the full coverage report. '
        'These are shared-success timing results, not an all-library average. Very short runtimes are noisy.', '',
        f"Candidate shared successes: {data.get('candidate_problems',stats['problems'])}. '
        'Full per-problem medians and identifiers are preserved in the JSON."]
    output.with_suffix('.md').write_text('\n'.join(lines)+'\n')


def historical(path, output):
    report=json.loads(path.read_text())
    data={'corpus':report['corpus'],'complete':report['complete'],'repeat':report['repeat'],
          'source_report_sha256':ev.digest(path),'method':'median of per-problem medians; identical common-solved positive cohort',
          'aggregate':aggregate(report['common_solved_comparisons']),
          'comparisons':report['common_solved_comparisons']}
    save(output,data)


def sequential(directory, output, repeats):
    report=json.loads((directory/'summary.json').read_text())
    if not report['complete']:
        raise ValueError('Full coverage evaluation must finish before sequential timing begins')
    if ev.digest(client.ROOT/'bin/qed') != report['prover_sha256']:
        raise ValueError('Prover changed since coverage evaluation')
    for name,expected in report['source_hashes'].items():
        if ev.digest(client.ROOT/name) != expected:
            raise ValueError('Source changed since coverage evaluation: '+name)
    with sqlite3.connect((directory/'results.sqlite3').resolve().as_uri()+'?mode=ro',uri=True) as db:
        outcomes=defaultdict(dict)
        for name,mode,raw in db.execute('SELECT name,mode,result FROM runs'):
            outcomes[name][mode]=json.loads(raw)
        names=sorted(name for name,modes in outcomes.items() if all(
            m in modes and modes[m]['correct'] and modes[m]['proof_checked'] for m in ev.MODES))
        problems={name:json.loads(db.execute('SELECT input FROM problems WHERE name=?',(name,)).fetchone()[0]) for name in names}
    protocol={'corpus':'TPTP 9.3.1 — sequential rerun of all shared positive successes',
        'candidate_names':names,'candidate_problems':len(names),'repeat':repeats,
        'seconds':report['seconds'],'max_clauses':report['max_clauses'],
        'coverage_report_sha256':ev.digest(directory/'summary.json'),
        'prover_sha256':report['prover_sha256'],'source_hashes':report['source_hashes'],
        'measurement_script_sha256':ev.digest(Path(__file__)),
        'method':'median of per-problem medians; only candidates proved and replay-checked in all sequential repetitions'}
    output.parent.mkdir(parents=True,exist_ok=True)
    protocol_path=output.with_suffix('.protocol.json')
    if protocol_path.exists() and json.loads(protocol_path.read_text()) != protocol:
        raise ValueError('Timing protocol changed; use a fresh output path')
    protocol_path.write_text(json.dumps(protocol,indent=2)+'\n')
    rows_path=output.with_suffix('.runs.jsonl')
    rows=[json.loads(line) for line in rows_path.read_text().splitlines()] if rows_path.exists() else []
    done={(r['name'],r['mode'],r['repetition']) for r in rows}
    proof_dir=output.parent/(output.stem+'-proofs'); proof_dir.mkdir(exist_ok=True)
    descriptors=[{'name':name,'expected':'proved','unsupported':None} for name in names]
    def checkpoint(complete=False):
        table=ev.per_problem(descriptors,rows,repeats)
        comparisons=ev.comparisons(rows,table)
        data={**protocol,'complete':complete,'updated_utc':datetime.now(timezone.utc).isoformat(),
            'completed_runs':len(rows),'aggregate':aggregate(comparisons),'comparisons':comparisons,
            'excluded_after_remeasurement':[p['name'] for p in table if not all(p[m]['correct_all_repetitions'] for m in ev.MODES)],
            'verification_failures':sum(r['verification_failure'] for r in rows),
            'mismatches':sum(r['mismatch'] for r in rows)}
        save(output,data)
        return data
    checkpoint()
    with rows_path.open('a') as stream:
        for repetition in range(1,repeats+1):
            for number,name in enumerate(names,1):
                for mode in ev.MODES if repetition%2 else ev.MODES[::-1]:
                    if (name,mode,repetition) in done:
                        continue
                    result=client.run({**problems[name],'mode':mode,'seconds':report['seconds'],'max_clauses':report['max_clauses']})
                    row={'name':name,'mode':mode,'repetition':repetition,'status':result['status'],
                         'reason':result['reason'],'metrics':result['metrics'],**ev.annotate(result,'proved')}
                    if row['proof_checked']:
                        path=proof_dir/(Path(name).name+f'.{mode}.r{repetition}.json.gz')
                        path.write_bytes(gzip.compress(json.dumps(result).encode(),mtime=0))
                        row.update(proof_artifact=str(path.relative_to(output.parent)),proof_sha256=ev.digest(path))
                    stream.write(json.dumps(row)+'\n');stream.flush();rows.append(row)
                if number%25==0:
                    checkpoint()
                    print(f'Repetition {repetition}/{repeats}: {number}/{len(names)} problems',flush=True)
    data=checkpoint(True)
    print(json.dumps(data['aggregate'],indent=2),flush=True)
    if data['mismatches'] or data['verification_failures']:
        raise SystemExit(1)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--historical',type=Path)
    group.add_argument('--full',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--repeat',type=int,default=3)
    args=parser.parse_args()
    if args.repeat<1:
        parser.error('Repetitions must be positive')
    if args.historical:
        historical(args.historical,args.output)
    else:
        sequential(args.full,args.output,args.repeat)
