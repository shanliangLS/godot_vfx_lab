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

用户指定资源扩展：

- 十一个新包统一迁移 res:// 路径并给 class_name 加包名命名空间；跳过 macOS 元数据，重建重复 UID，保留每包原始 ZIP 哈希。多个包使用同一脚本 UID 时，用 Godot 的 ResourceUID 分配新 ID，不改变脚本行为。
- Electric / Elemental 控制器的间接光、体积雾灯光 setter 改为其实际 VFXOmniLightBB 属性名。
- 补齐 OBJ 引用但原下载未提供的 MTL。护盾 VisualShader 删除已弃用且无效果的 graph_offset。
- Loot 的三个发光 Shader 将 ALBEDO 钳制为非负值，修复 hue variation 引起的负颜色与辉光闪烁；依据作者页面的问题讨论和实际 Shader 实现。
- 龙卷风、护盾从作者示例中取出对应节点；龙卷风按可见网格包围盒居中并调整舞台载体尺寸，保留原网格与材质。
- Magic Circles 直接实例化作者 MagicArea 脚本，按其元素 / 种类配置十六项，仅开放包内实际提供的 circle / ripple。删除逻辑加实验室 metadata 例外，使单次结束后可以继续编辑与重播，普通游戏实例行为不变。
- Magic Circles 的粒子、灯光参数按当前生成节点解析；Shader 参数通过作者 set_param API 保留重建后的值。未覆盖的 Shader 参数读引擎实际默认值，不把未赋值参数显示为零。
- berryhibiscus 的 preset / layers 资源作为持久参数页，修改后使用作者 play() 重建并重新应用受击叠加。preset / palette 按实例复制，修改不泄漏到缓存的作者默认资源。
- ARCFLUX 闪电连接舞台目标并使用作者 play() / strike()；激光使用作者目标 / 碰撞控制器。Starter 的独立自动重播计时器由舞台接管，保留作者粒子、缩放与调色板处理。
