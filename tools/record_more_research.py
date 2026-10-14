# -*- coding: utf-8 -*-
"""Durable compatibility/licensing decisions for all 19 second/third-batch URLs."""
import json
from pathlib import Path
from more_assets import INFO
from fetch_more import SPECS

ROOT = Path(__file__).resolve().parents[1]
items = []
for key, (name, author, category, base, license_name, description) in INFO.items():
    installed = (ROOT / "vendor" / key / "PROVENANCE.json").exists()
    if not installed:
        description += " 官网确认提供 Godot 免费 ZIP，但本次公开下载入口未返回有效文件列表，未用其他雨效替代，待取得原 ZIP 后导入。"
    items.append(dict(id=key, name=name, author=author, category=category, url=SPECS[key][0], requested_url=SPECS[key][0], status="installed" if installed else "pending", godot=True, delivery="素材 / 实验室载体" if key in ("christmas_assets", "brackeys_bundle") else "原生 Godot", license=license_name, description=description, evidence=[SPECS[key][0]] + (["vendor/" + key + "/PROVENANCE.json"] if installed else [])))
items.append(dict(id="reeboo_free", name="REEBOO · Stylized VFX Free Sample", author="REEBOO Labs", category="攻击 / 刀光", url="https://reebo0.itch.io/stylized-vfx-godot-free", requested_url="https://reebo0.itch.io/stylized-vfx-godot-free", status="installed", godot=True, license="可商用；禁止源文件再分发", description="已有 v1.2 的命中火花、剑斩和拾取闪光，核实后复用，不重复接入。", evidence=["vendor/reeboo_free/PROVENANCE.json"]))
items.append(dict(id="hun0fx_combat", name="hun0fx · Stylized Combat VFX", author="Hun0FX", category="综合资源", requested_url="https://hun0fx.itch.io/combat-vfx-demo", url="https://hun0fx.itch.io/stylized-combat-vfx", status="pending", godot=True, price_usd=20.99, license="付费 · 未持有；禁止源资源再分发", description="网页演示仅供预览，明确禁止复用其纹理和特效。完整版另有 Godot 4.3+ 原生场景，目前 $20.99（原价 $29.99），未持有源文件，待购买后导入。", evidence=["https://hun0fx.itch.io/combat-vfx-demo", "https://hun0fx.itch.io/stylized-combat-vfx"]))
for key, name, author, url, reason in [
    ("fox_lightning", "Lightning ShaderGraph", "Fox Jump", "https://fox-jump.itch.io/lightning-shadergraph", "交付 Unity .shadergraph，无 Godot 场景或 Shader。"),
    ("matthorn_explosion", "Explosion FX Clips", "Matthew L. Hornbostel", "https://matthornb.itch.io/explosion", "交付三段可抠像 MP4 视频，不是 3D 特效源场景；Godot 不原生播放 MP4，未进行转码或重建。"),
    ("nulltale_ascii", "Ascii Fx", "Null Tale", "https://nulltale.itch.io/asciifx", "Unity URP Render Feature / RenderGraph 后处理，不能直接载入 Godot。"),
    ("nulltale_volfx", "VolFx", "Null Tale", "https://nulltale.itch.io/volfx", "Unity 选择性后处理、LayerMask 和自定义渲染管线工具，没有 Godot 交付。"),
    ("yuriko_laser", "Elemental Laser VFX Pack", "YurikoKuun", "https://yurikokuun.itch.io/elemental-laser-pack", "下载为 .unitypackage 与 HDR_Particle.shadergraph，无 Godot 版本。"),
    ("smartwilliam_dash", "Energy Dash", "smartwilliam", "https://smartwilliam.itch.io/sfas2021vfx", "作者安装说明明确要求 Unreal Engine 4.26 / Niagara。"),
    ("laplahce_cartoon", "Cartoon Comic FX Pack", "laplahce", "https://laplahce.itch.io/cartoon-fx-pack", "itch 提供 Windows Unity 演示；完整版为 Unity URP 资源，未找到 Godot 交付。"),
]:
    items.append(dict(id=key, name=name, author=author, category="不适配 / 排除", requested_url=url, url=url, status="excluded", godot=False, license="未导入", description=reason + " 按要求不接入。", evidence=[url]))
data = {"verified_at": "2026-10-14", "policy": "只接入原生 Godot 或其可直接导入的 PNG/TGA/FBX 素材；素材载体、2D 叠加与成品 3D 效果明确标注；付费未持有和下载失败不冒充已安装。", "items": items}
(ROOT / "data/more_research.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
lines = ["# 第二、三批指定资源调研与接入", "", "核实日期：2026-10-14。共 19 个链接。Unity / Unreal 资源与 MP4 视频不移植，已有 REEBOO v1.2 复用。", "", "| 资源 | 来源 | 状态 | 交付 / 结论 |", "|---|---|---|---|"]
for item in items:
    lines.append("| [%s](%s) | %s | %s | %s |" % (item["name"], item["url"], item["author"], {"installed": "已接入", "pending": "待导入", "excluded": "不适配 · 排除"}[item["status"]], item["description"].replace("|", "/")))
lines += ["", "## 接入范围", "",
    "- Godot FX Collection：27 个新增预览项，覆盖 VFX 2D（4）、Sprite FX（6）、Weather FX 2D（3）、Scene Transitions（8）、Retro Screen（4）、PSX（1）、Toon（1）。它们是作者节点 / Shader 在实验室载体或视口叠加上的预览；其 Magic Circles 与 Storm 子包复用单独接入项，不重复增加目录。",
    "- Storm & Wind：12 个原始预设；Glyph Cities：三个带原模型的演示效果 × 四种配色，共 12 项。",
    "- Chest Looting：1 个原宝箱场景；Hologram：3 个原模型；Grass：1 个免费样式；Holographic Card：3 个原卡片节点。",
    "- Christmas：40 张 PNG + 14 个 FBX UV 网格，共 54 项；不含成品 VFX。FBX 的目录纹理引用在副本中移除，几何和 UV 保留，原始 ZIP 留存。",
    "- Brackeys：213 项 PNG/TGA 素材；文件名中的帧网格自动识别，支持帧率、混合、着色和循环。原图由 Kenney、Picster、Thomas Iché、CodeManu 制作，Brackeys 汇编，CC0。", "",
    "## 预览适配", "",
    "多项目合集按各子项目重定位 res://，隔离 class_name，并重建唯一 UID。卡片二进制 VisualShader 转成文本资源以修复外部脚本路径；完整节点层级保留，隐藏其他卡片以维持跨节点动画。风暴重建后参数重新解析生成的节点 / 材质；单次播放保留预览实例，游戏中的原始自动销毁逻辑不受影响。", "",
    "工具：tools/fetch_more.py 下载公开免费文件；tools/convert_card_resources.py 转换卡片资源；tools/record_more_research.py 更新本记录；tools/build_catalog.py 重建目录。各包 PROVENANCE.json 保存文件名、URL、SHA-256；原始授权文本保留在资源目录。", "",
    "## CC BY 4.0 署名", "",
    "Godot FX Collection Free by heyheythere - https://heyheythere.itch.io/godot-fx-collection-free - CC BY 4.0",
    "", "Storm & Wind 3D Free by heyheythere - https://heyheythere.itch.io/storm-wind-3d-free - CC BY 4.0", "",
    "## 验证", "",
    "运行 Godot --path . -- --more-qa，检查 artifacts/more-qa-report.json 和完整日志。该检查覆盖新增目录实例化、可编辑参数、模板与参数绑定、暂停、排除资源和资源页组合筛选；截图保存在 artifacts/more-*.png。"]
(ROOT / "docs/MORE_REQUESTED_ASSETS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("Recorded", len(items), "research decisions")
