#!/usr/bin/env python3
"""Turns analyzer and test results into GitHub Actions annotations.

Usage:
  report.py analyze <dart-analyze-machine-output> <workspace>
  report.py test <flutter-test-json-file> <workspace>

Issues are grouped into a few annotations (GitHub keeps only about ten error
annotations per step), so the whole list stays visible on the pull request.
The exit code is 1 when there is at least one analyzer issue or failed test.
"""
import json
import os
import sys

CHUNK = 40


def _escape(text):
    return text.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')


def _emit(level, title, lines):
    for start in range(0, len(lines), CHUNK):
        part = lines[start:start + CHUNK]
        header = f'{title} {start + 1}-{start + len(part)} of {len(lines)}'
        print(f'::{level} title={header}::{_escape(chr(10).join(part))}')


def _relative(path, root):
    if path.startswith(root):
        return os.path.relpath(path, root)
    return path


def analyze(path, root):
    issues = []
    with open(path, encoding='utf-8', errors='replace') as handle:
        for raw in handle:
            parts = raw.rstrip('\n').split('|')
            if len(parts) < 8 or parts[0] not in ('ERROR', 'WARNING', 'INFO'):
                if raw.strip():
                    print(raw.rstrip('\n'))
                continue
            severity, _, code, file_path, line, column = parts[:6]
            message = '|'.join(parts[7:])
            issues.append(
                f'{_relative(file_path, root)}:{line}:{column} '
                f'{severity} {code.lower()}: {message}')
    for issue in issues:
        print(issue)
    if issues:
        _emit('error', 'analyze', issues)
        return 1
    print('analyze: no issues')
    return 0


def test(path, root):
    if not os.path.exists(path):
        print('::error title=test::No test results file was produced')
        return 1
    names, errors, failed = {}, {}, []
    total = skipped = 0
    with open(path, encoding='utf-8', errors='replace') as handle:
        for raw in handle:
            raw = raw.strip()
            if not raw:
                continue
            try:
                event = json.loads(raw)
            except json.JSONDecodeError:
                continue
            events = event if isinstance(event, list) else [event]
            for item in events:
                kind = item.get('type')
                if kind == 'testStart':
                    info = item['test']
                    location = info.get('root_url') or info.get('url') or ''
                    location = _relative(location.replace('file://', ''), root)
                    line = info.get('root_line') or info.get('line') or ''
                    names[info['id']] = f"{info.get('name', '?')} ({location}:{line})"
                elif kind == 'error':
                    stack = '\n'.join(
                        (item.get('stackTrace') or '').splitlines()[:8])
                    text = f"{item.get('error', '')}\n{stack}".strip()
                    errors.setdefault(item['testID'], []).append(text[:1500])
                elif kind == 'testDone':
                    result = item.get('result')
                    if item.get('hidden') and result == 'success':
                        continue
                    total += 1
                    if item.get('skipped'):
                        skipped += 1
                    if result != 'success':
                        failed.append(item['testID'])
    lines = []
    for test_id in failed:
        lines.append(f'FAILED {names.get(test_id, test_id)}')
        for text in errors.get(test_id, []):
            lines.extend('    ' + row for row in text.splitlines())
    summary = f'tests: {total} run, {len(failed)} failed, {skipped} skipped'
    print(summary)
    for row in lines:
        print(row)
    print(f'::notice title=tests::{summary}')
    if failed:
        _emit('error', 'tests', lines)
        return 1
    return 0


if __name__ == '__main__':
    mode, source, workspace = sys.argv[1], sys.argv[2], sys.argv[3]
    workspace = workspace.rstrip('/') + '/'
    sys.exit(analyze(source, workspace) if mode == 'analyze' else test(source, workspace))
