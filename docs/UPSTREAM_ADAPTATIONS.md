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
