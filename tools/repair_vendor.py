"""Small documented packaging repairs for upstream preview integration."""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[1]
for key in ["binbun_battle", "binbun_flame", "binbun_hit"]:
    folder = ROOT / "vendor" / key
    for model in folder.rglob("suzanne.obj"):
        material = model.with_suffix(".mtl")
        if not material.exists():
            material.write_text("# Preview fallback: upstream ZIP omitted this material library.\nnewmtl Material\nKd 0.45 0.55 0.65\n", encoding="utf-8")
for f in (ROOT / "vendor").rglob("*.import"):
    text = f.read_text(encoding="utf-8")
    # Retain import settings but let Godot generate a unique identifier per pack.
    text = re.sub(r'^uid=.*\n', "", text, flags=re.M)
    f.write_text(text, encoding="utf-8")
project = ROOT / "vendor" / "motion_trail" / "project.godot"
if project.exists():
    project.rename(project.with_suffix(".godot.upstream"))
