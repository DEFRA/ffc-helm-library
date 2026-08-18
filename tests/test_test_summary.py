from pathlib import Path
import os
import subprocess
import sys


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


def test_junit_summary(tmp_path: Path) -> None:
    results_file = tmp_path / "pytest.xml"
    results_file.write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<testsuites tests="5" failures="1" errors="1" skipped="1">
  <testsuite name="example" tests="5" failures="1" errors="1" skipped="1" />
</testsuites>
""",
        encoding="utf-8",
    )
    summary_file = tmp_path / "summary.md"
    environment = os.environ.copy()
    environment.update(
        {
            "TEST_RESULTS_FILE": str(results_file),
            "GITHUB_STEP_SUMMARY": str(summary_file),
        }
    )

    subprocess.run(
        [sys.executable, "scripts/summarize-test-results.py"],
        cwd=REPOSITORY_ROOT,
        env=environment,
        check=True,
    )

    summary = summary_file.read_text(encoding="utf-8")
    assert "2 passed, 1 failed, 1 errors, 1 skipped" in summary
    assert "| 5 | 2 | 1 | 1 | 1 |" in summary
