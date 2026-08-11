"""Untyped TPTP adapter; includes stay within an explicit library root.

Annotations are metadata, not premises. Unsupported logic is never discarded.
The OCaml parser remains responsible for checking the formula grammar.
"""
import hashlib
import re
from pathlib import Path


class Unsupported(ValueError):
    pass


def strip_comments(text):
    token = r"'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"|%[^\n]*|/\*.*?\*/"
    return re.sub(token, lambda m: " " if m[0].startswith(("%", "/*")) else m[0], text, flags=re.S)


def split_top(text, separator):
    stack, quote, escaped, start, parts = [], None, False, 0, []
    for i, char in enumerate(text):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in "'\"":
            quote = char
        elif char in "([":
            stack.append(char)
        elif char in ")]":
            if not stack or stack.pop() != {")": "(", "]": "["}[char]:
                raise Unsupported("Unbalanced delimiters")
        elif char == separator and not stack:
            parts.append(text[start:i].strip())
            start = i + 1
    if stack or quote:
        raise Unsupported("Unclosed delimiter or quote")
    parts.append(text[start:].strip())
    return parts


def unquote(name):
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*|[0-9]+", name):
        return name
    if re.fullmatch(r"'(?:\\.|[^'\\])*'", name):
        return re.sub(r"\\(.)", r"\1", name[1:-1])
    raise Unsupported("Unsupported formula name: " + name)


def records(text, resolver=None):
    pieces = split_top(strip_comments(text), ".")
    if pieces[-1]:
        raise Unsupported("Every TPTP record must end with a period")
    result = []
    for piece in pieces[:-1]:
        match = re.fullmatch(r"(fof|cnf|include)\s*\((.*)\)", piece, flags=re.S)
        if not match:
            raise Unsupported("Only untyped fof, cnf, and local include records are supported")
        language, body = match.groups()
        parts = split_top(body, ",")
        if language == "include":
            if resolver is None:
                raise Unsupported("Includes need load(path, root=library_root)")
            if len(parts) not in (1, 2) or not re.fullmatch(r"'[^'\\]+'", parts[0]):
                raise Unsupported("Malformed include")
            included = resolver(parts[0][1:-1])
            if len(parts) == 2:
                if not (parts[1].startswith("[") and parts[1].endswith("]")):
                    raise Unsupported("Malformed include selection")
                selection = parts[1][1:-1].strip()
                names = {unquote(n) for n in split_top(selection, ",")} if selection else set()
                if names - {r[1] for r in included}:
                    raise Unsupported("Include selection names a missing formula")
                included = [r for r in included if r[1] in names]
            result.extend(included)
        else:
            if not 3 <= len(parts) <= 5:
                raise Unsupported("Expected name, role, formula, and optional annotations")
            result.append((language, unquote(parts[0]), parts[1], parts[2]))
    return result


def problem(text, entries):
    expected = re.search(r"^%\s*Status\s*:\s*(\w+)", text, flags=re.M)
    premises, goals, names = [], [], set()
    negated_goal = False
    for language, name, role, formula in entries:
        if name in names:
            raise Unsupported("Duplicate formula name: " + name)
        names.add(name)
        if "'" in formula or '"' in formula:
            raise Unsupported("Quoted formula symbols and distinct objects are not supported")
        if re.search(r"\$(?!true\b|false\b)", formula):
            raise Unsupported("Interpreted symbols other than $true/$false are not supported")
        if re.search(r"<~>|<=(?!>)|~[&|]", formula):
            raise Unsupported("Reverse implication, XOR, NAND and NOR are not supported")
        if re.search(r"\b(forall|exists|true|false)\b", formula.replace("$true", "").replace("$false", "")):
            raise Unsupported("A TPTP symbol collides with a reserved QED keyword")
        formula = " ".join(formula.split())
        if role == "conjecture":
            if language != "fof":
                raise Unsupported("A CNF problem cannot contain a positive conjecture")
            goals.append(formula)
        elif role in {"axiom", "hypothesis", "definition", "assumption", "lemma", "theorem", "corollary", "negated_conjecture"} or (role == "plain" and language == "cnf"):
            premises.append(formula)
            negated_goal |= role == "negated_conjecture"
        else:
            raise Unsupported("Unsupported formula role: " + role)
    if not names:
        raise Unsupported("No formula records found")
    if len(goals) > 1 or (goals and negated_goal):
        raise Unsupported("Use at most one conjecture, or negated conjectures, not both")
    return {"premises": premises, "goal": goals[0] if goals else "false",
            "expected_tptp_status": expected.group(1) if expected else None,
            "formula_count": len(entries), "languages": sorted({r[0] for r in entries})}


def parse(text):
    return problem(text, records(text))


def load(path, root=None, max_source_bytes=None):
    path = Path(path).resolve()
    root = Path(root).resolve() if root else path.parent
    sources, visiting = {}, set()
    source_bytes = 0
    def read(current):
        nonlocal source_bytes
        current = current.resolve()
        if not current.is_relative_to(root):
            raise Unsupported("Include escapes the TPTP library root")
        if current in visiting or len(visiting) >= 32:
            raise Unsupported("Cyclic or excessively nested include")
        source_bytes += current.stat().st_size
        if max_source_bytes is not None and source_bytes > max_source_bytes:
            raise Unsupported("Source expansion exceeds benchmark byte budget")
        content = current.read_bytes()
        sources[str(current.relative_to(root))] = hashlib.sha256(content).hexdigest()
        visiting.add(current)
        result = records(content.decode(), lambda relative: read(root / relative))
        visiting.remove(current)
        return result
    entries = read(path)
    return {"name": path.name, **problem(path.read_text(), entries), "source_hashes": sources}
