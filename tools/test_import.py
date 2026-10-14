"""Exercise importer relocation, class isolation, dependencies and source preservation."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
TEST = ROOT / "artifacts" / ("import_smoke_workspace_" + uuid.uuid4().hex[:8])
SOURCE = ROOT / "artifacts" / "import_smoke_source"
TEST.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
(ROOT / "artifacts" / ".gdignore").write_text("", encoding="utf-8")
tools_dir = TEST / "tools"
tools_dir.mkdir(exist_ok=True)
for name in ["import_pack.py", "build_catalog.py", "requested_assets.py"]:
    shutil.copy2(ROOT / "tools" / name, tools_dir / name)
(SOURCE / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Importer Fixture"\n', encoding="utf-8")
(SOURCE / "Helper.gd").write_text('class_name ImportSmokeHelper extends RefCounted\nstatic func value(): return 42\n', encoding="utf-8")
(SOURCE / "main.gd").write_text('extends Node3D\nconst Helper = preload("res://Helper.gd")\n@export var intensity: float = 1.0\nfunc _ready(): print("IMPORT_SMOKE_OK ", Helper.value())\n', encoding="utf-8")
(SOURCE / "effect.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://main.gd" id="1"]\n[node name="Effect" type="Node3D"]\nscript=ExtResource("1")\n', encoding="utf-8")
hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.iterdir()}
destination = TEST / "vendor" / "local_smoke"
if destination.exists():
    raise RuntimeError("Use a fresh artifacts/import_smoke_workspace to rerun this isolated check")
subprocess.run([sys.executable, str(tools_dir / "import_pack.py"), "--source", str(SOURCE), "--id", "smoke", "--name", "Import Smoke", "--scene", "effect.tscn"], check=True, cwd=str(TEST))
assert hashes == {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCE.iterdir()}, "Source was modified"
assert "LocalSmokeImportSmokeHelper" in (destination / "Helper.gd").read_text(encoding="utf-8")
assert 'preload("res://vendor/local_smoke/Helper.gd")' in (destination / "main.gd").read_text(encoding="utf-8")
data = json.loads((TEST / "data" / "catalog.json").read_text(encoding="utf-8"))
assert data[0]["path"] == "res://vendor/local_smoke/effect.tscn"
(TEST / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Import Smoke"\nrun/main_scene="res://vendor/local_smoke/effect.tscn"\n', encoding="utf-8")
engine = r"D:\Studio\AI\Projects\godot\tools\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
result = subprocess.run([engine, "--headless", "--path", str(TEST), "--quit-after", "2"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
assert result.returncode == 0 and "IMPORT_SMOKE_OK 42" in result.stdout, result.stdout
assert "ERROR" not in result.stdout, result.stdout
print("IMPORT_TEST_PASS: paths, namespaced class, dependencies, preserved source, runtime")
