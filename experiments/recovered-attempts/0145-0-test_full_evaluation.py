import json
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest

import client
import evaluation as ev
import full_evaluation as full
import tptp


class FullEvaluationTests(unittest.TestCase):
    def test_source_budget_covers_includes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            (root/'a.p').write_text("include('b.ax'). fof(g,conjecture,p).")
            (root/'b.ax').write_text('fof(a,axiom,p).')
            with self.assertRaisesRegex(tptp.Unsupported,'byte budget'):
                tptp.load(root/'a.p',root=root,max_source_bytes=40)
            self.assertEqual(len(tptp.load(root/'a.p',root=root,max_source_bytes=100)['premises']),1)

    def test_full_runner_scoring_and_resume(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)/'library'; root.mkdir()
            output=Path(tmp)/'results'
            cases=[('SYN001+1.p','Theorem','fof(g,conjecture,(p => p)).',False),
                   ('SYN002-1.p','Satisfiable','cnf(a,axiom,p).',False),
                   ('SYN003+1.p','Theorem','fof(g,conjecture,(p => p)).',True),
                   ('SYN004+1.p','ContradictoryAxioms','fof(a,axiom,p). fof(b,axiom,~p).',False),
                   ('SYN005+1.p','Theorem','fof(g,conjecture,p <~> q).',False),
                   ('SYN006+1.p','Unknown','fof(g,conjecture,(p => p)).',False)]
            inventory=[]
            for name,status,formula,bug in cases:
                (root/name).write_text('% Status : '+status+'\n'+formula)
                inventory.append(dict(name=name,expected_tptp_status=status,known_bug=bug,selected=True,language='CNF' if '-' in name else 'FOF'))
            manifest={'inventory':inventory,'files':{p.name:ev.digest(p) for p in root.glob('*.p')}}
            (root/'manifest.json').write_text(json.dumps(manifest))
            (root/'BuggedProblems-v9.3.1.txt').write_text('')
            command=['python3',str(client.ROOT/'full_evaluation.py'),str(root),'--output',str(output),'--workers','2']
            subprocess.run(command,check=True,capture_output=True,timeout=30)
            report=json.loads((output/'summary.json').read_text())
            self.assertTrue(report['complete'])
            self.assertEqual(report['preflight_states'],{'accepted':5,'unsupported':1})
            self.assertEqual(report['completed_runs'],10)
            s=report['summary']['optimized']
            self.assertEqual(s['correct'],3)
            self.assertEqual(s['correct_proofs'],2)
            self.assertEqual(s['correct_negative_decisions'],1)
            self.assertEqual(s['scored_selected'],4)
            self.assertEqual(s['mismatches'],0)
            with sqlite3.connect(output/'results.sqlite3') as db:
                before=list(db.execute('SELECT * FROM runs ORDER BY name,mode'))
            subprocess.run(command,check=True,capture_output=True,timeout=30)
            with sqlite3.connect(output/'results.sqlite3') as db:
                self.assertEqual(before,list(db.execute('SELECT * FROM runs ORDER BY name,mode')))
            for _,_,raw in before:
                row=json.loads(raw)
                if row['proof_checked']:
                    self.assertEqual(ev.digest(output/row['proof_artifact']),row['proof_sha256'])
            (root/cases[0][0]).write_text('fof(g,conjecture,q).')
            self.assertNotEqual(subprocess.run(command,capture_output=True,timeout=30).returncode,0)
