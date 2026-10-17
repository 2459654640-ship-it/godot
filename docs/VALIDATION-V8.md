# v8 验证记录

Godot 4.6.3 standard，Linux x86_64。11 组最终结果合计 **5,735 项检查，0 失败**。

| 测试 | 检查数 | 失败 |
| --- | ---: | ---: |
| D-6 原玩法、实体碰撞与通行 | 1,827 | 0 |
| 原画面约定、材质与旧存档 | 1,113 | 0 |
| 原对白、选项条件与任务状态基线 | 1,942 | 0 |
| 居民交谈、活动与让路 | 113 | 0 |
| 上下层、经济与图文章节 | 111 | 0 |
| 作业层目标与换层 | 35 | 0 |
| 后续设施谜题、导航、门洞与终章 | 282 | 0 |
| 实际按钮与跨设施图文存读档 | 16 | 0 |
| 任务分层、补给、已读与重逢 | 43 | 0 |
| v8 菜单、过场、门动画、人物与坐标迁移 | 30 | 0 |
| 十条支线、奖励、对话与内容版本迁移 | 223 | 0 |

首次整轮通过后增加了旧对白的内容版本迁移。再次检查发现旧基线把新增的 `content_revision` 存档元数据判作任务变化；比较时将它与已有存档元数据一并排除，原有物品、旗标、任务门槛与奖励快照保持不变。随后叙事及后续九组重新通过，前两组在同轮已通过。上表汇总各组最终结果。

新增支线检查逐步保存、恢复，再继续操作；提前领取、跨地图直接调用、重复领取均被拒绝。验证两个公报身份处理选项、两种退信回应能走通且各自排他。每个设施的主要设备和新目标经过角色胶囊、视线和导航可达检查；门洞用实际移动控制器双向通过。曾发现谢契立柱挤占门口，已移出开口并重测通过。

有图形的专项检查使用 Xorg dummy、OpenGL Compatibility、Mesa llvmpipe，实际运行：菜单与呈现 **31/31**，探索与问答 **223/223**。按钮测试实际点击叶莲娜的不同问题，确认每个回调对应自己的回答；名字提示检查移动人物及装备库别名绑定。新开游戏、继续、设置、返回菜单、图文中保存和读取也经过流程验证。

字体按最终内容重建，运行时汉字在两套字体中均无缺字；精确统计见 [validation.json](screenshots/visual-v8/validation.json)。

## Godot 视口截图

截图脚本准备剧情状态、冻结人物、调整镜头。下列是实际引擎渲染，不是地图概念图；这不代表逐段人工试玩录像。

- [主菜单](screenshots/visual-v8/main-menu.png)
- [首次地表](screenshots/visual-v8/first-sky.png)、[列宁像刻字](screenshots/visual-v8/lenin-inscription.png)、[途中损失](screenshots/visual-v8/road-loss.png)
- [水厂地图](screenshots/visual-v8/waterworks-overview.png)、[三名幸存者](screenshots/visual-v8/waterworks-survivors.png)
- [仓门关闭](screenshots/visual-v8/warehouse-closed.png)、[滑动中](screenshots/visual-v8/warehouse-opening.png)、[打开](screenshots/visual-v8/warehouse-open.png)
- [公社地图](screenshots/visual-v8/commune-overview.png)、[公社立场](screenshots/visual-v8/commune-leader.png)、[呼号问答](screenshots/visual-v8/commune-call-sign.png)
- [印刷委托](screenshots/visual-v8/printer-commission.png)、[跟进与待办](screenshots/visual-v8/accepted-journal.png)
- [谢契地图](screenshots/visual-v8/sech-overview.png)、[煤运照护](screenshots/visual-v8/coal-care.png)
- [星城测控](screenshots/visual-v8/starcity-control.png)、[技术员](screenshots/visual-v8/starcity-technician.png)

## 复现

```sh
./tools/run.sh --test
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 \
  --fixed-fps 60 --script res://tests/presentation_contract.gd
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 \
  --fixed-fps 60 --script res://tests/exploration_contract.gd
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 \
  --fixed-fps 60 --script res://tools/visual_capture_v8.gd -- --skip-intro
```

字体更新与资源导入顺序执行，图形检查在导入完成后运行。字体改为运行时加载，避免资源导入线程同时触发字体预加载；最终编辑器导入通过。

本次交付为 Godot 工程。软件渲染不能代替玩家设备性能测试，Dummy 音频不能代替扬声器听感检查；没有验证 Windows/macOS 导出安装包。固定岗位的新 NPC 为五视角静立素材，老兵协战、敌人和射击动画尚未实现。保留九条当前可达终章，没有照搬参考文档的全部分支。
