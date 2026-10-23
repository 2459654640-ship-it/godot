# v26 · 伊万过场形象与知情顺序修正

工程提交：`a84c30e`，分支 [metro-v26-creature-combat](https://github.com/2459654640-ship-it/godot/tree/metro-v26-creature-combat)。

## 伊万形象

- [矿区床边探视](mine_bedside-corrected.png)：移除右侧伊万的胡须，恢复年轻、干净的脸；左侧病人的胡须保留。
- [矿区探视入口](coal_threshold-corrected.png)：将左侧伊万错误的长发发髻改为原有短卷发。
- 使用最初认可的正面、侧面伊万作形象参考，保留房间、人物站位和照明。游戏中四套已认可的伊万动作图集未改。

## 彼得与北端铁路岔口

“核北道岔”是把“核对北侧道岔”压缩过度的旧句，容易误读为地名。现已删除。

1. 初识后先问“巡轨队现在缺人手吗？”。
2. 彼得说明铁轨在北端站台分成东西两线，道岔用于转轨；东线塌方而旧牌仍指向那里，并指出检修图和信号架的位置。
3. 玩家听过说明后，才出现明确的帮忙选项。听介绍不会自动接取任务。
4. 手记分阶段指出调度台、北端站台信号架、回报地点。报酬仍为原有四发制式子弹。

旧存档已经接取或做了一半的任务可继续，不要求补聊开场。

[介绍前的实际对话](screenshots/peter-before-briefing.png) · [解释与接取选项](screenshots/peter-after-explanation.png) · [当前目标](screenshots/patrol-current-goal.png) · [修正后的实际过场](screenshots/clean-shaven-ivan-bedside.png)

## 同类初次选项检查

长老先介绍需要维修的电台和旧列车，再由伊万提出帮忙。莫罗初次话题改为询问平时弹什么，由莫罗自己讲出组乐队的想法；了解后才开放筹备排练的任务。避免玩家主动说出尚未得知的计划。

相关 9 组测试通过，覆盖介绍门槛、主动接取、实际 HUD 按钮、跨存读档、旧任务续做与一次性报酬。详见 validation.json。
