# v9 验证记录

使用 Godot 4.6.3。以下为本轮最终源码的各套件结果汇总；不是单次运行的耗时或性能指标。

| 套件 | 检查数 | 失败 |
| --- | ---: | ---: |
| d6 | 1855 | 0 |
| visual | 1114 | 0 |
| narrative | 1942 | 0 |
| resident | 113 | 0 |
| chapter | 123 | 0 |
| floor | 35 | 0 |
| campaign | 279 | 0 |
| campaign_ui | 16 | 0 |
| refinement | 43 | 0 |
| presentation | 30 | 0 |
| exploration | 223 | 0 |
| v9 | 138 | 0 |

合计 **5,911 项、0 失败**。图形模式另通过启动检查 13 项和 v9 交互检查 138 项，未计入上述合计。实际渲染使用 X11、OpenGL / Mesa llvmpipe，截图分辨率 1600×1000。音频后端为 Dummy，未做听感验收；未执行平台导出或硬件性能评估。

## 覆盖范围

- 序章顺序、父母背景、图文资源引用及新存档配给。
- 离站装备购买、免费领取与低资产路径；伊戈尔实际离开视线、门体插值与碰撞、返岗关门、内侧安全闩和免费补偿差事。
- 三条新增主线路径与五个新增终章，支线失败记录、禁止失败后领奖、任务种类与状态通知。
- 煤运区完成寻亲后仍可返回；离站确认前检查点保存未失败状态，主线与经济替代路径可继续。
- 人物知情范围、逐段对话、物品通知、主支线手记与旧存档迁移。
- 设施碰撞与通行，谢契重排后的交互点、车厢手闸与检修孔；洗手池内收及新走廊边界。
- 两套字体对 scripts、data、scenes 中运行文本的汉字覆盖检查均为零缺字。

既有测试中，固定地图边界、旧版无装备离站、同时显示全部对话、旧序章首节点和旧交互点数量的预期随需求更新。未通过删除套件规避失败。新增检查位于 `tests/v9_contract.gd`。

## 重现与截图

```bash
./tools/run.sh --test
DISPLAY=:99 ./tools/run.sh --script res://tests/graphical_startup.gd
DISPLAY=:99 ./tools/run.sh --script res://tests/v9_contract.gd
DISPLAY=:99 ./tools/run.sh --script res://tools/visual_capture_v9.gd
```

图形命令需要实际可用的 X11 显示，`:99` 是本次云环境的临时显示编号。截图脚本设置受控剧情状态、冻结角色并调整镜头，便于复查，不代表人工逐分钟通关。新增序章、门动画中间帧、任务与物品提示、失败记录、四张设施总览、书架车厢及手闸等共 17 张截图存放于 [visual-v9](screenshots/visual-v9)。机器可读汇总见 [validation.json](screenshots/visual-v9/validation.json)。

本轮新增三条主线路径、五条支线内容与五个终章，总终章数十四。战斗及老兵作战动作仍待方案确认。
