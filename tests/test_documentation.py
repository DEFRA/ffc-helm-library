from pathlib import Path
import re


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
README = REPOSITORY_ROOT / "README.md"
TEMPLATES = REPOSITORY_ROOT / "ffc-helm-library" / "templates"


def test_documented_template_files_and_names_exist() -> None:
    readme = README.read_text(encoding="utf-8")
    documented_files = re.findall(r"^- Template file: `([^`]+)`", readme, re.M)
    documented_names = re.findall(r"^- Template name: `([^`]+)`", readme, re.M)
    template_source = "\n".join(
        path.read_text(encoding="utf-8") for path in TEMPLATES.iterdir()
    )

    missing_files = [name for name in documented_files if not (TEMPLATES / name).is_file()]
    missing_names = [
        name
        for name in documented_names
        if f'define "{name}"' not in template_source
    ]

    assert not missing_files, f"README references missing template files: {missing_files}"
    assert not missing_names, f"README references missing template names: {missing_names}"


def test_readme_uses_actual_container_value_names() -> None:
    readme = README.read_text(encoding="utf-8")

    assert "containter" not in readme
    assert "requestCPU" not in readme
    assert "limitCPU" not in readme
    assert "requestCpu" in readme
    assert "limitCpu" in readme
