#!/usr/bin/env python3
"""Check Compose modes and the student artifacts with the Python standard library."""

import json
import os
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
COMPONENTS = {"router", "access", "server", "victim", "attack"}


def compose_config(*files):
    command = ["docker", "compose", "--env-file", ".env.example"]
    for file in files:
        command.extend(["-f", file])
    command.extend(["config", "--format", "json"])
    environment = {
        key: value for key, value in os.environ.items()
        if not key.startswith(("LAB_", "ARP_LAB_"))
    }
    result = subprocess.run(
        command, cwd=ROOT, env=environment, check=True, capture_output=True, text=True
    )
    return json.loads(result.stdout)


def check_group(model, group):
    services = model["services"]
    assert {name for name in services if name.startswith(group + "-")} == {
        group + "-" + component for component in COMPONENTS
    }, group
    for component in COMPONENTS:
        service = services[group + "-" + component]
        assert "build" not in service, (group, component, "unexpected default build")
        assert service["image"].startswith("ghcr.io/"), service["image"]
        assert not service.get("privileged", False), (group, component)
    capture = next(
        mount for mount in services[group + "-router"]["volumes"]
        if mount["target"] == "/captures"
    )
    assert capture["type"] == "bind", capture
    assert Path(capture["source"]) == ROOT / "captures" / group, capture


default = compose_config("compose.yaml")
assert len(default["services"]) == 5, "default entry point must enable g01"
check_group(default, "g01")
second = compose_config("compose.g02.yaml")
check_group(second, "g02")

combined = compose_config("compose.g01.yaml", "compose.g02.yaml")
assert len(combined["services"]) == 10
subnets = [
    ipam["subnet"]
    for network in combined["networks"].values()
    for ipam in network.get("ipam", {}).get("config", [])
]
assert len(subnets) == 4 and len(set(subnets)) == 4, subnets
ports = [
    (port["host_ip"], port["published"], port["protocol"])
    for service in combined["services"].values()
    for port in service.get("ports", [])
]
assert len(ports) == len(set(ports)), "groups share a host port"

local = compose_config("compose.yaml", "compose.build.yaml")
for component in COMPONENTS:
    service = local["services"]["g01-" + component]
    assert service["image"] == "arp-laboratory-" + component + ":local", service
    assert Path(service["build"]["context"]) == ROOT / "containers" / component
    assert service["pull_policy"] == "build"

for source in [ROOT / "README.md", *ROOT.glob("docs/**/*.md")]:
    for target in re.findall(r"!?\[[^\]]*\]\(([^)\n]+)\)", source.read_text(encoding="utf-8-sig")):
        if re.match(r"^(https?://|mailto:|#)", target):
            continue
        target = unquote(target.split("#")[0].split("?")[0])
        assert (source.parent / target).exists(), (source.relative_to(ROOT), target)

for name in ("student-handout", "student-handout-macos"):
    folder = ROOT / "docs" / "handouts"
    pdf = (folder / (name + ".pdf")).read_bytes()
    assert pdf.startswith(b"%PDF-") and b"%%EOF" in pdf[-100:], name
    assert len(pdf) > 100_000, (name, "PDF unexpectedly small")
    markdown = folder / (name + ".md")
    text = markdown.read_text(encoding="utf-8-sig")
    assert text.count("<!-- page -->") == 9, name
    assert "SIGUSR1" in text and "captures/g01" in text.replace("\\", "/"), name
    with ZipFile(folder / (name + "-markdown.zip")) as archive:
        assert archive.testzip() is None, name
        assert archive.read(markdown.name) == markdown.read_bytes(), name
        images = re.findall(r"\]\((handout-images/[^)]+)\)", text)
        for image in images:
            assert archive.read(image) == (folder / image).read_bytes(), (name, image)

print("Validated GHCR defaults, local builds, two-group isolation, links, PDFs and Markdown packages.")
