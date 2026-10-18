# v13 人物、材质与刊物封面

本批图像由本次会话的图像工具以现有角色、服装和手绘美术为参考生成与修改。未引入外部下载素材或现成歌曲。莫罗仍为虚构的哈萨克族锅炉工；黑色蓬松中长发与朴素衣装轻度呼应维克多·崔，绘制角度采用游戏中的俯视等距角度。

## 原始素材

- `ivan_base_source.png`、`ivan_masked.png`：普通与面具版的站立、两侧迈步，各五个方向。
- `ivan_combat.png`：无面具版持枪准备、迈步与装填；`ivan_masked_ready.png`、`ivan_masked_reload.png`：面具版对应动作。`ivan_armed_reference.png` 为生成时使用的完整形象参考。
- `ivan_rear.png`：面具／无面具持枪版各六个后向准备、迈步、装填姿态。
- `commander.png`、`commander_masked.png`：中尉普通与面具版站立和两侧迈步。
- `veteran_masked_combat.png`、`veteran_masked_left.png`、`veteran_rear.png`：老兵的持枪、移动装填及相反迈步修正。`veteran_normal.png` 是完整中立姿态一行，用于基础图集与肖像。
- `static_cast.png`：莫罗、两位厨师和儿童，每人五个静态方向；这些单姿态居民固定站位，不套用假步态。`sech_cast.png`：长老和谢尔盖。
- `factory_materials.png`：八种干湿混凝土、瓷砖、灰泥、旧绿漆和锈铁，运行图为 512 像素见方。
- `publication_covers.png`、`publication_covers_extra.png`：十八张刊物封面；运行图裁切为 160×208，透明外轮廓可用于未收集剪影。

## 重建与检查

需要 Python 3、Pillow、NumPy、SciPy：

```sh
python3 tools/pack_v13_art.py
python3 tools/check_v13_art.py
```

打包器按完整人形的连通轮廓定位，不把生成图机械地等分为同高行。偶然相接的上下两个人形以窄连接处为界分离；整个人物等比缩放，头部居中、脚底对齐。不拼接腿部，不横向拉伸身体。人物主体统一为 324 像素高；普通单格 280×352、持枪单格 400×352，为枪械保留横向留白，不改变人体比例。

少数服装对称的正后方迈步采用完整姿态水平镜像，标注在 `atlas.json` 的 `frame_mirror` 中；有不对称包具的老兵不使用此方式。照明校准记录四个身体区域的共同曝光变化，运行时增益限制在 0.88–1.12，房间照明另行平滑取样。

`packing_report.json` 保存各帧边界、原始尺寸、打包位置、明度和脚步偏移。检查报告为 `docs/ART-AUDIT-V13.json`。这些数值用于找裁切、越界和同侧迈步问题，不能取代逐帧美术观察。游戏仍使用 2D 画师图集，没有恢复被放弃的 3D 伊万项目。

旧版重建脚本会重新生成旧素材；重建全项目时请最后运行 v13 打包器。图像生成原件保留，打包步骤仅做分割、裁切、完整画面等比缩放和排版。
