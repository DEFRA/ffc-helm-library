#!/usr/bin/env python3

import re
import sys
from pathlib import Path


def set_chart_version(chart_file: str, old_version: str, new_version: str) -> None:
    path = Path(chart_file)
    contents = path.read_text(encoding="utf-8")
    pattern = re.compile(
        r"^(\s*version:\s*)(['\"]?)([^'\"\s#]+)(['\"]?)(.*)$",
        re.MULTILINE,
    )

    def replace(match: re.Match[str]) -> str:
        if match.group(3) != old_version:
            return match.group(0)
        if match.group(2) != match.group(4):
            raise ValueError("Chart version has mismatched quotes")
        return (
            f"{match.group(1)}{match.group(2)}{new_version}"
            f"{match.group(4)}{match.group(5)}"
        )

    updated, substitutions = pattern.subn(replace, contents, count=1)
    if substitutions != 1 or updated == contents:
        raise ValueError("Unable to update Chart.yaml version")
    path.write_text(updated, encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(
            "Usage: set-chart-version.py CHART_FILE OLD_VERSION NEW_VERSION"
        )
    try:
        set_chart_version(*sys.argv[1:])
    except ValueError as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main()
