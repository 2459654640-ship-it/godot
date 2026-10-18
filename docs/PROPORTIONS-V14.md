# v14：早期人物比例与八方向动作

伊万、中尉采用 V3 原图作为固定参考，老兵采用 V8 首次加入的原图。普通装、面具装与持枪动作均按相同的早期形象重绘，减轻后续多轮绘图形成的大头、大手和厚重体型。对应头像同步更新。

[早期／v13／v14 对比](screenshots/visual-v14/proportion-comparison.png) 将完整人物等比排在相同身高下；老兵比较的是实际战斗使用的持枪版本。没有对人物局部缩放来制作对比。

## 每个方向的动作

沿用五个原始绘制角度经左右镜像组成八方向。每个方向都有中立、迈步 A、迈步 B 三种完整姿态；循环为“左—站—右—站”，即三张独立姿态、四个播放相位。普通、面具、持枪及移动装填均按此检查。

三套持枪图集各保留七格：准备、射击别名、站立装填、两侧持枪迈步、两侧移动装填。射击别名与准备使用同一图，后坐仍由原有表现逻辑处理。不是宣称每套有七张不同动作。

对适用的正反面对称服装，可用完整姿态镜像形成另一侧迈步。老兵挎包不对称，因此其步态使用分别绘制的完整帧。所有人物继续使用同一身体高度、脚底锚点和原有平滑光照取样。

- [伊万八方向](screenshots/visual-v14/ivan-walk.webp)
- [面具伊万八方向](screenshots/visual-v14/ivan_masked-walk.webp)
- [面具中尉八方向](screenshots/visual-v14/commander_masked-walk.webp)
- [老兵持枪八方向](screenshots/visual-v14/veteran_masked_combat-walk.webp)
- [老兵移动装填](screenshots/visual-v14/veteran_masked_combat-reload.webp)

预览是 Godot 在同一镜头与照明下渲染的固定相位截图，按四相位组合；不是正常游玩录像。同名 PNG 同时展示三种姿态，便于逐帧比较。

## 验证

素材检查：八套图集，458 项检查通过；覆盖八方向共 80 组行走／移动装填姿态，检查全身边界、格子尺寸、三姿态差异及正反向脚步交替。检查不代替人工判断所有动作的自然度。

四组相关回归（视觉契约、人物动作、战斗、武器装备）共 1,203 项检查通过。此轮没有修改任务、战斗规则、地图碰撞或存档结构。原有 Word 文案校订本继续适用。

素材说明见 [v14 原始素材目录](../art-source/v14/README.md)。实际采集工具为 `tools/actor_audit_v14.gd`、`tools/scene_capture_v14.gd`；预览整理工具为 `tools/pack_animation_previews_v14.py`。结果见 `ART-AUDIT-V14.json` 和 `VALIDATION-V14.json`。
