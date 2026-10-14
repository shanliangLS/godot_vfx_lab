"""Convert source VisualShader binaries through Godot before relocating their dependencies."""
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ENGINE = r"D:\Studio\AI\Projects\godot\tools\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"

def convert():
    destination = ROOT / "artifacts/card_conversion"
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(ROOT / "downloads/soygus_card.zip") as archive:
        for name in archive.namelist():
            path = (destination / name).resolve()
            if destination.resolve() not in path.parents and path != destination.resolve():
                raise ValueError("Unsafe archive path")
        archive.extractall(destination)
    source = destination / "holographic-card-vfx"
    (source / "convert.gd").write_text('extends SceneTree\nfunc _initialize():\n\tfor stem in ["cardHolo", "cardHolo2", "cardHolo3"]:\n\t\tvar resource = load("res://" + stem + ".res")\n\t\tassert(resource != null)\n\t\tassert(ResourceSaver.save(resource, "res://" + stem + ".tres") == OK)\n\tprint("CARD_RESOURCES_CONVERTED")\n\tquit()\n', encoding="utf-8")
    with open(ROOT / "artifacts/card-conversion.log", "w", encoding="utf-8") as log:
        subprocess.run([ENGINE, "--headless", "--editor", "--path", str(source), "--import", "--quit"], stdout=log, stderr=subprocess.STDOUT, check=True, timeout=120)
        subprocess.run([ENGINE, "--headless", "--path", str(source), "--script", "res://convert.gd", "--quit-after", "30"], stdout=log, stderr=subprocess.STDOUT, check=True, timeout=60)
    target = ROOT / "vendor/soygus_card/holographic-card-vfx"
    prefix = "res://vendor/soygus_card/holographic-card-vfx/"
    for path in source.glob("cardHolo*.tres"):
        text = path.read_text(encoding="utf-8")
        text = re.sub(r"res://(?!vendor/)", prefix, text)
        text = re.sub(r'\s+uid="uid://[^"]+"', "", text)
        text = re.sub(r"^graph_offset = .*\n", "", text, flags=re.M)
        (target / path.name).write_text(text, encoding="utf-8")
    scene = target / "main.tscn"
    scene.write_text(scene.read_text(encoding="utf-8").replace("cardHolo.res", "cardHolo.tres").replace("cardHolo2.res", "cardHolo2.tres").replace("cardHolo3.res", "cardHolo3.tres"), encoding="utf-8")
    for original in target.glob("cardHolo*.res"):
        original.rename(original.with_suffix(".res.upstream"))
    print("Converted 3 card VisualShaders to relocated text")

if __name__ == "__main__":
    convert()
