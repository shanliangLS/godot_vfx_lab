class_name ParameterDictionary extends RefCounted

const TERMS := {
	"color": ["颜色", "调整主体颜色。"], "colors": ["颜色组", "效果使用的配色。"],
	"base_color": ["基础颜色", "材质的主体颜色。"], "emission": ["发光强度", "提高亮度；启用舞台辉光可观察泛光。"],
	"emission_color": ["发光颜色", "材质自发光的颜色。"], "light_energy": ["灯光能量", "控制效果附带灯光照亮环境的强度。"],
	"speed": ["速度", "调整运动或纹理滚动速度。"], "speed_scale": ["播放速度", "调节整个动画或粒子模拟的速度倍率。"],
	"size": ["尺寸", "调整效果大小。"], "radius": ["半径", "调整效果或光束的宽度。"],
	"length": ["拖尾采样数", "GPUTrail 的历史采样点数量，数值越大拖尾越长。"],
	"length_seconds": ["拖尾时长（秒）", "根据粒子固定帧率换算拖尾持续时间。"],
	"color_ramp": ["颜色渐变", "沿拖尾或粒子生命周期变化的颜色。"],
	"curve": ["宽度曲线", "用起点、中点、终点控制拖尾宽度。"],
	"texture": ["主纹理", "拖尾或效果使用的纹理。支持内置程序纹理。"],
	"mask": ["遮罩纹理", "控制效果的透明区域。"], "mask_strength": ["遮罩强度", "调整遮罩对透明度的影响。"],
	"scroll": ["纹理滚动", "UV 纹理在水平和垂直方向的滚动速度。"],
	"vertical_texture": ["纵向纹理", "切换拖尾纹理的方向。"], "use_red_as_alpha": ["红通道作透明度", "将纹理的红色通道当作透明度。"],
	"billboard": ["朝向相机", "使拖尾面向相机；上游标为实验功能。"],
	"dewiggle": ["修正扭曲", "改善拖尾弯曲时的纹理映射。"], "clip_overlaps": ["裁剪重叠", "减少拖尾自身交叉重叠。"],
	"snap_to_transform": ["对齐当前位置", "使拖尾头部贴合节点的实时位置。"],
	"trailEnabled": ["启用拖尾", "停止后不产生新拖尾，已有拖尾逐渐消失。"],
	"fromWidth": ["起始宽度", "新生成拖尾的宽度。"], "toWidth": ["末端宽度", "拖尾尾部的宽度。"],
	"scaleAcceleration": ["宽度衰减指数", "控制宽度收缩曲线的弯曲程度。"],
	"motionDelta": ["采样距离", "移动超过此距离才增加采样点。"], "lifespan": ["拖尾寿命（秒）", "拖尾点保留时间。"],
	"scaleTexture": ["纹理按距离平铺", "按采样间距设置纹理 UV。"], "startColor": ["起始颜色", "拖尾头部颜色。"],
	"endColor": ["末端颜色", "拖尾末端颜色；降低透明度可渐隐。"],
	"colorInterpolationMode": ["颜色插值模式", "线性 / 平方 / 立方 / 四次方，决定颜色过渡曲线。"],
	"interpolationDirection": ["插值方向", "正向或反向插值。"],
	"amount": ["粒子数量", "更多粒子能提升密度，同时增加开销。"], "lifetime": ["粒子寿命（秒）", "单个粒子的存活时间。"],
	"explosiveness": ["爆发程度", "0 为连续发射，1 为同时爆发。"], "randomness": ["随机程度", "发射时间的随机性。"],
	"one_shot": ["仅播放一次", "单次发射后停止。可使用重播按钮再次播放。"], "emitting": ["发射粒子", "切换粒子发射开关。"],
	"preprocess": ["预模拟时间", "预先推进模拟，使循环效果立即呈现。"], "fixed_fps": ["模拟帧率", "粒子模拟的固定帧率；0 表示随每帧更新。"],
	"spread": ["发射扩散角", "增加后粒子发射方向更分散。"],
	"initial_velocity_min": ["最小初速度", "粒子发射时的最小速度。"], "initial_velocity_max": ["最大初速度", "粒子发射时的最大速度。"],
	"scale_min": ["最小粒子尺寸", "随机粒子尺寸的下限。"], "scale_max": ["最大粒子尺寸", "随机粒子尺寸的上限。"],
	"gravity": ["重力", "粒子所受加速度，负 Y 通常代表下落。"], "direction": ["发射方向", "粒子的初始发射方向向量。"],
	"noise": ["噪声纹理", "改变效果的形状细节。"], "noise_scale": ["噪声缩放", "控制噪声的疏密。"],
	"noise_speed": ["噪声速度", "控制噪声形状随时间变化的速度。"], "noise_strength": ["噪声强度", "调整噪声对形状的扰动。"],
	"open_amount": ["开启程度", "0 关闭，1 完全开启，可预览光束展开。"],
	"autoplay": ["自动播放", "加载效果后自动开始。"], "proximity_fade": ["近距离淡出", "效果靠近几何体时淡出，减少硬边交叉。"],
	"transparency": ["透明度模式", "控制透明表现及性能取舍。"], "dissolve": ["溶解进度", "控制效果出现与消散。"],
	"Dissovle": ["溶解强度", "上游保留的变量拼写，控制刀光噪声溶解。"],
	"Bright_Color": ["高亮颜色", "刀光最亮区域的颜色。"], "Mid_Color": ["中间颜色", "刀光的中间色。"],
	"Dark_Color": ["暗部颜色", "刀光边缘的暗色。"], "duration": ["持续时间", "效果动画的时长。"],
	"intensity": ["亮度", "控制视觉效果的亮度倍率。"], "flicker_speed": ["闪烁速度", "控制火焰明暗变化速度。"],
	"flicker_strength": ["闪烁强度", "控制火焰明暗变化幅度。"], "fade_start": ["淡出起点", "开始淡出的进度。"],
	"fade_end": ["淡出终点", "完全消失的进度。"], "offset": ["UV 偏移", "调整纹理沿 UV 的移动方向。"],
	"noise_flow": ["噪声流速", "控制噪声纹理流动。"], "Gradient_Sharpness": ["渐变锐度", "控制刀光明暗渐变。"],
	"core_color": ["核心颜色", "激光中心颜色。"], "glow_color": ["光晕颜色", "激光外围光晕颜色。"],
	"laser_width": ["激光宽度", "控制光束中心宽度。"], "pulse_speed": ["脉冲速度", "控制光束的周期变化速度。"]
}

const TOKENS := {"color":"颜色", "emission":"发光", "energy":"能量", "light":"灯光", "speed":"速度", "size":"尺寸", "radius":"半径", "scale":"缩放", "noise":"噪声", "texture":"纹理", "alpha":"透明度", "fade":"淡出", "strength":"强度", "min":"最小", "max":"最大", "hardness":"硬度", "edge":"边缘", "width":"宽度", "length":"长度", "shape":"形状", "amount":"程度", "time":"时间", "duration":"时长", "one":"单次", "shot":"发射", "scroll":"滚动", "offset":"偏移", "pulse":"脉冲", "flaring":"扩张", "flare":"闪光", "wobble":"摆动", "smooth":"平滑", "dither":"抖动", "proximity":"邻近", "enable":"启用", "enabled":"启用", "use":"使用", "auto":"自动", "play":"播放", "cut":"裁剪", "rotation":"旋转", "distortion":"扭曲", "intensity":"强度", "flame":"火焰", "spark":"火花", "target":"目标", "softness":"柔和度", "exponent":"指数", "twist":"扭转", "factor":"系数", "emitting":"发射", "resolution":"分辨率", "mesh":"网格", "subdivision":"细分", "saturation":"饱和度", "value":"明度", "hue":"色相", "base":"基础", "main":"主体", "particles":"粒子", "range":"范围", "transparency":"透明度", "density":"密度", "fringe":"边缘", "sharpness":"锐度", "mode":"模式", "type":"类型", "loop":"循环", "start":"起始", "end":"结束", "position":"位置", "brightness":"亮度", "coloring":"着色", "falloff":"衰减", "power":"强度", "soft":"柔和", "exp":"指数", "frequency":"频率", "fresnel":"菲涅耳", "rim":"边缘", "flashes":"闪光", "strengths":"强度", "local":"局部", "global":"全局", "depth":"深度", "distance":"距离", "threshold":"阈值", "opacity":"不透明度", "blur":"模糊", "smoothing":"平滑", "border":"边界", "widths":"宽度", "speedscale":"播放倍率", "surface":"表面", "metallic":"金属度", "roughness":"粗糙度", "detail":"细节", "secondary":"次级", "animation":"动画", "delay":"延迟"}

static func translate(key: String) -> String:
	var clean := key.trim_prefix("shader_parameter/")
	if TERMS.has(clean):
		return TERMS[clean][0]
	var words: Array[String] = []
	for word in clean.to_snake_case().split("_"):
		words.append(TOKENS.get(word.to_lower(), word))
	return "·".join(words)

static func describe(key: String) -> String:
	var clean := key.trim_prefix("shader_parameter/")
	if TERMS.has(clean):
		return TERMS[clean][1]
	return "原资源参数：%s。修改后立即应用到当前实例；重置可恢复作者默认值。" % clean
