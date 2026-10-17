# v7 验证记录

Godot 4.6.3 standard Linux x86_64。九组测试最新结果合计 **5,442 项检查、0 失败**。

| 测试 | 检查数 | 失败 |
| --- | ---: | ---: |
| D-6 原玩法、移动与碰撞 | 1,827 | 0 |
| 墙体、材质、图标与旧存档 | 1,113 | 0 |
| 原对白、奖励与任务行为 | 1,942 | 0 |
| 居民交谈、活动与让路 | 113 | 0 |
| 两层章节、经济与图文界面 | 101 | 0 |
| 作业层通行、目标可达与换层 | 35 | 0 |
| 后续剧情、设施门、物资与终章 | 253 | 0 |
| 实际按钮与跨设施存读档 | 15 | 0 |
| v7 任务分层、补给、已读与重逢读档 | 43 | 0 |

首轮 `./tools/run.sh --test` 九组全部通过。随后扩充旧话题迁移与父亲过场读档检查，修复同地图读档丢失楼层上下文，重新通过叙事、章节、后续剧情、实际按钮及 v7 专项测试。表中为各组最终检查数；作业层有 4,135 个连通导航格。

专项测试验证未接任务隐藏、跟进与待办分离、发现照片后主动记任务、奖励交接才完成、当前地图任务优先、水厂入口值班桌提示。补给测试模拟一小时阅读不耗食物、二十分钟行走仅减 10 饱食、零饱食两小时也不掉血、轻伤缓慢恢复、免费餐食不能当天重复领取。

新增对话测试检查已读选项不能再次执行、读档后仍不能重复、旧聊天记录只迁移真实点过的话题。父亲流程通过实际 UI 按钮开始全屏重逢，保存、读回、返回人物对话，继续追问并检查不能重复触发；地图内对话插画保持原日期。

另在 Xorg dummy + Mesa llvmpipe 的真实 OpenGL Compatibility 模式运行 UI 流程：v7 专项 43/43，跨设施 UI 15/15。不是仅调用剧情状态模拟结束。

## 实际视口截图

截图脚本准备特定任务状态、冻结人物并控制相机，以下均是 Godot 实际渲染结果，不是场景概念图，也不代表整段人工试玩录像。

- [常驻生命饱食、长椅与 HUD](screenshots/visual-v7/hud-and-benches.png)
- [进行中与已接待办](screenshots/visual-v7/journal-tasks.png) / [含蓄线索](screenshots/visual-v7/journal-leads.png)
- [统一地图](screenshots/visual-v7/journal-map.png) / [水厂提示区域](screenshots/visual-v7/waterworks-map.png)
- [独立脚步音量](screenshots/visual-v7/audio-settings.png) / [双跑楼梯](screenshots/visual-v7/stairwell.png)
- [水厂入口标识](screenshots/visual-v7/waterworks-guide.png) / [水厂全屏图文](screenshots/visual-v7/waterworks-cinematic.png)
- [安娜人物与头像](screenshots/visual-v7/anna.png) / [公社图文](screenshots/visual-v7/commune-cinematic.png)
- [父亲人物与头像](screenshots/visual-v7/father.png) / [重逢图文](screenshots/visual-v7/father-cinematic.png)

复现：

```sh
./tools/run.sh --test
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 \
  --fixed-fps 60 --script res://tests/refinement_contract.gd -- --skip-intro
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 \
  --fixed-fps 60 --script res://tools/visual_capture_v7.gd -- --skip-intro
```

字库与音频静态检查结果见 [validation.json](screenshots/visual-v7/validation.json)。软件渲染不能代替玩家设备的性能测试，Dummy 音频不能代替扬声器听感检查。此次交付为 Godot 工程，未验证平台导出包。安娜和父亲新增五视角静立素材，不包含新的行走动画。
