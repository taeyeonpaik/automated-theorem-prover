"""Inventory an official release; extract untyped FOF/CNF and axiom dependencies."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import tarfile


def prepare(archive, bug_file, destination):
    destination.mkdir(parents=True, exist_ok=True)
    bugs = bug_file.read_text()
    bug_ids = set(re.findall(r'\b[A-Z]{3}\d{3}[+\-]\d+(?:\.\d+)?', bugs))
    inventory, hashes = [], {}
    with tarfile.open(archive, 'r|gz') as tar:
        for member in tar:
            parts = PurePosixPath(member.name).parts
            if not member.isfile() or len(parts) < 2:
                continue
            relative = PurePosixPath(*parts[1:])
            if '..' in relative.parts or relative.is_absolute():
                raise ValueError('Unsafe archive path')
            problem = relative.parts[0] == 'Problems' and relative.suffix == '.p'
            selected = problem and bool(re.fullmatch(r'[A-Z]{3}\d{3}[+\-].*\.p', relative.name))
            support = relative.parts[0] in {'Axioms', 'Documents'}
            if not (problem or support):
                continue
            stream = tar.extractfile(member)
            header = stream.read(min(member.size, 16384))
            if problem:
                text = header.decode('utf-8', errors='replace')
                status = re.search(r'^%\s*Status\s*:\s*(\w+)', text, re.M)
                inventory.append({'name': str(relative), 'selected': selected,
                    'language': 'FOF' if '+' in relative.name else 'CNF' if '-' in relative.name else 'other',
                    'expected_tptp_status': status[1] if status else None,
                    'known_bug': relative.stem in bug_ids, 'bytes': member.size})
            if selected or support:
                path = destination / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                digest = hashlib.sha256()
                with path.open('wb') as out:
                    out.write(header); digest.update(header)
                    while block := stream.read(1024 * 1024):
                        out.write(block); digest.update(block)
                hashes[str(relative)] = digest.hexdigest()
    archive_hash = hashlib.file_digest(archive.open('rb'), 'sha256').hexdigest()
    (destination / bug_file.name).write_text(bugs)
    manifest = {'title': 'All untyped FOF/CNF problems in TPTP 9.3.1', 'tptp_version': '9.3.1',
        'archive_url': 'https://tptp.org/TPTP/Distribution/TPTP-v9.3.1.tgz',
        'archive_sha256': archive_hash, 'bug_list_sha256': hashlib.sha256(bugs.encode()).hexdigest(),
        'selection_rule': 'Every Problems/*.p with the standard + (FOF) or - (CNF) language code; no difficulty, size, status, domain, or solver-outcome filtering. Includes are resolved and grammar checked during evaluation. Known bug-list entries run but are unscored.',
        'problem_paths': sorted(p['name'] for p in inventory if p['selected']),
        'inventory': sorted(inventory, key=lambda p:p['name']), 'files': hashes}
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({'all_problems': len(inventory), 'selected': len(manifest['problem_paths']),
        'languages': dict(Counter(p['language'] for p in inventory)), 'archive_sha256': archive_hash}, indent=2))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('bug_list', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    prepare(args.archive, args.bug_list, args.destination)
