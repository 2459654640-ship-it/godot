# v11 验证记录

环境：Godot 4.6.3 标准版，Linux。无界面测试使用独立用户目录；图形检查使用 Xorg dummy、Mesa llvmpipe 的实际 OpenGL Compatibility 渲染，1600×1000。没有用无界面输出代替截图。

## 自动检查

```bash
METRO_RUNTIME_ROOT=/tmp/metro-v11-release ./tools/run.sh --test
```

16 组检查涵盖 D-6 动作与通路、墙体几何、叙事分支、居民移动、章节及换层、后续地图双向过门、界面、支线、商店、存档与备份恢复、水厂战斗和动态遮挡。合计 6248 项断言通过，失败 0；具体结果记录在下表。断言数量仅代表这些已覆盖的条件，不等同于全面人工通关或美术验收。

| 检查组 | 通过的断言 |
|---|---:|
| run | 1855 |
| visual_contract | 1100 |
| narrative_contract | 1942 |
| resident_contract | 103 |
| chapter_contract | 123 |
| floor_contract | 37 |
| campaign_contract | 342 |
| campaign_ui | 17 |
| refinement_contract | 43 |
| presentation_contract | 30 |
| exploration_contract | 223 |
| v9_contract | 138 |
| v10_contract | 101 |
| v11_contract | 163 |
| v11_combat | 22 |
| occlusion_v11 | 9 |

水厂测试实际执行物理射线命中、墙体挡弹、弹仓与储备转移、老兵射击与救援、污染区移动暴露、阅读暂停、击杀回调以及死亡重试的场景重建，检查资源恢复。地图测试使用真实人物控制器双向穿过各门，并验证可达交互点；检查中修正了煤矿门边矿车的位置。

遮挡检查验证完整覆盖和擦边的透明度差别、最低不透明度、离开后恢复、碰撞不变，以及细管线在脸部位置的检测。顶部每个批次有独立透明度材质，保留原始设计标识，避免 Godot 自动更名造成重复管线漏检。

## 图形检查

```bash
DISPLAY=:99 LP_NUM_THREADS=4 godot --path . --audio-driver Dummy \
  --resolution 1600x1000 --script res://tests/graphical_startup.gd
DISPLAY=:99 LP_NUM_THREADS=4 godot --path . --audio-driver Dummy \
  --resolution 1600x1000 --script res://tools/visual_capture_v11.gd
DISPLAY=:99 LP_NUM_THREADS=4 godot --path . --audio-driver Dummy \
  --resolution 1600x1000 --script res://tools/actor_capture_v11.gd
python tools/pack_animation_previews.py
```

实际图形启动检查通过 13 项：战争序章、按顺序继续、领取维生素的真实按钮回调、返回控制以及上下层切换。受控截图位于 [visual-v11](screenshots/visual-v11)，包括新地图、战斗、购买出售、存档、对话选项和入境图文。行走预览分别采样伊万右下、左下、侧面和儿童动作；截图工具固定状态与位置，不是完整的人工游玩录像。

[右下步态](screenshots/visual-v11/ivan-diagonal-walk.webp) · [左下步态](screenshots/visual-v11/ivan-left-diagonal-walk.webp) · [侧面步态](screenshots/visual-v11/ivan-side-walk.webp) · [儿童步态](screenshots/visual-v11/child-walk.webp) · [顶部构件渐隐](screenshots/visual-v11/overhead-visibility.png)。步态使用每周期 12 个等距相位，放大检查后收小了斜向步幅，避免过度横摆。

独立试验项目也能单独启动，原有光照与脚底深度测试通过 8 项。它只说明迁出后的技术基线仍可运行，**不表示 v10 的 3D 外观已经通过验收**。

## 已知边界

- 常规人物为原画的 2D 图层变形，腿部和服装信息受原图限制；持枪为准备、后坐、换弹姿态与移动变形，尚非全身骨骼动作库。五视角仍使用镜像补足八方向。
- 常规人物的亮度按灯具与墙体遮挡采样，并非逐像素法线受光。遮挡程度使用包围盒与身体采样近似，顶部取更密的采样来识别细管线。
- 水厂是本轮战斗首关；公社大规模攻防、谢契外出狩猎与其它武器系统未在本轮实现。
- 云端音频使用 Dummy 驱动，未进行耳机或扬声器的主观听感验收。脚步继续用既有 CC0 采样；新战斗音效为短时离线合成，可调 Effects 音量。
- 本次未做 Windows/macOS 实机、其它渲染器、性能基准或长时间连续人工通关；不能据此保证所有硬件与分支组合均无问题。
