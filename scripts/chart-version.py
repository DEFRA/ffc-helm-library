#!/usr/bin/env python3

import re
import sys
from pathlib import Path


def read_chart(source: str) -> str:
    if source == "-":
        return sys.stdin.read()
    return Path(source).read_text(encoding="utf-8")


if len(sys.argv) != 2:
    raise SystemExit("Usage: chart-version.py <Chart.yaml|->")

match = re.search(
    r"^version:\s*['\"]?([^'\"\s#]+)",
    read_chart(sys.argv[1]),
    flags=re.MULTILINE,
)
if not match:
    raise SystemExit("Chart.yaml does not contain a version")

print(match.group(1))
