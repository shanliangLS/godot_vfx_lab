"""Write the verified compatibility decisions for every requested pack and series."""
import json
from pathlib import Path
from requested_assets import INFO
from fetch_requested import SPECS

ROOT = Path(__file__).resolve().parents[1]
items = []
for key, info in INFO.items():
    name, category, mode, relative_root, license_name, description = info
    items.append(dict(id=key, name=name, category=category, requested_url=SPECS[key][0], url=SPECS[key][0], status="installed", godot=True, license=license_name, description=description, evidence=[SPECS[key][0], "vendor/" + key + "/PROVENANCE.json"]))
items.append(dict(id="binbun_battle", name="Binbun · Battle FX", category="攻击 / 刀光", requested_url="https://binbun3d.itch.io/battle-fx", url="https://binbun3d.itch.io/battle-fx", status="installed", godot=True, license="CC0", description="现有免费基础场景已经接入；本次复核不重复下载。完整 42 预设需付费。", evidence=["https://binbun3d.itch.io/battle-fx"]))

godot_projectiles = {
    1: ("https://gabrielaguiarprod.itch.io/unique-projectiles-vol1", "https://www.gabrielaguiarprod.com/product-page/unity-vfx-graph-muzzle-flash-effect", "30 个 Godot 飞弹与配套发射 / 命中特效"),
    2: ("https://gabrielaguiarprod.itch.io/unique-projectiles-vol-2", "https://www.gabrielaguiarprod.com/product-page/godot-projectiles-vol-2", "60 个 Godot 飞弹与配套发射 / 命中特效"),
    3: ("https://gabrielaguiarprod.itch.io/unique-projectiles-vol-3", "https://www.gabrielaguiarprod.com/product-page/godot-projectiles-vol-3", "60 个 Godot 飞弹与配套发射 / 命中特效"),
}
for volume, (requested, url, description) in godot_projectiles.items():
    items.append(dict(id="gap_godot_projectiles_" + str(volume), name="Gabriel · Godot Projectiles Vol." + str(volume), category="魔法 / 飞弹", requested_url=requested, url=url, status="pending", godot=True, license="付费 · 未持有；以购买许可为准", price_usd=20, description=description + "。itch 展示的是 Unity 版本；官网另售原生 Godot 版，未获得源文件，待导入。", evidence=[url, "https://www.gabrielaguiarprod.com/game-vfx-assets"]))
for volume, requested, url, description in [
    (1, "https://gabrielaguiarprod.itch.io/unique-magic-abilities-vol1", "https://www.gabrielaguiarprod.com/product-page/godot-magic-abilities-vol", "31 个 Godot 魔法技能：光束、治疗、地面攻击、彗星、冲击和增益"),
    (2, "https://gabrielaguiarprod.itch.io/unique-magic-abilities-vol2", "https://www.gabrielaguiarprod.com/product-page/godot-magic-abilities-vol-2", "50 个 Godot 范围技能：增益、减益、箭雨、陨石、彗星与冲击"),
]:
    items.append(dict(id="gap_godot_magic_" + str(volume), name="Gabriel · Godot Magic Abilities Vol." + str(volume), category="范围 / 魔法阵", requested_url=requested, url=url, status="pending", godot=True, license="付费 · 未持有；以购买许可为准", price_usd=20, description=description + "，售价 $20。未持有源文件，待导入。", evidence=[url, "https://www.gabrielaguiarprod.com/game-vfx-assets"]))

for key, name, url, reason in [
    ("laplahce_projectiles", "laplahce · Stylized Projectiles", "https://laplahce.itch.io/stylized-projectiles-pack", "提供 Unity URP / HDRP 资产和 Windows Demo，没有 Godot 场景。"),
    ("gap_projectiles_4", "Gabriel · Unique Projectiles Vol.4", "https://gabrielaguiarprod.itch.io/unique-projectiles-vol4", "Unity Shader Graph / URP / HDRP / BIRP 版；在作者官网当前 Godot 产品列表中未找到对应 Vol.4。"),
    ("gap_projectiles_5", "Gabriel · Unique Projectiles Vol.5", "https://gabrielaguiarprod.itch.io/unique-projectiles-vol5", "当前交付为 Unity；官网 Godot 飞弹目前核实到 Vol.1–3，未找到 Vol.5。旧评论中的移植承诺不代表可下载交付。"),
    ("gap_magic_3", "Gabriel · Unique Magic Abilities Vol.3", "https://gabrielaguiarprod.itch.io/magic-abilities-vol3", "Unity 和 Niagara 版本；官网 Godot 技能目前核实到 Vol.1–2，未找到 Vol.3。"),
    ("gap_loot_1", "Gabriel · Unique Loot Drops Vol.1", "https://gabrielaguiarprod.itch.io/unique-loot-drops-vol-1", "Unity HDRP / URP / BIRP 资产；未找到 Godot 交付。"),
    ("gap_sword_1", "Gabriel · Unique Sword Slashes Vol.1", "https://gabrielaguiarprod.itch.io/unique-sword-slashes-vol1", "Unity HDRP / URP / BIRP 资产；作者系列目录核实到此 Vol.1，未找到 Godot 剑斩系列交付。"),
    ("wallcoeur_fire", "wallcoeur · Fire Toon Particle", "https://wallcoeur.itch.io/unity-urp-vfx-fire-toon-particle", "交付 .unitypackage 和 Unity URP Prefab，不能直接载入 Godot。"),
]:
    items.append(dict(id=key, name=name, category="不适配 / 排除", requested_url=url, url=url, status="excluded", godot=False, license="未导入", description=reason + " 按用户要求排除，不下载、不移植，不加入效果目录。", evidence=[url, "https://www.gabrielaguiarprod.com/game-vfx-assets"] if key.startswith("gap_") else [url]))

data = {"verified_at": "2026-10-14", "policy": "只接入原生 Godot、可合法获取且已验证的 3D 资源；付费未持有记录待导入，Unity / Unreal 交付排除。重复的 Magic Circles URL 合并为一次。", "items": items}
(ROOT / "data/requested_research.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
lines = ["# 用户指定 VFX 调研与接入记录", "", "核实日期：2026-10-14。重复 Magic Circles 链接合并；系列扩展核实作者当前目录。只有实际取得的 Godot 源资源进入预览目录。", "", "| 资源 | 状态 | 结论 / 免费版范围 |", "|---|---|---|"]
for item in items:
    lines.append("| [%s](%s) | %s | %s |" % (item["name"], item["url"], {"installed": "已接入", "pending": "原生 Godot · 付费未持有", "excluded": "不适配 · 排除"}[item["status"]], item["description"].replace("|", "/")))
lines += ["", "Gabriel 原生 Godot 的产品、定价与系列范围来自[作者当前官网目录](https://www.gabrielaguiarprod.com/game-vfx-assets)，不能用 itch 的 Unity Demo 代替源资源。", "", "Magic Circles 页面列出 UnityPackage 和 ZIP；实际 ZIP 包含 addons/magic_circles/magic_area.gd 与原生 Shader，因此可接入。只提供 circle / ripple 两种 Shader，面板不开放付费种类。", "", "Magic Circles 署名：Magic Circles 3D Free by heyheythere - https://heyheythere.itch.io/magic-circles-3d-free - CC BY 4.0", "", "各包下载 SHA-256、实际文件名与许可摘要保存在 vendor/<id>/PROVENANCE.json 和 SOURCE-LICENSE.txt，原下载 ZIP 保留于 downloads/。免费样例不代表持有付费完整版。"]
(ROOT / "docs/REQUESTED_ASSETS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("Recorded", len(items), "research decisions")
