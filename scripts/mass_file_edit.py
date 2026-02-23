#!/usr/bin/env python3
"""Batch text replacement utility for SCSS/CSS/theme files.

Safe by default: runs in dry-run mode unless --apply is provided.
"""

from __future__ import annotations

import argparse
import difflib
import re
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch replace text across files (plain text or regex)."
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Root directory for file discovery (default: current directory).",
    )
    parser.add_argument(
        "--glob",
        dest="globs",
        action="append",
        required=True,
        help="Glob pattern to include (repeatable), e.g. 'src/_sass/**/*.scss'.",
    )
    parser.add_argument(
        "--exclude-glob",
        dest="exclude_globs",
        action="append",
        default=[],
        help="Glob pattern to exclude (repeatable).",
    )
    parser.add_argument("--find", required=True, help="String or regex to find.")
    parser.add_argument("--replace", required=True, help="Replacement text.")
    parser.add_argument(
        "--regex",
        action="store_true",
        help="Interpret --find as a regular expression.",
    )
    parser.add_argument(
        "--ignore-case",
        action="store_true",
        help="Case-insensitive matching (plain or regex).",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write changes to disk. Without this flag, runs in dry-run mode.",
    )
    parser.add_argument(
        "--backup-ext",
        default="",
        help="Optional backup extension (example: .bak) when using --apply.",
    )
    parser.add_argument(
        "--max-diff-lines",
        type=int,
        default=80,
        help="Max diff lines printed per file in dry-run mode.",
    )
    return parser.parse_args()


def discover_files(root: Path, globs: list[str], exclude_globs: list[str]) -> list[Path]:
    files: set[Path] = set()
    for pattern in globs:
        files.update(path for path in root.glob(pattern) if path.is_file())

    excluded: set[Path] = set()
    for pattern in exclude_globs:
        excluded.update(path for path in root.glob(pattern) if path.is_file())

    return sorted(files - excluded)


def replace_plain(content: str, needle: str, replacement: str, ignore_case: bool) -> tuple[str, int]:
    if not ignore_case:
        count = content.count(needle)
        return content.replace(needle, replacement), count

    pattern = re.compile(re.escape(needle), re.IGNORECASE)
    new_content, count = pattern.subn(replacement, content)
    return new_content, count


def replace_regex(content: str, pattern_text: str, replacement: str, ignore_case: bool) -> tuple[str, int]:
    flags = re.MULTILINE
    if ignore_case:
        flags |= re.IGNORECASE
    pattern = re.compile(pattern_text, flags)
    return pattern.subn(replacement, content)


def make_diff(path: Path, old: str, new: str, max_lines: int) -> str:
    diff_lines = list(
        difflib.unified_diff(
            old.splitlines(),
            new.splitlines(),
            fromfile=str(path),
            tofile=str(path),
            lineterm="",
        )
    )
    if len(diff_lines) > max_lines:
        shown = diff_lines[:max_lines]
        shown.append(f"... diff truncated ({len(diff_lines) - max_lines} lines omitted)")
        diff_lines = shown
    return "\n".join(diff_lines)


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    files = discover_files(root, args.globs, args.exclude_globs)

    if not files:
        print("No files matched.", file=sys.stderr)
        return 1

    total_files_changed = 0
    total_replacements = 0

    for path in files:
        try:
            original = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            print(f"[skip] non-utf8 file: {path}")
            continue

        if args.regex:
            updated, count = replace_regex(original, args.find, args.replace, args.ignore_case)
        else:
            updated, count = replace_plain(original, args.find, args.replace, args.ignore_case)

        if count == 0 or updated == original:
            continue

        total_files_changed += 1
        total_replacements += count
        print(f"[match] {path} (replacements={count})")

        if args.apply:
            if args.backup_ext:
                backup_path = path.with_name(path.name + args.backup_ext)
                backup_path.write_text(original, encoding="utf-8")
            path.write_text(updated, encoding="utf-8")
        else:
            print(make_diff(path, original, updated, args.max_diff_lines))

    mode = "apply" if args.apply else "dry-run"
    print(
        f"[summary] mode={mode} files_changed={total_files_changed} replacements={total_replacements}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
