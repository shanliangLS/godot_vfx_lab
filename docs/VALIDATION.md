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
