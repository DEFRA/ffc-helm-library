from pathlib import Path
import subprocess

import pytest


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.parametrize(
    ("script", "description"),
    [
        ("tests/test-chart.sh", "Helm consumer rendering"),
        ("tests/test-versioning.sh", "versioning and package names"),
        ("tests/test-pipeline-scripts.sh", "publishing pipeline functions"),
    ],
    ids=["helm-consumer", "versioning", "pipeline-functions"],
)
def test_shell_suite(script: str, description: str) -> None:
    result = subprocess.run(
        ["bash", script],
        cwd=REPOSITORY_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0, (
        f"{description} failed\n\nstdout:\n{result.stdout}\n\nstderr:\n{result.stderr}"
    )
