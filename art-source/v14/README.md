# v14：固定早期参考的人物重绘

所有生成均以 `references/` 中的早期角色为形象和比例参考，没有继续把 v13 人物当作生成参考。原图由 Git 历史直接提取：

- `057fff3`（V3）：伊万、中尉。
- `2e799a3`（V8）：首次加入的戴面具老兵、早期面具版伊万与中尉。

`references/sources.json` 保留原图集参数；`*-idle.png` 是完整中立行，`veteran-back.png` 是原始背面全身帧。其余原图集也保留，以便追溯。图像由本会话的图像生成工具绘制，未下载外部角色素材。

`v13-validation-baseline.json` 仅保存上一版的宽度采样数值，供检查报告对照，不用于生图；因此检查工具在不带 Git 历史的工程 ZIP 中也可使用。

## 采用的素材

- `ivan.png`、`ivan_masked.png`、`commander.png`、`commander_masked.png`：每套三行、五个角度，包含中立及两侧迈步。
- `veteran_masked.png`：老兵五个中立方向。
- `*_combat.png`：两套伊万及一套老兵的持枪姿态。准备、行走、站立装填及移动装填按源表选取。面具版伊万的源表只有五行，装填部分改用完整的 `ivan_masked_reload.png` 三行，避免缺帧。
- `*_combat_front_back.png`：持枪正反面修正；老兵只取正面一行。老兵背面统一来自 `veteran_combat_rear.png` 六个原生姿态，保持挎包所在侧。

打包只分离、裁切和等比缩放完整人物。普通格为 280×352，持枪格为 400×352，主体统一为 324 像素高。头像从同一套中立形象提取。对正反面服装基本对称的人物，必要时用完整姿态镜像形成相反迈步，记录在 `frame_mirror`；不拼接肢体，也不给老兵步态帧套用这种镜像。

## 重建

Python 3、Pillow、NumPy、SciPy：

```sh
python3 tools/pack_v14_art.py
python3 tools/check_v14_art.py
```

打包器复用 v13 的完整轮廓分离、对齐与曝光校准，使用独立版本参数。重建多版素材时应最后运行 v14，以免旧脚本覆盖本次图集。`packing_report.json` 保存各帧尺寸、位置和亮度；`docs/ART-AUDIT-V14.json` 保存检查与对照数据。

头部采样宽度包含帽子和头发，躯干包络可能包含衣袖；这些数值不等于解剖学头身比。实际观感仍通过原图对比、八方向截图和游戏内近景核对。
