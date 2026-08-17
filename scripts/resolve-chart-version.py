#!/usr/bin/env python3

import re
import sys


VERSION_PATTERN = re.compile(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)")


def parse(version):
    if not VERSION_PATTERN.fullmatch(version):
        raise ValueError(f"Invalid chart version: {version}")
    return tuple(map(int, version.split(".")))


def resolve(previous_version, current_version):
    previous = parse(previous_version)
    current = parse(current_version)

    if current[:2] < previous[:2]:
        raise ValueError(
            "Chart major/minor version cannot move backwards from "
            f"{previous[0]}.{previous[1]}.x to {current[0]}.{current[1]}.x"
        )
    if current[:2] > previous[:2]:
        return f"{current[0]}.{current[1]}.0"
    if current <= previous:
        return f"{previous[0]}.{previous[1]}.{previous[2] + 1}"
    return current_version


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: resolve-chart-version.py PREVIOUS_VERSION CURRENT_VERSION")
    try:
        print(resolve(sys.argv[1], sys.argv[2]))
    except ValueError as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main()
