# 第二、三批指定资源调研与接入

核实日期：2026-10-14。共 19 个链接。Unity / Unreal 资源与 MP4 视频不移植，已有 REEBOO v1.2 复用。

| 资源 | 来源 | 状态 | 交付 / 结论 |
|---|---|---|---|
| [Godot FX Collection Free](https://heyheythere.itch.io/godot-fx-collection-free) | heyheythere | 已接入 | 九个原生子包：新增 2D 效果、精灵材质、天气叠加、转场、复古屏幕、PSX 和卡通材质；魔法阵与风暴复用已单独接入的子包。 |
| [Free Rain VFX · Rain / Ripples / Splashes](https://gennai.itch.io/free-rain-vfx-godot-4) | gennai | 已接入 | 原生 3D 雨滴、地面波纹与水花；免费中雨预设，强度可实时调节。 |
| [Chest Looting VFX](https://soygus.itch.io/chest-looting-vfx) | soygus | 已接入 | 原作者宝箱模型、开箱动画、发光形状与粒子；未把示例舞台相机导入预览。 |
| [Storm & Wind 3D Free](https://heyheythere.itch.io/storm-wind-3d-free) | heyheythere | 已接入 | 六种雷击与六种阵风，共 12 个免费原始预设；其他付费种类不开放。 |
| [PARADOX Novissime · Glyph Cities Free](https://paradox-ai-creatives.itch.io/glyph-cities-free) | PARADOX | 已接入 | 地面传送门、水晶闪烁和灯光闪烁 × 四种配色；使用 Godot 交付与原始模型。 |
| [Hologram VFX 3D](https://soygus.itch.io/hologram-vfx-godot) | soygus | 已接入 | 作者三个原始全息模型场景：桶和两种坦克；可调 Visual Shader 参数。 |
| [VFX Library · Christmas Edition](https://gameutb.itch.io/vfx-library-christmas) | game.utb / Petr Medveď | 已接入 | 原始 PNG 和 FBX 素材预览，非成品特效。实验室载体支持颜色、强度、混合、序列帧和模型查看。 |
| [Brackeys VFX Bundle](https://brackeysgames.itch.io/brackeys-vfx-bundle) | Brackeys | 已接入 | 原始粒子纹理、TGA Flipbook 和 PNG 预绘序列帧；实验室 3D 载体预览，非作者成品场景。原创来源：Kenney、Picster、Thomas Iché、CodeManu。 |
| [Godot Grass Shader · 免费样例](https://binbun3d.itch.io/godot-grass) | Binbun | 已接入 | 原生草地 MultiMesh、风动、渐变颜色与地面材质；免费一个样式，付费 10 个预设未持有。 |
| [Holographic Card VFX](https://soygus.itch.io/holographic-card-vfx-godot) | soygus | 已接入 | 三个原作者全息卡片节点，含动画和 Visual Shader；源演示包含品牌卡图，使用这些图像前需另行确认相应权利。 |
| [REEBOO · Stylized VFX Free Sample](https://reebo0.itch.io/stylized-vfx-godot-free) | REEBOO Labs | 已接入 | 已有 v1.2 的命中火花、剑斩和拾取闪光，核实后复用，不重复接入。 |
| [hun0fx · Stylized Combat VFX](https://hun0fx.itch.io/stylized-combat-vfx) | Hun0FX | 待导入 | 网页演示仅供预览，明确禁止复用其纹理和特效。完整版另有 Godot 4.3+ 原生场景，目前 $20.99（原价 $29.99），未持有源文件，待购买后导入。 |
| [Lightning ShaderGraph](https://fox-jump.itch.io/lightning-shadergraph) | Fox Jump | 不适配 · 排除 | 交付 Unity .shadergraph，无 Godot 场景或 Shader。 按要求不接入。 |
| [Explosion FX Clips](https://matthornb.itch.io/explosion) | Matthew L. Hornbostel | 不适配 · 排除 | 交付三段可抠像 MP4 视频，不是 3D 特效源场景；Godot 不原生播放 MP4，未进行转码或重建。 按要求不接入。 |
| [Ascii Fx](https://nulltale.itch.io/asciifx) | Null Tale | 不适配 · 排除 | Unity URP Render Feature / RenderGraph 后处理，不能直接载入 Godot。 按要求不接入。 |
| [VolFx](https://nulltale.itch.io/volfx) | Null Tale | 不适配 · 排除 | Unity 选择性后处理、LayerMask 和自定义渲染管线工具，没有 Godot 交付。 按要求不接入。 |
| [Elemental Laser VFX Pack](https://yurikokuun.itch.io/elemental-laser-pack) | YurikoKuun | 不适配 · 排除 | 下载为 .unitypackage 与 HDR_Particle.shadergraph，无 Godot 版本。 按要求不接入。 |
| [Energy Dash](https://smartwilliam.itch.io/sfas2021vfx) | smartwilliam | 不适配 · 排除 | 作者安装说明明确要求 Unreal Engine 4.26 / Niagara。 按要求不接入。 |
| [Cartoon Comic FX Pack](https://laplahce.itch.io/cartoon-fx-pack) | laplahce | 不适配 · 排除 | itch 提供 Windows Unity 演示；完整版为 Unity URP 资源，未找到 Godot 交付。 按要求不接入。 |

## 接入范围

- Godot FX Collection：27 个新增预览项，覆盖 VFX 2D（4）、Sprite FX（6）、Weather FX 2D（3）、Scene Transitions（8）、Retro Screen（4）、PSX（1）、Toon（1）。它们是作者节点 / Shader 在实验室载体或视口叠加上的预览；其 Magic Circles 与 Storm 子包复用单独接入项，不重复增加目录。
- Storm & Wind：12 个原始预设；Glyph Cities：三个带原模型的演示效果 × 四种配色，共 12 项。
- Chest Looting：1 个原宝箱场景；Hologram：3 个原模型；Grass：1 个免费样式；Holographic Card：3 个原卡片节点。
- Christmas：40 张 PNG + 14 个 FBX UV 网格，共 54 项；不含成品 VFX。FBX 的目录纹理引用在副本中移除，几何和 UV 保留，原始 ZIP 留存。
- Brackeys：213 项 PNG/TGA 素材；文件名中的帧网格自动识别，支持帧率、混合、着色和循环。原图由 Kenney、Picster、Thomas Iché、CodeManu 制作，Brackeys 汇编，CC0。

## 预览适配

多项目合集按各子项目重定位 res://，隔离 class_name，并重建唯一 UID。卡片二进制 VisualShader 转成文本资源以修复外部脚本路径；完整节点层级保留，隐藏其他卡片以维持跨节点动画。风暴重建后参数重新解析生成的节点 / 材质；单次播放保留预览实例，游戏中的原始自动销毁逻辑不受影响。

工具：tools/fetch_more.py 下载公开免费文件；tools/convert_card_resources.py 转换卡片资源；tools/record_more_research.py 更新本记录；tools/build_catalog.py 重建目录。各包 PROVENANCE.json 保存文件名、URL、SHA-256；原始授权文本保留在资源目录。

## CC BY 4.0 署名

Godot FX Collection Free by heyheythere - https://heyheythere.itch.io/godot-fx-collection-free - CC BY 4.0

Storm & Wind 3D Free by heyheythere - https://heyheythere.itch.io/storm-wind-3d-free - CC BY 4.0

## 验证

运行 Godot --path . -- --more-qa，检查 artifacts/more-qa-report.json 和完整日志。该检查覆盖新增目录实例化、可编辑参数、模板与参数绑定、暂停、排除资源和资源页组合筛选；截图保存在 artifacts/more-*.png。
