"""Strict adapter for a documented, self-contained untyped FOF/CNF subset.

Unsupported features raise an error instead of silently changing semantics.
See docs/WALKTHROUGH.md for boundaries. This is not full TPTP conformance.
"""
import re
from pathlib import Path


class Unsupported(ValueError):
    pass


def split_top(text, separator):
    depth, start, parts = 0, 0, []
    for i, char in enumerate(text):
        if char in "([":
            depth += 1
        elif char in ")]":
            depth -= 1
        elif char == separator and depth == 0:
            parts.append(text[start:i].strip())
            start = i + 1
        if depth < 0:
            raise Unsupported("Unbalanced delimiters")
    if depth:
        raise Unsupported("Unbalanced delimiters")
    parts.append(text[start:].strip())
    return parts


def parse(text):
    expected_match = re.search(r"%\s*Status\s*:\s*(\w+)", text)
    expected = expected_match.group(1) if expected_match else None
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    text = re.sub(r"%[^\n]*", " ", text)
    if "'" in text or '"' in text:
        raise Unsupported("Quoted symbols, distinct objects, and includes are not supported")
    records = split_top(text, ".")
    if records[-1]:
        raise Unsupported("Every TPTP record must end with a period")
    premises, goals, names = [], [], set()
    negated_goal = False
    for record in records[:-1]:
        match = re.fullmatch(r"(fof|cnf)\s*\((.*)\)", record, flags=re.S)
        if not match:
            raise Unsupported("Only self-contained fof(...) and cnf(...) records are supported")
        parts = split_top(match.group(2), ",")
        if len(parts) != 3:
            raise Unsupported("Expected name, role, formula; source annotations are not supported")
        name, role, formula = parts
        if name in names:
            raise Unsupported("Duplicate formula name: " + name)
        names.add(name)
        if re.search(r"\$(?!true\b|false\b)", formula):
            raise Unsupported("Interpreted symbols other than $true/$false are not supported")
        if re.search(r"<~>|<=|~[&|]", formula):
            raise Unsupported("Reverse implication, XOR, NAND and NOR are not supported")
        formula = " ".join(formula.split())
        if role == "conjecture":
            goals.append(formula)
        elif role in {"axiom", "hypothesis", "definition", "assumption", "lemma", "theorem", "corollary", "negated_conjecture"}:
            premises.append(formula)
            negated_goal |= role == "negated_conjecture"
        else:
            raise Unsupported("Unsupported formula role: " + role)
    if not names:
        raise Unsupported("No formula records found")
    if len(goals) > 1 or (goals and negated_goal):
        raise Unsupported("Use at most one conjecture, or negated conjectures, not both")
    return {"premises": premises, "goal": goals[0] if goals else "false", "expected_tptp_status": expected}


def load(path):
    return {"name": Path(path).name, **parse(Path(path).read_text())}
