# v4 实际验证

环境：Godot 4.6.3，Compatibility，X11 dummy 显示上的 Mesa llvmpipe 实际 OpenGL 帧。未用素材图代替实机截图。软件渲染用于画面正确性检查，不据此承诺桌面 GPU 帧率。

| 检查 | 结果 |
|---|---|
| `./tools/run.sh --test` | 1,826 项，0 失败 |
| `tests/visual_contract.gd` | 1,151 项，0 失败 |
| `tests/narrative_contract.gd` | 1,753 项，0 失败 |
| `tests/resident_contract.gd` | 119 项，0 失败 |
| 合计 | 4,849 项，0 失败 |

物理回归实际驱动胶囊通过所有原门口、主走廊和代表过道，并探测 141 件家具/墙段的 312 个暴露侧面及 376 个可接近墙角；探测后反向退回，确认不会楔住。以半米网格、玩家胶囊及视线检查所有新增交互可达；锁门前东段出口不可达，放行后可达。闭门 1,753 个可达格，开放东段 1,878 个可达格。西翼入口接入原来的行走区域，没有另建传送地图。

新增流程验证实际守卫寻路离岗、仍在岗时禁止撬盖、答应后未走开时仍禁止、查表期间可开、对话暂停 45 秒窗口、窗口结束恢复监督及凭据可重复使用。强制覆盖检定成功与失败两支，确认失败后仍能完成确定替代任务；同一存档检查前后读入不重掷。旧版本剧情 fixture 继续逐步核对未改动路线的消耗与奖励，显式预置本轮新增的借工具/离岗条件；没有用旧断言忽略新机制。

NPC 实际巡走 30 秒，按固定间隔检查胶囊不进入墙体/家具，检查不同角色运行中切换绘制步幅；同一控制器实际测试相对镜头八方向，含左右后斜向。实体门框与 NPC 相互碰撞、遇玩家让路均经过物理测试。快速逐字显示验证完整正文、1.2 秒上限、立即跳过以及关闭界面。

完整墙体仍有 4,324 个三角形、1,250 个顶面四边形；外法线/绕序正确，无顶面重叠。墙体遮挡保持迟滞，短暂丢失视线不会闪回；全部物品插画和角色材质存在，3D 材质有 mipmaps。v1 存档实际写盘/读盘恢复位置、物品和标记。字体包括本轮对白与 UI 使用的汉字，不需要联网字体。

## 实机截图

- [全景](screenshots/visual-v4/overview.png)、[西翼](screenshots/visual-v4/residential-wing.png)、[卧室](screenshots/visual-v4/bedroom-close.png)。
- [后左移动](screenshots/visual-v4/upper-left.png)、[后右移动](screenshots/visual-v4/upper-right.png)、[沿墙移动](screenshots/visual-v4/wall-walk-17.png)。
- [守卫通过门口](screenshots/visual-v4/guard-through-door.png)、[引开后的盖板](screenshots/visual-v4/hatch-after-diversion.png)。
- [概率选项](screenshots/visual-v4/guard-options.png)、[住户对话](screenshots/visual-v4/resident-conversation.png)、[地图](screenshots/visual-v4/map.png)。

截图工具：`DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --script res://tools/visual_capture_v4.gd`。截图测试可暂放玩家或固定镜头，但人物沿墙行走与守卫离岗使用真实 CharacterBody3D 控制器。

本轮支持闲置、行走、转向、交谈、点头/摇头与短途生活动线，未制作战斗动作或全天候 NPC 生活模拟。穿模修复基于上述物理覆盖和实机帧，不能代替后续更多玩家的长时间游玩反馈。
