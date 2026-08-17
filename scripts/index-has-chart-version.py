#!/usr/bin/env python3

import re
import sys
from pathlib import Path


def index_has_version(index_file: str, chart_name: str, chart_version: str) -> bool:
    lines = Path(index_file).read_text(encoding="utf-8").splitlines()
    chart_header = re.compile(rf"^  {re.escape(chart_name)}:\s*$")
    next_chart = re.compile(r"^  [^\s].*:\s*$")
    version_line = re.compile(r"^\s+version:\s*['\"]?([^'\"\s#]+)")
    in_chart = False

    for line in lines:
        if chart_header.match(line):
            in_chart = True
            continue
        if in_chart and next_chart.match(line):
            return False
        if in_chart:
            match = version_line.match(line)
            if match and match.group(1) == chart_version:
                return True
    return False


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(
            "Usage: index-has-chart-version.py INDEX_FILE CHART_NAME CHART_VERSION"
        )
    if index_has_version(*sys.argv[1:]):
        return
    raise SystemExit(1)


if __name__ == "__main__":
    main()
