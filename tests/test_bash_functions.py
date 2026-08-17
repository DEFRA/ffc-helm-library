from pathlib import Path
import os
import shutil
import subprocess

import pytest


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = REPOSITORY_ROOT / "scripts"
MOCK_BIN = REPOSITORY_ROOT / "tests" / "mocks"


def run_script(
    script: str,
    environment: dict[str, str],
    *,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    process_environment = os.environ.copy()
    process_environment.update(environment)
    result = subprocess.run(
        ["bash", str(SCRIPTS / script)],
        cwd=REPOSITORY_ROOT,
        env=process_environment,
        capture_output=True,
        text=True,
        check=False,
    )
    if check:
        assert result.returncode == 0, result.stdout + result.stderr
    return result


def output_value(output_file: Path, name: str) -> str:
    prefix = f"{name}="
    for line in output_file.read_text(encoding="utf-8").splitlines():
        if line.startswith(prefix):
            return line.removeprefix(prefix)
    raise AssertionError(f"Output {name!r} not found in {output_file}")


@pytest.mark.parametrize(
    ("event_name", "ref_name", "requested", "expected"),
    [
        ("push", "feature", "auto", "alpha"),
        ("pull_request", "42/merge", "auto", "beta"),
        ("push", "master", "auto", "release"),
        ("merge_group", "gh-readonly-queue/master/pr-42", "auto", "validation"),
        ("workflow_dispatch", "feature", "beta", "beta"),
    ],
    ids=["alpha", "beta", "release", "merge-validation", "manual-beta"],
)
def test_bash_channel_selection(
    tmp_path: Path,
    event_name: str,
    ref_name: str,
    requested: str,
    expected: str,
) -> None:
    github_output = tmp_path / "github-output"
    run_script(
        "select-package-channel.sh",
        {
            "EVENT_NAME": event_name,
            "REF_NAME": ref_name,
            "REQUESTED_CHANNEL": requested,
            "GITHUB_OUTPUT": str(github_output),
        },
    )
    assert output_value(github_output, "channel") == expected


def test_bash_release_channel_rejected_outside_master(tmp_path: Path) -> None:
    result = run_script(
        "select-package-channel.sh",
        {
            "EVENT_NAME": "workflow_dispatch",
            "REF_NAME": "feature",
            "REQUESTED_CHANNEL": "release",
            "GITHUB_OUTPUT": str(tmp_path / "github-output"),
        },
        check=False,
    )
    assert result.returncode != 0
    assert "release channel is allowed only on master" in result.stderr


@pytest.mark.parametrize(
    ("event_name", "ref_name", "pr_number", "mock_output", "expected"),
    [
        ("pull_request", "42/merge", "42", "README.md", "false"),
        (
            "pull_request",
            "42/merge",
            "42",
            "ffc-helm-library/templates/_deployment.yaml",
            "true",
        ),
        ("push", "feature", "", "1", "false"),
        ("push", "feature", "", "0", "true"),
        ("push", "master", "", "", "true"),
        ("merge_group", "gh-readonly-queue/master/pr-42", "", "", "false"),
    ],
    ids=[
        "documentation-pr",
        "chart-pr",
        "branch-with-pr",
        "branch-without-pr",
        "master",
        "merge-group",
    ],
)
def test_bash_package_decision(
    tmp_path: Path,
    event_name: str,
    ref_name: str,
    pr_number: str,
    mock_output: str,
    expected: str,
) -> None:
    github_output = tmp_path / "github-output"
    run_script(
        "decide-build.sh",
        {
            "PATH": f"{MOCK_BIN}:{os.environ['PATH']}",
            "MOCK_GH_OUTPUT": mock_output,
            "EVENT_NAME": event_name,
            "REF_NAME": ref_name,
            "PR_NUMBER": pr_number,
            "REPOSITORY_OWNER": "DEFRA",
            "GH_TOKEN": "test-token",
            "GITHUB_REPOSITORY": "DEFRA/ffc-helm-library",
            "GITHUB_OUTPUT": str(github_output),
        },
    )
    assert output_value(github_output, "should_package") == expected


@pytest.mark.parametrize(
    ("denied_repository", "expected_success"),
    [("", True), ("DEFRA/ffc-helm-repository", False)],
    ids=["allowed", "denied"],
)
def test_bash_publisher_permissions(
    denied_repository: str,
    expected_success: bool,
) -> None:
    result = run_script(
        "verify-publisher-token.sh",
        {
            "PATH": f"{MOCK_BIN}:{os.environ['PATH']}",
            "MOCK_DENIED_REPOSITORY": denied_repository,
            "GH_TOKEN": "test-token",
            "PUBLISHER_REPOSITORIES": (
                "DEFRA/ffc-helm-library DEFRA/ffc-helm-repository"
            ),
        },
        check=False,
    )
    assert (result.returncode == 0) is expected_success


@pytest.mark.parametrize(
    ("version", "expected_success"),
    [("5.2.2", True), ("5.2", False)],
    ids=["valid-semver", "invalid-semver"],
)
def test_bash_chart_version_validation(
    tmp_path: Path,
    version: str,
    expected_success: bool,
) -> None:
    chart_directory = tmp_path / "chart"
    chart_directory.mkdir()
    source = (REPOSITORY_ROOT / "ffc-helm-library" / "Chart.yaml").read_text(
        encoding="utf-8"
    )
    current_version = subprocess.run(
        [
            "python3",
            str(SCRIPTS / "chart-version.py"),
            str(REPOSITORY_ROOT / "ffc-helm-library" / "Chart.yaml"),
        ],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    (chart_directory / "Chart.yaml").write_text(
        source.replace(f"version: {current_version}", f"version: {version}"),
        encoding="utf-8",
    )
    result = run_script(
        "validate-chart-version.sh",
        {
            "CHART_DIRECTORY": str(chart_directory),
            "GITHUB_OUTPUT": str(tmp_path / "github-output"),
        },
        check=False,
    )
    assert (result.returncode == 0) is expected_success


@pytest.mark.parametrize(
    ("channel", "prerelease"),
    [
        ("alpha", "alpha.42"),
        ("beta", "beta.42"),
        ("release", ""),
    ],
    ids=["alpha", "beta", "release"],
)
def test_bash_package_names(
    tmp_path: Path,
    channel: str,
    prerelease: str,
) -> None:
    chart_directory = tmp_path / "ffc-helm-library"
    shutil.copytree(REPOSITORY_ROOT / "ffc-helm-library", chart_directory)
    chart_version = subprocess.run(
        ["python3", str(SCRIPTS / "chart-version.py"), str(chart_directory / "Chart.yaml")],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    expected_version = f"{chart_version}-{prerelease}" if prerelease else chart_version
    github_output = tmp_path / "github-output"
    run_script(
        "package-chart.sh",
        {
            "RUNNER_TEMP": str(tmp_path),
            "CHART_DIRECTORY": str(chart_directory),
            "CHART_VERSION": chart_version,
            "CHANNEL": channel,
            "BUILD_NUMBER": "42",
            "GITHUB_OUTPUT": str(github_output),
        },
    )
    assert output_value(github_output, "version") == expected_version
    assert (tmp_path / "chart-package" / f"ffc-helm-library-{expected_version}.tgz").is_file()


@pytest.mark.parametrize(
    ("chart_name", "chart_version", "expected_success"),
    [
        ("ffc-helm-library", "5.2.2-beta.42", True),
        ("ffc-helm-library", "9.9.9", False),
        ("missing-chart", "5.2.2-beta.42", False),
    ],
    ids=["found", "unknown-version", "wrong-chart"],
)
def test_bash_index_version_lookup(
    chart_name: str,
    chart_version: str,
    expected_success: bool,
) -> None:
    result = subprocess.run(
        [
            "python3",
            str(SCRIPTS / "index-has-chart-version.py"),
            str(REPOSITORY_ROOT / "tests" / "fixtures" / "index.yaml"),
            chart_name,
            chart_version,
        ],
        cwd=REPOSITORY_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    assert (result.returncode == 0) is expected_success
