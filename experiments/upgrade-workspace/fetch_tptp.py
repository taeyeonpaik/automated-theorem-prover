"""Freeze QED's small, deterministic subset of the official TPTP archive.

No solver outcomes or difficulty ratings are used to select problems.
Source files are copied verbatim, with dependencies and redistribution notice.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

VERSION = "3.3.0"
URL = "https://tptp.org/TPTP/Archive/TPTP-v3.3.0.tgz"
SHA256 = "299e00b71c01a357626ff6238b005b2856bd1b16a24a7f5b939ec343ee526e3f"
DEFAULT = Path(__file__).resolve().parent / "benchmarks/tptp-v3.3.0"
SMOKE = ["SYN075-1", "MGT031-1", "MGT041-2", "NLP114-1", "BOO003-4",
         "BOO027-1", "SYN075+1", "MGT019+2", "KRS063+1", "KRS018+1"]


def freeze(archive, destination):
    raw = Path(archive).read_bytes()
    if hashlib.sha256(raw).hexdigest() != SHA256:
        raise ValueError("Official archive checksum mismatch; no files extracted")
    prefix = f"TPTP-v{VERSION}/"
    with tarfile.open(fileobj=io.BytesIO(raw)) as outer:
        bugs = outer.extractfile(prefix + "BuggedProblems-v3.3.0").read()
        inner = outer.extractfile(prefix + "TPTP-v3.3.0.tar.gz").read()
    with tarfile.open(fileobj=io.BytesIO(inner)) as library:
        members = {m.name[len(prefix):]: m for m in library if m.isfile() and m.name.startswith(prefix)}
        selection = []
        for domain in ("SYN", "PUZ", "ALG"):
            for sign in ("+", "-"):
                pattern = f"Problems/{domain}/{domain}" + r"(?!000)\d{3}" + re.escape(sign) + r"1\.p"
                available = sorted(p for p in members if re.fullmatch(pattern, p))
                if len(available) < 9:
                    raise ValueError("Not enough files for the fixed selection rule")
                selection.extend(available[:9])
        selection.extend(f"Problems/{name[:3]}/{name}.p" for name in SMOKE)
        if len(set(selection)) != 64:
            raise ValueError("Expected 64 distinct benchmark problems")
        selected_ids = {Path(p).stem for p in selection}
        listed_bugs = set(re.findall(r"[A-Z]{3}\d{3}[+\-]\d+(?:\.\d+)?", bugs.decode()))
        if selected_ids & listed_bugs:
            raise ValueError("Selection overlaps archived bug list; review before evaluating")
        data = {"BuggedProblems-v3.3.0": bugs}
        def copy(relative):
            if relative in data:
                return
            if relative not in members:
                raise ValueError("Missing archive dependency: " + relative)
            data[relative] = library.extractfile(members[relative]).read()
            for include in re.findall(rb"^\s*include\s*\(\s*'([^']+)'", data[relative], flags=re.M):
                copy(include.decode())
        for path in selection + ["Documents/ReadMe"]:
            copy(path)
    destination = Path(destination)
    for relative, content in data.items():
        path = destination / relative
        if path.exists() and path.read_bytes() != content:
            raise ValueError(f"Refusing to overwrite modified source: {path}")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
    manifest = {"title": "QED TPTP 64", "tptp_version": VERSION, "archive_url": URL,
                "archive_sha256": SHA256,
                "selection_rule": "First nine sorted non-000 DDDnnn+1.p and DDDnnn-1.p files in each of SYN, PUZ, ALG; plus ten untyped Quick Guide examples. No filtering by outcome or rating.",
                "quick_guide_url": "https://tptp.org/UserDocs/QuickGuide/",
                "quick_guide_ids": SMOKE, "bug_list_overlap": [],
                "problem_paths": selection,
                "files": {p: hashlib.sha256(b).hexdigest() for p, b in sorted(data.items())}}
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Frozen {len(selection)} problems and {len(data) - len(selection)} supporting files in {destination}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", type=Path, help="Use an already downloaded official archive")
    parser.add_argument("--destination", type=Path, default=DEFAULT)
    args = parser.parse_args()
    if args.archive:
        freeze(args.archive, args.destination)
    else:
        with tempfile.TemporaryDirectory(prefix="qed-tptp-") as tmp:
            archive = Path(tmp) / "archive.tgz"
            subprocess.run(["curl", "--fail", "--location", "--max-time", "120", URL, "--output", str(archive)], check=True)
            freeze(archive, args.destination)


if __name__ == "__main__":
    main()
