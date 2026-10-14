"""Native entry points and explicitly labelled texture/mesh carriers for batch two/three."""
import json
from pathlib import Path
import re
from requested_assets import normalize_requested
from fetch_more import SPECS
from strip_fbx_textures import strip_empty_textures

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / "vendor"
INFO = {
    "fx_collection_free": ("Godot FX Collection Free", "heyheythere", "屏幕 / 材质", None, "CC BY 4.0 · 必须署名", "九个原生子包：新增 2D 效果、精灵材质、天气叠加、转场、复古屏幕、PSX 和卡通材质；魔法阵与风暴复用已单独接入的子包。"),
    "rain_free": ("Free Rain VFX · Rain / Ripples / Splashes", "gennai", "环境 / 天气", "nimblux_lite_v1.0.3/project", "可商用；禁止资源包再分发", "原生 3D 雨滴、地面波纹与水花；免费中雨预设，强度可实时调节。"),
    "soygus_chest": ("Chest Looting VFX", "soygus", "掉落 / 拾取", "chest-looting-vfx", "作者免费发布；未附明确许可文本，使用前核对来源", "原作者宝箱模型、开箱动画、发光形状与粒子；未把示例舞台相机导入预览。"),
    "storm_free": ("Storm & Wind 3D Free", "heyheythere", "电击 / 闪电", "storm-wind-3d-free", "CC BY 4.0 · 必须署名", "六种雷击与六种阵风，共 12 个免费原始预设；其他付费种类不开放。"),
    "glyph_free": ("PARADOX Novissime · Glyph Cities Free", "PARADOX", "范围 / 魔法阵", "PARADOX_Novissime_GlyphCities_FreeSampler_v1.0/Godot", "可商用；禁止素材再售与再分发", "地面传送门、水晶闪烁和灯光闪烁 × 四种配色；使用 Godot 交付与原始模型。"),
    "soygus_hologram": ("Hologram VFX 3D", "soygus", "屏幕 / 材质", "hologram-vfx", "可商用 / 可修改；禁止再分发与重新打包", "作者三个原始全息模型场景：桶和两种坦克；可调 Visual Shader 参数。"),
    "christmas_assets": ("VFX Library · Christmas Edition", "game.utb / Petr Medveď", "纹理 / 网格", "", "可商用；禁止作为素材类产品再分发", "原始 PNG 和 FBX 素材预览，非成品特效。实验室载体支持颜色、强度、混合、序列帧和模型查看。"),
    "brackeys_bundle": ("Brackeys VFX Bundle", "Brackeys", "纹理 / 网格", "brackeys_vfx_bundle", "CC0", "原始粒子纹理、TGA Flipbook 和 PNG 预绘序列帧；实验室 3D 载体预览，非作者成品场景。原创来源：Kenney、Picster、Thomas Iché、CodeManu。"),
    "binbun_grass": ("Godot Grass Shader · 免费样例", "Binbun", "环境 / 天气", "", "CC0", "原生草地 MultiMesh、风动、渐变颜色与地面材质；免费一个样式，付费 10 个预设未持有。"),
    "soygus_card": ("Holographic Card VFX", "soygus", "屏幕 / 材质", "holographic-card-vfx", "可商用 / 可修改；禁止再分发与重新打包", "三个原作者全息卡片节点，含动画和 Visual Shader；源演示包含品牌卡图，使用这些图像前需另行确认相应权利。"),
}

def append_more(entries, sources):
    for key, (name, author, category, base, license_name, description) in INFO.items():
        folder = VENDOR / key
        if not (folder / "PROVENANCE.json").exists():
            continue
        normalize_requested(key, base)
        if key == "storm_free":
            script = folder / base / "addons/storm_wind/storm_fx.gd"
            text = script.read_text(encoding="utf-8")
            script.write_text(text.replace("if not Engine.is_editor_hint():\n\t\t\t\t\tqueue_free()", 'if not Engine.is_editor_hint() and not get_meta("vfx_lab_keep_alive", false):\n\t\t\t\t\tqueue_free()'), encoding="utf-8")
        if key in ("soygus_card", "soygus_hologram"):
            for resource in list(folder.rglob("*.tscn")) + list(folder.rglob("*.tres")):
                text = resource.read_text(encoding="utf-8")
                resource.write_text(re.sub(r"^graph_offset = .*\n", "", text, flags=re.M), encoding="utf-8")
        if key == "christmas_assets":
            # Original FBX files refer to an empty texture filename; display the UV meshes
            # without attempting to resolve that invalid path. PNGs have their own entries.
            for config in folder.rglob("*.fbx.import"):
                text = config.read_text(encoding="utf-8")
                config.write_text(text.replace("fbx/embedded_image_handling=1", "fbx/embedded_image_handling=0"), encoding="utf-8")
            marker = folder / "FBX_TEXTURE_ADAPTATION.json"
            if not marker.exists() or json.loads(marker.read_text(encoding="utf-8")).get("version") != 2:
                changes = {path.relative_to(folder).as_posix(): strip_empty_textures(path) for path in folder.rglob("*.fbx")}
                marker.write_text(json.dumps({"version": 2, "note": "Remove texture/video objects referring to a directory instead of an image and their connections; geometry, UVs and animation remain unchanged. Original ZIP retained.", "removed_objects": changes}, indent=2), encoding="utf-8")
        source = dict(id=key, name=name, author=author, category=category, url=SPECS[key][0], license=license_name, description=description, status="installed", directory="res://vendor/" + key)
        sources.append(source)
        def add(path, label, mode="static", entry_category=category, **extras):
            entry = dict(source)
            initial = extras.get("initial", {})
            suffix = str(extras.get("subnode", extras.get("visible_subnode", initial.get("variant", "") or initial.get("source_asset", "") or initial.get("kind", "") + "_" + initial.get("style", ""))))
            entry.update(id=key + "/" + Path(path).stem + ("/" + suffix if suffix not in ("", "_") else ""), pack_id=key, label=label, path="res://" + Path(path).relative_to(ROOT).as_posix(), mode=mode, category=entry_category)
            entry.update(extras)
            entries.append(entry)
        if key == "storm_free":
            script = folder / base / "addons/storm_wind/storm_fx.gd"
            for style, label in [("storm", "雷暴"), ("arcane", "奥术"), ("fire", "烈焰"), ("toxic", "剧毒"), ("holy", "圣光"), ("void", "虚空")]:
                add(script, label + " · 天降雷击", "area", initial={"kind": "strike", "style": style})
            for style, label in [("air", "空气"), ("leaves", "落叶"), ("snow", "飘雪"), ("sand", "沙尘"), ("petals", "花瓣"), ("ash", "灰烬")]:
                add(script, label + " · 阵风", entry_category="环境 / 天气", initial={"kind": "gust", "style": style})
        elif key == "fx_collection_free":
            for subpack, script, sampler, variants in [
                ("vfx-2d-free", "vfx_2d/vfx_2d.gd", "vfx", [("explosion", "2D 爆炸"), ("smoke", "2D 烟雾"), ("spark", "2D 命中火花"), ("fire", "2D 火焰")]),
                ("sprite-fx-free", "sprite_fx/sprite_fx.gd", "sprite", [("flash", "精灵受击闪白"), ("outline", "精灵描边"), ("dissolve", "精灵溶解"), ("shine", "精灵扫光"), ("blink", "精灵闪烁"), ("hue_shift", "精灵色相")]),
                ("weather-fx-free", "weather_fx/weather_fx.gd", "weather", [("rain", "2D 雨叠加"), ("snow", "2D 雪叠加"), ("fog", "2D 雾叠加")]),
                ("scene-transitions-free", "scene_transitions/scene_transition.gd", "transition", [(v, "转场 · " + cn) for v, cn in [("fade", "淡入淡出"), ("dither", "抖动"), ("wipe", "擦除"), ("diamonds", "菱形"), ("circles", "圆点"), ("iris", "光圈"), ("clouds", "云遮罩"), ("spots", "斑点遮罩")]]),
                ("retro-screen-fx-free", "retro_screen/retro_screen.gd", "retro", [("1", "CRT 显像管"), ("2", "街机屏幕"), ("3", "VHS 磁带"), ("11", "老电影")]),
                ("psx-look-free", "psx_look/psx.gd", "psx", [("lit", "PSX 复古 3D 材质")]),
                ("toon-look-free", "toon_look/toon.gd", "toon", [("cel", "卡通色阶与描边")]),
            ]:
                for variant, label in variants:
                    add(ROOT / "scripts/adapters/sampler_preview.gd", label + " · 作者 Shader / 实验室载体", initial={"source_script": "res://" + (folder / subpack / "addons" / script).relative_to(ROOT).as_posix(), "sampler": sampler, "variant": variant})
        elif key in ("christmas_assets", "brackeys_bundle"):
            for path in sorted(folder.rglob("*")):
                if path.suffix.lower() not in (".png", ".tga", ".fbx") or "__MACOSX" in path.parts or path.name.startswith("._"):
                    continue
                initial = {"source_asset": "res://" + path.relative_to(ROOT).as_posix()}
                grid = re.search(r"(\d+)x(\d+)", path.stem)
                if grid:
                    initial.update(columns=int(grid[1]), rows=int(grid[2]), additive=True)
                add(ROOT / "scripts/adapters/raw_asset_preview.gd", ("网格素材 · " if path.suffix.lower() == ".fbx" else ("序列帧素材 · " if grid else "纹理素材 · ")) + path.stem, initial=initial)
        elif key == "soygus_chest":
            add(folder / base / "chest.tscn", "开箱与掉落光效 · 作者模型 / 动画", "area", preview_scale=6.0)
        elif key == "soygus_hologram":
            for stem, label in [("barrel", "全息桶"), ("tank", "全息坦克 A"), ("tank2", "全息坦克 B")]:
                add(folder / base / (stem + ".tscn"), label, preview_scale=2.0)
        elif key == "glyph_free":
            for path in sorted((folder / base / "ParadoxNovissime/demo").glob("D_FX_*.tscn")):
                stem = path.stem
                label = "地面传送门" if "Portal" in stem else ("水晶闪烁" if "Crystal" in stem else "灯光闪烁")
                color = next((cn for en, cn in [("Violet", "紫色"), ("Gold", "金色"), ("Red", "红色")] if en in stem), "青色")
                add(path, label + " · " + color, "area" if "Portal" in stem else "static", strip_demo_stage=True, strip_demo_nodes=["Floor", "Overlay"])
        elif key == "binbun_grass":
            add(folder / "assets/BinbunGrass/main.tscn", "草地与风动 · 作者免费样式", "area", strip_demo_stage=True, preview_scale=0.3)
        elif key == "soygus_card":
            for subnode, label in [("yugioh card", "全息卡片 A"), ("pokemon card", "全息卡片 B"), ("magic card", "全息卡片 C")]:
                add(folder / base / "main.tscn", label, visible_subnode=subnode, strip_demo_stage=True, preview_scale=1.5)
        elif key == "rain_free":
            for scene in sorted(folder.rglob("*.tscn")):
                if "/presets/3d/" in scene.as_posix():
                    add(scene, "中雨 · 雨滴 / 波纹 / 水花", "area")
