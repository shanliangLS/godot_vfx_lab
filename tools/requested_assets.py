"""Curated native Godot entry points for the user's October 14 asset list."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / "vendor"
INFO = {
    "binbun_electric": ("Binbun · Electric FX 免费版", "电击 / 闪电", "static", "ElectricFXFree", "CC0", "2 个免费预设：闪电与电球；完整 Shader 和控制器。付费版 18 预设未持有。"),
    "binbun_loot": ("Binbun · Loot VFX 基础包", "掉落 / 拾取", "static", "", "CC0", "6 个稀有度，地面 / 悬浮各一套，共 12 个原始效果。Extra 付费包未持有。"),
    "binbun_status": ("Binbun · Status FX 免费版", "状态 / 护盾", "static", "StatusFXFree", "CC0", "免费状态样例与完整组件 / 叠加 Shader；付费 18 效果和 18 叠加材质未持有。"),
    "binbun_elemental": ("Binbun · Elemental Magic 免费版", "范围 / 魔法阵", "area", "ElementalMagicFXFree", "CC0", "火系飞弹、施法、范围各一个免费预设；付费 24 预设未持有。"),
    "binbun_dark": ("Binbun · Dark Magic 免费版", "范围 / 魔法阵", "area", "DarkMagicFXFree", "CC0", "免费飞弹、暗球、范围三个预设；付费 21 预设未持有。"),
    "berry_hit_free": ("berryhibiscus · Hit VFX 免费样例", "受击 / 冲击", "hit", "", "可商用 / 可修改；禁止资源包再分发、NFT 和模型训练", "仅免费 Crimson Slash 样例；页面的 30 效果完整版需付费，未持有。"),
    "soygus_tornado": ("soygus · Tornado VFX", "范围 / 魔法阵", "static", "tornado", "可商用 / 可修改；禁止再分发与重新打包", "原始蓝色龙卷风、毒雾龙卷风和火龙卷风，拆分作者示例中的三个节点预览。"),
    "starter_lite": ("AlekseiRamirov · Starter VFX Lite", "受击 / 冲击", "hit", "", "作者页面 CC0 / MIT", "9 个免费原始效果：命中、拾取、营火、爆炸、枪口和移动反馈；支持调色板和整体缩放。"),
    "magic_circles_free": ("heyheythere · Magic Circles 3D Free", "范围 / 魔法阵", "area", "magic-circles-3d-free", "CC BY 4.0 · 必须署名", "原生 Godot ZIP：八种元素 × 魔法阵 / 波纹，共 16 个预设；其余种类的 Shader 不在免费包内。"),
    "arcflux_lite": ("gennai · ARCFLUX Lite", "电击 / 闪电", "static", "arcflux_lite_v1.0.3/project", "可商用；禁止资源包再分发", "蓝色分叉闪电与红色激光两个原始预设；支持长度、分支、闪烁、余辉、碰撞和调色板。"),
    "soygus_shield": ("soygus · Force Shield VFX", "状态 / 护盾", "static", "shield-vfx", "可商用 / 可修改；禁止再分发与重新打包", "作者三个原始护盾节点，保留网格、Shader 和粒子。"),
}

def normalize_requested(key, relative_root):
    folder = VENDOR / key
    marker = folder / "LAB-ADAPTATION.json"
    if marker.exists():
        return
    base = folder / relative_root
    prefix = "res://" + base.relative_to(ROOT).as_posix() + "/"
    for ghosts in folder.rglob("__MACOSX"):
        (ghosts / ".gdignore").write_text("", encoding="utf-8")
    files = [p for p in folder.rglob("*") if p.is_file() and not any(part in ("__MACOSX", ".godot", ".git") for part in p.parts) and not p.name.startswith("._")]
    classes = {}
    for path in files:
        if path.suffix == ".gd":
            for name in re.findall(r"^class_name\s+(\w+)", path.read_text(encoding="utf-8-sig"), re.M):
                classes[name] = "Lab" + key.title().replace("_", "") + name
    changed = []
    for path in files:
        if path.suffix not in (".gd", ".tscn", ".tres", ".gdshader", ".gdshaderinc", ".import"):
            continue
        original = path.read_text(encoding="utf-8-sig")
        text = original
        if path.suffix == ".import":
            text = re.sub(r"^uid=.*\n", "", text, flags=re.M)
            text = re.sub(r'(source_file=")res://', r"\1" + prefix, text)
        else:
            text = re.sub(r"res://(?!vendor/)", prefix, text)
            text = re.sub(r'\s+uid="uid://[^"]+"', "", text)
            for name, adapted in classes.items():
                text = re.sub(r"\b" + re.escape(name) + r"\b", adapted, text)
            for name, adapted in classes.items():
                text = text.replace(adapted + ".gd", name + ".gd")
        if text != original:
            path.write_text(text, encoding="utf-8")
            changed.append(path.relative_to(folder).as_posix())
    for project in folder.rglob("project.godot"):
        project.rename(project.with_suffix(".godot.upstream"))
    for obj in folder.rglob("*.obj"):
        if not obj.with_suffix(".mtl").exists():
            matches = re.findall(r"^usemtl (.+)$", obj.read_text(encoding="utf-8", errors="replace"), re.M)
            if matches:
                obj.with_suffix(".mtl").write_text("\n".join("newmtl " + name + "\nKd 0.45 0.55 0.65" for name in set(matches)), encoding="utf-8")
    marker.write_text(json.dumps({"relocation_prefix": prefix, "class_names": classes, "changed_files": changed, "note": "Original ZIP retained; isolate paths/classes and stale UIDs; ignore macOS metadata; supply missing OBJ materials."}, indent=2), encoding="utf-8")

def repair_pack_metadata(key):
    folder = (VENDOR / key).resolve()
    assert VENDOR.resolve() in folder.parents
    marker = folder / "LAB-ADAPTATION.json"
    record = json.loads(marker.read_text(encoding="utf-8"))
    if not record.get("uids_regenerated"):
        for uid in folder.rglob("*.uid"):
            if "__MACOSX" not in uid.parts:
                uid.unlink()
        record["uids_regenerated"] = True
        marker.write_text(json.dumps(record, indent=2), encoding="utf-8")
    if key == "magic_circles_free" and not record.get("preview_lifetime_guard"):
        script = next(folder.rglob("magic_area.gd"))
        text = script.read_text(encoding="utf-8")
        text = text.replace("\t\t\t\t\tqueue_free()", '\t\t\t\t\tif not get_meta("vfx_lab_keep_alive", false):\n\t\t\t\t\t\tqueue_free()')
        script.write_text(text, encoding="utf-8")
        record["preview_lifetime_guard"] = True
        marker.write_text(json.dumps(record, indent=2), encoding="utf-8")
    for obj in folder.rglob("*.obj"):
        text = obj.read_text(encoding="utf-8", errors="replace")
        for filename in re.findall(r"^mtllib (.+)$", text, re.M):
            target = (obj.parent / filename.strip()).resolve()
            assert folder in target.parents
            if not target.exists():
                names = re.findall(r"^usemtl (.+)$", text, re.M) or ["Material"]
                target.write_text("\n".join("newmtl " + name + "\nKd 0.45 0.55 0.65" for name in set(names)), encoding="utf-8")
    if key.startswith("binbun_"):
        for script in folder.rglob("*.gd"):
            original = script.read_text(encoding="utf-8")
            repaired = original.replace("vfx_light_indirect_energy", "vfx_indirect_energy").replace("vfx_light_volumetric_fog_energy", "vfx_volumetric_fog_energy")
            if repaired != original:
                script.write_text(repaired, encoding="utf-8")

def append_requested(entries, sources):
    for key, values in INFO.items():
        name, category, mode, relative_root, license_name, description = values
        folder = VENDOR / key
        provenance = folder / "PROVENANCE.json"
        if not provenance.exists():
            continue
        normalize_requested(key, relative_root)
        repair_pack_metadata(key)
        record = json.loads(provenance.read_text(encoding="utf-8"))
        source = dict(id=key, name=name, category=category, url=record["url"], license=license_name, description=description, status="installed", directory="res://vendor/" + key)
        sources.append(source)
        def add(path, label, entry_mode=mode, entry_category=category, **extras):
            entry = dict(source)
            identity = str(extras.get("subnode", extras.get("initial", {}).get("element", "") + "_" + extras.get("initial", {}).get("kind", "")))
            entry.update(id=key + "/" + path.stem + ("/" + identity if identity not in ("", "_") else ""), pack_id=key, label=label, path="res://" + path.relative_to(ROOT).as_posix(), mode=entry_mode, category=entry_category)
            entry.update(extras)
            entries.append(entry)
        if key == "soygus_tornado":
            for subnode, label in [("tornado Blue", "蓝色龙卷风"), ("tornado poison", "毒雾龙卷风"), ("tornado fire", "火龙卷风")]:
                add(folder / "tornado/node_3d.tscn", label, "static", category, subnode=subnode)
        elif key == "soygus_shield":
            for index in range(1, 4):
                add(folder / "shield-vfx/main.tscn", "护盾 · " + str(index), subnode="shield_basic" + (str(index) if index > 1 else ""))
        elif key == "magic_circles_free":
            script = folder / relative_root / "addons/magic_circles/magic_area.gd"
            for element, chinese in [("fire", "烈焰"), ("frost", "冰霜"), ("poison", "剧毒"), ("holy", "圣光"), ("shadow", "暗影"), ("arcane", "奥术"), ("nature", "自然"), ("blood", "鲜血")]:
                for kind, label in [("circle", "魔法阵"), ("ripple", "波纹")]:
                    add(script, chinese + " · " + label, initial={"kind": kind, "element": element})
        else:
            if key == "berry_hit_free":
                scenes = list((folder / "FreeHitVfx/scenes").glob("*.tscn"))
            elif key == "starter_lite":
                scenes = list((folder / "Starter_Vfx/scenes").rglob("*.tscn"))
            elif key == "arcflux_lite":
                scenes = list((folder / relative_root / "addons/arcflux_fx/presets/3d").glob("*.tscn"))
            else:
                scenes = [p for p in folder.rglob("*.tscn") if "/effects/" in p.as_posix()]
            for path in sorted(scenes):
                stem = path.stem
                category_for_scene, mode_for_scene = category, mode
                label = stem
                if key == "binbun_loot":
                    rarity = next((cn for en, cn in [("uncommon", "优秀"), ("common", "普通"), ("rare", "稀有"), ("epic", "史诗"), ("legendary", "传说"), ("mythic", "神话")] if stem.endswith("_" + en)), stem)
                    label = ("地面" if "ground" in stem else "悬浮") + "掉落 · " + rarity
                    mode_for_scene = "area"
                elif key in ("binbun_elemental", "binbun_dark"):
                    if "projectile" in str(path):
                        category_for_scene, mode_for_scene = "魔法 / 飞弹", "projectile"
                    elif "/cast/" in path.as_posix():
                        category_for_scene, mode_for_scene = "受击 / 冲击", "hit"
                    elif "/orb/" in path.as_posix():
                        category_for_scene, mode_for_scene = "魔法 / 飞弹", "static"
                    label = stem.replace("vfx_", "").replace("fire", "烈焰").replace("dark", "暗影").replace("projectile", "飞弹").replace("area", "范围").replace("cast", "施法").replace("orb", "暗球")
                elif key == "binbun_electric":
                    mode_for_scene = "projectile" if "/ball/" in path.as_posix() else "static"
                    label = "闪电电球" if mode_for_scene == "projectile" else "闪电击射"
                elif key == "arcflux_lite":
                    category_for_scene, mode_for_scene = ("激光 / 射线", "beam") if "laser" in stem else ("电击 / 闪电", "bolt")
                    label = "红色激光" if "laser" in stem else "蓝色分叉闪电"
                elif key == "starter_lite":
                    section = path.parent.name
                    category_for_scene, mode_for_scene = {"fire": ("火焰 / 火球", "static"), "loot": ("掉落 / 拾取", "area"), "hit_impact": ("受击 / 冲击", "hit"), "explosion": ("受击 / 冲击", "hit"), "muzzle": ("攻击 / 刀光", "hit"), "movement": ("状态 / 护盾", "hit")}[section]
                    label = {"vfx_air_explosion_01": "空中爆炸", "vfx_fire_01": "循环营火", "vfx_hit_impact_01": "命中火花 · 1", "vfx_hit_impact_02": "命中火花 · 2", "vfx_loot_environment_01": "拾取闪光 · 1", "vfx_loot_environment_02": "拾取闪光 · 2", "vfx_muzzle_01": "枪口爆闪", "vfx_ground_smoke_01": "跳跃烟尘", "vfx_ground_smoke_02": "移动烟尘"}.get(stem, stem)
                elif key == "berry_hit_free":
                    label = "免费样例 · 赤红斩击"
                elif key == "binbun_status":
                    label = "免费样例 · 状态碎片"
                add(path, label, mode_for_scene, category_for_scene)
