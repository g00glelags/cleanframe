#!/usr/bin/env python3
"""Audit installed GTK themes for Adwaita-like blue selected backgrounds."""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


TARGET_BG_HEX = "#3584e4"
WHITE_VALUES = {"#fff", "#ffffff", "white", "rgb(255,255,255)", "rgba(255,255,255,1)"}

CSS_EXTENSIONS = {".css"}
SELECTED_MARKERS = ("selected", "selection")


@dataclass
class Finding:
    file: Path
    line: int
    selector: str
    background: str
    color: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Find selected-state CSS blocks using #3584e4 background + white text."
    )
    parser.add_argument(
        "--theme-dir",
        default=str(Path.home() / ".themes" / "CleanFrame-Light"),
        help="Installed theme directory to scan (default: ~/.themes/CleanFrame-Light)",
    )
    parser.add_argument(
        "--include-runtime",
        action="store_true",
        help="Also scan ~/.config/gtk-3.0/gtk.css and ~/.config/gtk-4.0/*.css and report GTK_THEME env.",
    )
    parser.add_argument(
        "--max-findings",
        type=int,
        default=50,
        help="Maximum findings to print (default: 50)",
    )
    return parser.parse_args()


def css_files_under(root: Path) -> Iterable[Path]:
    if not root.exists():
        return []
    return [p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in CSS_EXTENSIONS]


def normalize_value(value: str) -> str:
    s = value.strip().lower()
    s = re.sub(r"\s+", "", s)
    return s


def strip_comments(text: str) -> str:
    return re.sub(r"/\*.*?\*/", "", text, flags=re.S)


def iter_css_blocks(text: str):
    """Yield (selector, body, line_number) using a simple brace parser."""
    i = 0
    n = len(text)
    while i < n:
        open_idx = text.find("{", i)
        if open_idx == -1:
            break
        selector = text[i:open_idx].strip()
        depth = 1
        j = open_idx + 1
        while j < n and depth > 0:
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
            j += 1
        if depth != 0:
            break
        body = text[open_idx + 1 : j - 1]
        line_no = text.count("\n", 0, open_idx) + 1
        yield selector, body, line_no
        i = j


def parse_declarations(body: str) -> dict[str, str]:
    decls: dict[str, str] = {}
    for part in body.split(";"):
        if ":" not in part:
            continue
        prop, value = part.split(":", 1)
        prop = prop.strip().lower()
        value = value.strip()
        if prop and value:
            decls[prop] = value
    return decls


def is_selected_selector(selector: str) -> bool:
    s = selector.lower()
    return any(marker in s for marker in SELECTED_MARKERS)


def find_selected_blue_white(css_file: Path) -> list[Finding]:
    raw = css_file.read_text(encoding="utf-8", errors="ignore")
    text = strip_comments(raw)
    findings: list[Finding] = []
    for selector, body, line_no in iter_css_blocks(text):
        if not selector or not is_selected_selector(selector):
            continue
        decls = parse_declarations(body)
        bg_val = decls.get("background-color", decls.get("background", ""))
        fg_val = decls.get("color", "")
        if not bg_val or not fg_val:
            continue
        bg_norm = normalize_value(bg_val)
        fg_norm = normalize_value(fg_val)
        if TARGET_BG_HEX in bg_norm and fg_norm in WHITE_VALUES:
            findings.append(
                Finding(
                    file=css_file,
                    line=line_no,
                    selector=" ".join(selector.split()),
                    background=bg_val,
                    color=fg_val,
                )
            )
    return findings


def runtime_css_candidates() -> list[Path]:
    home = Path.home()
    return [
        home / ".config" / "gtk-3.0" / "gtk.css",
        home / ".config" / "gtk-4.0" / "gtk.css",
        home / ".config" / "gtk-4.0" / "gtk-dark.css",
    ]


def main() -> int:
    args = parse_args()
    theme_dir = Path(os.path.expanduser(args.theme_dir))
    files = list(css_files_under(theme_dir))
    if args.include_runtime:
        for p in runtime_css_candidates():
            if p.exists():
                files.append(p)

    if not theme_dir.exists():
        print(f"[FAIL] theme dir not found: {theme_dir}")
        return 2

    findings: list[Finding] = []
    for css_file in files:
        findings.extend(find_selected_blue_white(css_file))

    if args.include_runtime:
        gtk_theme_env = os.environ.get("GTK_THEME")
        if gtk_theme_env:
            print(f"[INFO] GTK_THEME ativo na sessão: {gtk_theme_env}")

    if findings:
        print(f"[FAIL] Encontradas {len(findings)} ocorrencias de selected azul + texto branco")
        for item in findings[: args.max_findings]:
            print(f"- {item.file}:{item.line}")
            print(f"  selector: {item.selector}")
            print(f"  background: {item.background}")
            print(f"  color: {item.color}")
        if len(findings) > args.max_findings:
            print(f"... {len(findings) - args.max_findings} ocorrencias adicionais omitidas")
        return 1

    print(f"[PASS] Nenhuma ocorrencia de selected com {TARGET_BG_HEX} + texto branco encontrada.")
    print(f"[INFO] Arquivos CSS auditados: {len(files)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
