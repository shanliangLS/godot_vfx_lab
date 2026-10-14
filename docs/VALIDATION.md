# 验证记录

日期：2026-10-14。

引擎：用户提供的 Godot 4.7.1 stable official a13da4feb。
GPU：NVIDIA GeForce GTX 1050 Ti，Vulkan 1.3.289，Forward+。

- 50 个目录项逐个实例化，包含 11 个第三方 / 官方来源。
- 全部参数分组创建、模板切换、暂停 / 继续、参数快照恢复通过。
- 自定义预设写入磁盘、JSON 导出与重新导入、中英参数清单导出通过。
- 本地资源导入：隔离测试项目中检查 class_name 命名空间、res:// 依赖迁移、原目录内容不变，并运行复制后的场景输出 42。
- GPU 运行日志无 SCRIPT ERROR / ERROR，50 个目录项的 QA 失败数为 0。
- 分类截图位于 artifacts/；最终界面截图为 artifacts/preview.png。
- Headless 测试中 GPUTrail 无法读取屏幕刷新率，按上游逻辑回退到 60 FPS；图形运行没有该提示。

付费包未持有，因此列入待接入来源；Effekseer、独立 Kenney 包和 Unity/Fab 资源没有冒充已运行效果。

交互修复回归（同日，Godot 4.7.1 / Forward+）：

- 使用实际鼠标输入事件验证：点击字段内部保留焦点，点击界面空白解除文本与数值输入焦点；SpinBox 箭头继续可用。
- 独立颜色选择器弹窗截图确认背景不透明；选中按钮和 CheckButton 的悬停状态保持高亮。
- 暂停时右键拖动、滚轮缩放会更新镜头并触发一次视口刷新，特效时间保持不变。
- 7 个受击场景的叠加材质编译和深度设置通过，截图确认特效覆盖训练假人。
- 4 个 inspiredsloth 飞弹经过两个循环、关闭循环后结束、手动重播、暂停时重播；实例未删除，参数保留，发射器恢复，旧拖尾清空。
- --interaction-qa 输出 7 hit scenes, 4 projectile scenes, failures=0；最终日志无 SCRIPT ERROR、SHADER ERROR 或 ERROR。截图位于 artifacts/interaction-*.png。

用户指定资源扩展（同日）：

- 11 个新增原生 Godot 包、55 个效果；现有目录共 105 项、22 个已接入包。24 条用户指定资源与系列扩展的调研决策见 REQUESTED_ASSETS.md。
- --requested-qa 验证新增 55 项的实例化、全部参数页、模板切换、恢复、暂停、源资源独立性和资源卡导航。额外检查命中数据层实时重建、魔法阵重建后的粒子 / Shader 参数、单次结束保留实例、ARCFLUX 闪电循环与重播；输出 11 packs, 0 failures。
- --interaction-qa 验证 15 个受击场景、4 个 inspiredsloth 飞弹与原有焦点 / 颜色弹窗 / 暂停镜头交互，失败数为 0。输入测试只选择主窗口内可见的 SpinBox，排除 ColorPicker 内部的隐藏输入框。
- 完整目录 --qa 验证 105 项的全部参数组、模板、暂停、快照与 JSON 预设 / 参数清单导入导出。
- 原生 Godot 引擎修复 4 个共享脚本 / Shader 的重复 UID，重建生成的 UID / 文件系统缓存后重新导入。
- 最终导入与 GPU 运行日志无 SCRIPT ERROR、SHADER ERROR、ERROR 或 WARNING。专项截图为 artifacts/requested-*.png，完整目录截图与报告位于 artifacts/。
