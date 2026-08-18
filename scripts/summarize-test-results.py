#!/usr/bin/env python3

import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def totals(results_file: Path) -> dict[str, int]:
    root = ET.parse(results_file).getroot()
    suites = [root] if root.tag == "testsuite" else list(root.findall("testsuite"))
    summary = {"tests": 0, "failures": 0, "errors": 0, "skipped": 0}
    for suite in suites:
        for key in summary:
            summary[key] += int(suite.attrib.get(key, 0))
    return summary


def render(summary: dict[str, int]) -> str:
    passed = (
        summary["tests"]
        - summary["failures"]
        - summary["errors"]
        - summary["skipped"]
    )
    icon = "✅" if summary["failures"] == 0 and summary["errors"] == 0 else "❌"
    return "\n".join(
        [
            "## Test results",
            "",
            f"{icon} **{passed} passed, {summary['failures']} failed, "
            f"{summary['errors']} errors, {summary['skipped']} skipped**",
            "",
            "| Total | Passed | Failed | Errors | Skipped |",
            "| ---: | ---: | ---: | ---: | ---: |",
            f"| {summary['tests']} | {passed} | {summary['failures']} | "
            f"{summary['errors']} | {summary['skipped']} |",
            "",
        ]
    )


def main() -> None:
    results_file = Path(os.environ.get("TEST_RESULTS_FILE", "test-results/pytest.xml"))
    summary_file = os.environ.get("GITHUB_STEP_SUMMARY")

    if not results_file.is_file():
        message = "## Test results\n\n⚠️ The test report was not produced.\n"
    else:
        message = render(totals(results_file))

    if summary_file:
        with Path(summary_file).open("a", encoding="utf-8") as output:
            output.write(message)
    else:
        sys.stdout.write(message)


if __name__ == "__main__":
    main()
