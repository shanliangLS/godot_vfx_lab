# 上游接入改动

原压缩包 SHA-256 和下载日期见各目录 PROVENANCE.json。原下载包保存在被 Git 忽略的 downloads/。

- 将原 res:// 路径迁移到 vendor/ 下各自完整目录。
- Binbun 包的共享 class_name 按包加命名空间，解决不同版本控制器重名；文件名保持原始名称。
- 移除场景中原项目 UID 引用，让 Godot 重新建立资源映射。
- Battle / Flame 示例里的 Suzanne OBJ 缺少 MTL，添加中性材质库以便无错误导入；不影响特效本体。
- Motion Trail 的嵌套 project.godot 改名为 project.godot.upstream，避免主项目忽略其脚本。
- FlameFX 的 VFXFireBB 中间接光和体积雾灯光属性名，与实际 VFXOmniLightBB 的属性名不同。修复两处 setter。
- GPUTrail 的 _get_property_list() 显式返回 Array[Dictionary]，兼容 Godot 4.7.1 的类型检查。

预览舞台的运动轨迹、配色模板、训练假人和 UI 属于本项目。它们不冒充作者的付费预设。

官方示例预览会从原始 Testers 子节点中取出各测试组，放到实验室舞台，不运行原 Demo 的镜头和 GUI。
REEBOO 免费样例的 auto_free 在预览中固定关闭，保证参数面板始终绑定同一个可重播实例。

受击预览仅修改当前实例的材质：关闭深度测试和邻近淡出，使特效显示在训练假人之上。动态 Shader 副本先展开原目录中的 include，不改写 vendor 文件。

inspiredsloth 飞弹由预览舞台管理轨迹和生命周期，禁用根节点原有的移动与自行删除逻辑，保留子节点的粒子和拖尾更新。按作者 lifetime / fade_time 淡出；循环间隔至少覆盖 lifetime + 0.5 秒。重播恢复发射器和拖尾缩放、清除拖尾历史并重启发射粒子，不播放碰撞爆炸。重播和循环保留已编辑的参数。
