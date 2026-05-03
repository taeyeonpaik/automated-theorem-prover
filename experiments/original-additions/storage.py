"""SQLite stores submitted problems and proof runs, never global assumptions."""
import hashlib
import json
import sqlite3
from pathlib import Path

DEFAULT_DB = Path(__file__).resolve().parent / "data/qed.sqlite3"


def connect(path=DEFAULT_DB):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path)
    db.executescript("""
        CREATE TABLE IF NOT EXISTS problems (
            id TEXT PRIMARY KEY, premises TEXT NOT NULL, goal TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS runs (
            id INTEGER PRIMARY KEY, problem_id TEXT NOT NULL,
            created TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
            status TEXT NOT NULL, checked INTEGER NOT NULL, result TEXT NOT NULL);
    """)
    return db


def save(result, path=DEFAULT_DB):
    problem = result["problem"]
    content = json.dumps([problem["premises"], problem["goal"]], separators=(",", ":"))
    key = hashlib.sha256(content.encode()).hexdigest()
    with connect(path) as db:
        db.execute("INSERT OR IGNORE INTO problems VALUES (?,?,?)",
                   (key, json.dumps(problem["premises"]), problem["goal"]))
        cursor = db.execute("INSERT INTO runs(problem_id,status,checked,result) VALUES (?,?,?,?)",
                            (key, result["status"], int(result["proof_checked"]), json.dumps(result)))
        return cursor.lastrowid


def history(path=DEFAULT_DB):
    with connect(path) as db:
        rows = db.execute("""SELECT runs.id,created,status,goal,result FROM runs
            JOIN problems ON problems.id=runs.problem_id ORDER BY runs.id DESC LIMIT 50""").fetchall()
        premises = {p for (ps,) in db.execute("SELECT premises FROM problems") for p in json.loads(ps)}
        counts = {
            "problems": db.execute("SELECT count(*) FROM problems").fetchone()[0],
            "runs": db.execute("SELECT count(*) FROM runs").fetchone()[0],
            "checked_proof_runs": db.execute("SELECT count(*) FROM runs WHERE checked=1").fetchone()[0],
            "distinct_proved_problems": db.execute("SELECT count(DISTINCT problem_id) FROM runs WHERE checked=1").fetchone()[0],
            "distinct_premise_texts": len(premises),
        }
    return {"counts": counts, "runs": [{"id": i, "created": date, "status": status,
             "goal": goal, "result": json.loads(result)} for i, date, status, goal, result in rows]}
