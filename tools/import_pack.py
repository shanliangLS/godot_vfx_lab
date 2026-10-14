"""Import a user-owned full Godot asset folder without modifying its original."""
import argparse
import json
from pathlib import Path
import re
import shutil
from build_catalog import build

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--source", required=True, help="Original project root or folder containing res:// assets")
parser.add_argument("--id", required=True, help="Unique lowercase ASCII pack identifier")
parser.add_argument("--name", required=True)
parser.add_argument("--category", default="攻击 / 刀光")
parser.add_argument("--mode", default="static", choices=["static", "hit", "slash", "beam", "projectile", "trail", "area"])
parser.add_argument("--url", default="")
parser.add_argument("--license", default="以用户持有的原资源许可为准")
parser.add_argument("--scene", action="append", help="Optional relative scenes; may be repeated")
args = parser.parse_args()
if not re.fullmatch(r"[a-z][a-z0-9_]{1,63}", args.id):
    parser.error("id must be lowercase letters, numbers and underscores")
source = Path(args.source).resolve()
if not source.is_dir():
    parser.error("source must be the complete unpacked folder")
destination = (ROOT / "vendor" / ("local_" + args.id)).resolve()
if source == ROOT or source in destination.parents:
    parser.error("source must not contain the destination")
if ROOT.resolve() not in destination.parents or destination.exists():
    parser.error("destination is outside the project or already exists; choose another id")
shutil.copytree(source, destination, ignore=shutil.ignore_patterns(".godot", ".git", "__pycache__"))
project = destination / "project.godot"
if project.exists(): project.rename(destination / "project.godot.upstream")
prefix = "res://" + destination.relative_to(ROOT).as_posix() + "/"
classes = {}
for f in destination.rglob("*.gd"):
    for name in re.findall(r"^class_name\s+(\w+)", f.read_text(encoding="utf-8-sig"), re.M):
        classes[name] = "Local" + args.id.title().replace("_", "") + name
for f in destination.rglob("*"):
    if f.suffix not in [".gd", ".tscn", ".tres", ".gdshader", ".gdshaderinc"]:
        continue
    text = f.read_text(encoding="utf-8-sig")
    text = re.sub(r"res://(?!vendor/)", prefix, text)
    text = re.sub(r'\s+uid="uid://[^"]+"', "", text)
    for old, new in classes.items(): text = re.sub(r"\b" + old + r"\b", new, text)
    for old, new in classes.items(): text = text.replace(new + ".gd", old + ".gd")
    f.write_text(text, encoding="utf-8")
scenes = [destination / p for p in args.scene] if args.scene else sorted(destination.rglob("*.tscn"))
base = {"id": args.id, "name": args.name, "category": args.category, "url": args.url, "license": args.license, "status": "installed", "directory": prefix, "description": "用户持有的本地成品资源；复制完整依赖并隔离资源路径。"}
entries = []
for scene in scenes:
    if not scene.exists() or destination not in scene.resolve().parents:
        parser.error("scene does not exist inside imported pack")
    text = scene.read_text(encoding="utf-8")
    node = re.search(r"\[node[^\]]+\]", text)
    if not node or ('type="Control"' in node.group() or 'type="Node2D"' in node.group()):
        continue
    entry = dict(base)
    entry.update(id=args.id + "/" + scene.relative_to(destination).as_posix(), pack_id=args.id, label=scene.stem, path="res://" + scene.relative_to(ROOT).as_posix(), mode=args.mode)
    entries.append(entry)
if not entries:
    parser.error("no suitable 3D scenes found")
custom_file = ROOT / "data" / "custom_sources.json"
custom = json.loads(custom_file.read_text(encoding="utf-8")) if custom_file.exists() else []
custom.append({"source": base, "entries": entries})
custom_file.write_text(json.dumps(custom, ensure_ascii=False, indent=2), encoding="utf-8")
build()
print("Imported", len(entries), "scenes. Restart the Godot editor to import textures and register scripts.")
