# v10 验证记录

使用 Godot 4.6.3 与 Blender 4.3.2。结果按本轮各套件的最终定向运行汇总；不把早期失败、重复运行或截图数算作额外通过。

| 无界面套件 | 检查数 | 失败 |
| --- | ---: | ---: |
| D-6 | 1855 | 0 |
| visual | 1114 | 0 |
| narrative | 1942 | 0 |
| resident | 113 | 0 |
| chapter | 123 | 0 |
| floor | 35 | 0 |
| campaign | 279 | 0 |
| campaign UI | 16 | 0 |
| refinement | 43 | 0 |
| presentation | 30 | 0 |
| exploration | 223 | 0 |
| v9 | 138 | 0 |
| v10 | 96 | 0 |

合计 **6,007 项、0 失败**。新增检查覆盖水厂阶段对白、完成后话题、卓娅两项工作的区分、星城先登记后知情、旧存档保留财物与任务、设施材质、实际厂门动画、被新物件占用的旧站位恢复及角色样片隔离。

图形模式另通过 13 项启动检查、96 项 v10 检查及 8 项受光与深度检查，共 117 项。检查实际主菜单入口、暖光/冷光/暗处的像素变化、物体投影遮挡和鞋底深度遮挡。角色图集打包逐帧检查固定画幅边界，拒绝裁头或裁脚，不通过重新缩放单帧补救。所有八方向、十六帧步态来自同一模型。

## 实机与素材检查

- X11、OpenGL / Mesa llvmpipe，实际视口 1600×1000；本次没有硬件性能测试或平台导出。
- 图形启动套件通过序章、领取补给与上下楼；v10 套件实际加载新设施并执行对话与离站回调。
- 灯光套件取样同一人物、同一像素区域。原人物保持固定亮度，新样片随真实灯光与环境光变化；用不同颜色的无光地面检查鞋底是否被错误覆盖。
- 使用缩在身体内部的胶囊近似投影，接收灯光和遮挡的位置由逐像素几何深度还原。没有将近似投影描述成精确的全身三维投影。
- 鞋底像素检查为光栅化与边缘抗锯齿留有容差，用来发现成片鞋底被地面裁去，不声称两种光栅化的边缘逐像素一致。
- 字库对 scripts、data、scenes 中运行文字的汉字覆盖检查为零缺字。
- 音频后端为 Dummy，没有听感验收；本轮没有改动战斗、饱食和经济参数。

原有测试随需求更新的地方：内部通路继续做双向实际行走；新增厂区外门按关闭出口单独测试开门与图文衔接；UI 测试等待可见开门动作结束。叶莲娜的问答断言检查其实际知情边界，避免依赖已经改掉的措辞。没有删除套件来规避失败。

## 重现

```bash
./tools/run.sh --test
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 --script res://tests/graphical_startup.gd
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 --script res://tests/ivan_lighting.gd
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 --script res://tests/v10_contract.gd
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 --script res://tools/visual_capture_v10.gd
```

图形命令需要实际可用的 X11 显示，`:99` 是本次临时显示编号。截图脚本也可传 `-- --maps-only` 或 `-- --pilot-only` 分开检查。截图与动图使用受控状态、固定镜头和实际游戏渲染，不是人工逐分钟通关，也不是用生成插画充当关卡截图。机器可读结果与图形取样见 [visual-v10](screenshots/visual-v10)。

角色样片的外观尚待用户验收；这轮没有据此批量替换人物，也没有将其记作已完成战斗动作。
