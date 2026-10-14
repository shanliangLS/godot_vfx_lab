"""Relocate imported packs and build an auditable runtime catalog."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / "vendor"
PACKS = {
    "binbun_hit": ("Binbun · Hit FX", "受击 / 冲击", "hit", "https://binbun3d.itch.io/hit-fx", "CC0", "6 个免费命中预设；可调三色、噪声、边缘、动画与音频。"),
    "binbun_battle": ("Binbun · Battle FX", "攻击 / 刀光", "slash", "https://binbun3d.itch.io/battle-fx", "CC0", "免费基础预设：挥砍、飞行斩击、爪击、蓄力和护盾。"),
    "binbun_beam": ("Binbun · Beam VFX", "激光 / 射线", "beam", "https://binbun3d.itch.io/beam-vfx", "CC0", "完整免费光束控制器；付费版额外增加 16 个美术预设。"),
    "binbun_projectiles": ("Binbun · Magic Projectiles", "魔法 / 飞弹", "projectile", "https://binbun3d.itch.io/magic-projectiles-vfx", "CC0", "12 个作者原始弹体：基础球形、波动弹体与魔法标枪。"),
    "binbun_flame": ("Binbun · Flame FX", "火焰 / 火球", "static", "https://binbun3d.itch.io/flame-fx", "CC0", "作者免费火焰预设；火球运动由预览舞台提供，不是另购的火球包。"),
    "inspired_projectiles": ("inspiredsloth · Projectile Effects", "魔法 / 飞弹", "projectile", "https://inspiredsloth.itch.io/projectile-effects", "CC0", "Vol.1 的 4 个原始弹体场景，包含真实拖尾与材质。"),
    "gpu_trail": ("celyk · GPUTrail", "拖尾 / 插件", "trail", "https://github.com/celyk/GPUTrail", "MIT", "GPU 带状拖尾；采样数、时长、渐变、宽度曲线、遮罩和纹理滚动。"),
    "motion_trail": ("metanoia83 · Motion Trail", "拖尾 / 插件", "trail", "https://github.com/metanoia83/Godot-4.0-Motion-Trail", "MIT", "CPU 带状拖尾；起末宽度、寿命、颜色与插值方式。"),
}
PENDING = [
    ("effectblocks", "EffectBlocks", "综合资源", "https://bukkbeek.itch.io/effectblocks", "付费 · 未持有", "100+ 成品 VFX。缺少购买后的源文件；免费可执行 Demo 不能代替源场景。"),
    ("gameidea_fireball", "GameIdea · Fireballs", "火焰 / 火球", "https://gameidea-studio.itch.io/godot-fireballs-projectiles-vfx", "付费 · 未持有", "火球与配套命中爆发。需本地导入购买后的资源。"),
    ("gameidea_beam", "GameIdea · Beam VFX", "激光 / 射线", "https://gameidea-studio.itch.io/godot-beam-vfx", "付费 · 未持有", "模块化核心、端点与冲击光束。"),
    ("magic_area", "Binbun · Magic Area", "范围 / 魔法阵", "https://binbun3d.itch.io/magic-area-vfx", "付费 · 未持有", "地面波纹、脉冲和光柱；未把其他资源假冒为此包。"),
    ("flame_wizard", "Flame Wizard VFX Set", "火焰 / 火球", "https://berryhibiscus.itch.io/flame-wizard-vfx-set-godot-4", "付费 · 授权待确认", "15 个火系施法、蓄力、火球、喷火、爆发与光环。"),
    ("reeboo", "REEBOO · Stylized VFX", "综合资源", "https://reebo0.itch.io/stylized-vfx-godot", "付费 / 免费样例", "完整 25 个效果需购买；未下载样例时显示未接入。"),
    ("effekseer", "Effekseer · Godot 4", "工具 / 插件", "https://github.com/effekseer/EffekseerForGodot4", "MIT · 未接入", "需要额外原生运行插件与 .efkefc 样例。本项目目前使用 Godot 原生资源。"),
    ("official_particles", "Godot 官方 · 3D Particles Demo", "工具 / 插件", "https://godotengine.org/asset-library/asset/2745", "MIT · 未接入", "官方粒子碰撞、吸引器、拖尾与子发射器参考。"),
    ("kenney", "Kenney · Particle Pack", "纹理素材", "https://kenney.nl/assets/particle-pack", "CC0 · 未接入", "80 个粒子贴图，需要搭建发射器后才能成为完整效果。"),
    ("slash_shader", "Godot Shaders · Slash Shader", "攻击 / 刀光", "https://godotshaders.com/shader/slash-shader/", "代码 CC0 · 未接入", "需要配套网格及纹理；各自授权需要分别检查。"),
    ("simple_laser", "Godot Shaders · Simple Laser", "激光 / 射线", "https://godotshaders.com/shader/simple-laser-shader-sls/", "代码 CC0 · 未接入", "激光材质示例，待接入。"),
    ("fab_textures", "Fab · 150++ VFX Textures", "纹理素材", "https://www.fab.com/listings/69a74c16-09aa-41bf-a139-e81810267df6", "付费 · Unreal 交付", "须确认独立 PNG 交付；需要在 Godot 重建材质。"),
    ("oga_hit", "OpenGameArt · Unity Hit VFX Vol.2", "受击 / 冲击", "https://opengameart.org/content/unity-hit-vfx-volume-2", "CC0 · 需移植", "20+ Unity 命中特效；不是可直接运行的 Godot 场景。"),
]


def normalize(key):
    folder = VENDOR / key
    marker = folder / "LAB-ADAPTATION.json"
    if marker.exists():
        return
    if key == "binbun_battle":
        base = folder / "BattleFXFree"
    elif key == "binbun_flame":
        base = folder / "FlameFXFree"
    else:
        base = folder
    prefix = "res://" + base.relative_to(ROOT).as_posix() + "/"
    classes = {}
    for f in folder.rglob("*.gd"):
        for name in re.findall(r'^class_name\s+(\w+)', f.read_text(encoding="utf-8-sig"), re.M):
            if key.startswith("binbun"):
                classes[name] = "Lab" + key.title().replace("_", "") + name
    changes = []
    for f in folder.rglob("*"):
        if f.suffix not in [".gd", ".tscn", ".tres", ".gdshader", ".gdshaderinc"]:
            continue
        old = f.read_text(encoding="utf-8-sig")
        new = re.sub(r'res://(?!vendor/)', prefix, old)
        new = re.sub(r'\s+uid="uid://[^"]+"', "", new)
        for name, replacement in classes.items():
            new = re.sub(r'\b' + name + r'\b', replacement, new)
        if new != old:
            f.write_text(new, encoding="utf-8")
            changes.append(f.relative_to(folder).as_posix())
    marker.write_text(json.dumps({"relocation_prefix": prefix, "class_names": classes, "changed_files": changes, "note": "Path relocation, stale UID removal and per-pack class namespaces only; upstream ZIP remains in downloads."}, indent=2), encoding="utf-8")


def build():
    entries = []
    sources = []
    for key, info in PACKS.items():
        name, category, mode, url, license_name, description = info
        folder = VENDOR / key
        if not (folder / "PROVENANCE.json").exists():
            continue
        normalize(key)
        source = dict(id=key, name=name, category=category, url=url, license=license_name, description=description, status="installed", directory="res://vendor/" + key)
        sources.append(source)
        if key == "gpu_trail":
            scenes = [folder / "GPUTrail3D.gd"]
        elif key == "motion_trail":
            scenes = [folder / "Trail3D.gd"]
        elif key == "inspired_projectiles":
            scenes = sorted(folder.glob("projectiles/projectile_*.tscn"))
        else:
            scenes = sorted(f for f in folder.rglob("*.tscn") if "/effects/" in f.as_posix())
        for scene in scenes:
            entry = dict(source)
            stem = scene.stem
            label = stem.replace("vfx_blank_", "基础 · ").replace("vfx_basic_", "基础 · ").replace("base_beam_vfx", "基础 · 目标跟随光束")
            label = label.replace("mprojectile_basic_vfx_", "魔法球 · ").replace("mprojectile_wave_vfx_", "波动弹体 · ").replace("mprojectile_javelin_vfx_", "魔法标枪 · ")
            label = label.replace("projectile_", "成品弹体 · ").replace("swing", "挥砍").replace("slash", "飞行斩击").replace("claw", "爪击").replace("charge", "蓄力").replace("shield", "护盾").replace("fire", "火焰")
            entry.update(id=key + "/" + stem, pack_id=key, label=label, path="res://" + scene.relative_to(ROOT).as_posix(), mode=mode)
            if "shield" in stem or "charge" in stem:
                entry["mode"] = "static"
            if key in ["gpu_trail", "motion_trail"]:
                entry["id"] = key
                entry["label"] = "GPU 带状拖尾" if key == "gpu_trail" else "CPU 带状拖尾"
            entries.append(entry)
    for key, name, category, url, license_name, description in PENDING:
        sources.append(dict(id=key, name=name, category=category, url=url, license=license_name, description=description, status="pending", directory=""))
    data = ROOT / "data"
    data.mkdir(exist_ok=True)
    (data / "catalog.json").write_text(json.dumps(entries, ensure_ascii=False, indent=2), encoding="utf-8")
    (data / "sources.json").write_text(json.dumps(sources, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Catalog:", len(entries), "effects;", len(sources), "sources")


if __name__ == "__main__":
    build()
