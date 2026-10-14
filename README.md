# Godot 3D 特效实验室

面向 Godot 4.7.1 的成品 VFX / 插件预览项目。

目标：分类浏览真实第三方资源、查看英文参数与中文说明、实时调参、切换模板预设。

资源来源、版本和授权记录在 `data/sources.json`，第三方许可保存在对应资源目录。
购买后的资源可以通过本地目录接入；本项目不会下载付费文件或把自制示例标成第三方成品。

开发遵循功能级 Git 提交；生成缓存、下载压缩包和验证截图不纳入版本控制。

## 启动

双击/运行 RunPreview.ps1，或把 project.godot 导入 Godot 4.7.1，按 F6/F5 运行。
OpenEditor.ps1 打开编辑器。默认 Forward+；旧显卡可运行：

    powershell -ExecutionPolicy Bypass -File .\RunPreview.ps1 -Renderer gl_compatibility

Compatibility 的粒子碰撞、吸引器、拖尾等功能有限；主要验证环境为 Forward+。

## 操作

- 左侧切换攻击、受击、魔法飞弹、激光、火焰、拖尾插件、官方粒子页面。
- 资源树切换作者原始效果。右侧选择主控制器、子节点或 Shader / 粒子材质参数。
- 参数同时显示中文与英文，悬停可读中文说明；搜索支持中英关键词。
- 数值、颜色、向量、枚举、纹理、音效、渐变和宽度曲线直接应用到当前实例。
- 右键拖动旋转镜头，滚轮缩放，空格暂停，R 重播；镜头可切正面、侧面和俯视。
- 作者默认 + 烈焰、冰霜、奥术、剧毒、圣光五个实验室模板。
- 自定义预设保存到 user://lab_presets.json，可导出 / 导入 JSON；保存同名预设会更新原预设。
- 「资源 / 授权」页面明确区分已接入与待购买、待移植项目。

## 导入自己持有的资源

完整解压原项目，保留 res:// 对应根目录，使用：

    python tools/import_pack.py --source "D:\MyAssets\EffectBlocks" --id effectblocks_local --name "EffectBlocks 本地版" --category "受击 / 冲击" --mode hit

可用 --scene assets/example.tscn 指定需要接入的场景（可重复）。
脚本复制源文件到 vendor/local_<id>/，隔离路径和 class_name，不修改原目录。
在 Godot 编辑器重新导入后启动预览。

## 验证与来源

    Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --import --quit
    Godot_v4.7.1-stable_win64_console.exe --path . -- --qa

自动检查逐个实例化成品效果、创建全部参数分组、切换模板、暂停、序列化 / 恢复预设和资源页导航。
GPU 运行时生成分类截图与 artifacts/qa_report.json；检查日志中的 SCRIPT ERROR / ERROR 后才可判断通过。
上游兼容修复见 docs/UPSTREAM_ADAPTATIONS.md。

本地 Git 未连接远程。发布项目或上传仓库前，需要按各资源的原始许可处理第三方文件，特别是后续自行购买的资源。
