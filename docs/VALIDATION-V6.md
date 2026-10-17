# v6 验证记录

在 Godot 4.6.3 standard Linux x86_64 实例完成。主测试命令 `./tools/run.sh --test` 退出码为 0，八组共 **5,210 项检查，0 失败**。

| 测试 | 检查数 | 失败 |
| --- | ---: | ---: |
| D-6 原玩法、移动与碰撞回归 | 1,827 | 0 |
| 墙体、材质、图标与旧存档兼容 | 1,113 | 0 |
| 原对白与任务行为契约 | 1,753 | 0 |
| 居民交谈、活动与让路 | 113 | 0 |
| 两层章节、经济与图文界面 | 101 | 0 |
| 作业层通行、目标可达与换层读档 | 35 | 0 |
| 后续剧情、物资、设施门与终章条件 | 253 | 0 |
| 实际 UI 按钮与跨设施存读档 | 15 | 0 |

完整测试后调整了楼梯台阶朝向与实际高度，重新执行受影响的 `floor_contract.gd`：35/35 通过，可达导航格 4,163。碰撞与楼层转换方式保持一致。最终楼梯截图也重新采集。

新增设施检查不只看场景能否加载：使用真实胶囊和射线检查所有交互点有可到达位置；用原角色控制器实际穿过每个主通道门口的两个方向；确认星城联锁门在解锁前实际阻挡；确认水厂和星城的谜题条件不能绕过；检查一次性奖励、可选干电池消耗、途中保存与跨设施恢复。

另以 Xorg dummy + Mesa llvmpipe 的真实 OpenGL Compatibility 模式运行 `tests/campaign_ui.gd`，15/15 通过。流程通过实际按钮进入水厂、处理设备、离开地图进入全屏旅程、选择公社，再从另一设施读取途中存档。不是只调用剧情状态函数模拟完成。

字库检查覆盖当前脚本与剧情 JSON，缺失汉字 0。所有新增音频文件均可解析为 PCM，削波样本 0；音乐与音效进入不同总线，音量控件操作实际总线。旧通风噪音文件保留，但不再被运行场景播放。云端图形验证使用 Dummy 音频输出，没有把它当作扬声器听感验收。

## 画面

以下来自引擎实际视口。采集脚本控制相机、冻结人物，并为对话与终章准备测试状态；不是新生成的场景效果图，也不是整段人工试玩的录像。

- [全屏开场](screenshots/visual-v6/fullscreen-opening.png)
- [音量设置](screenshots/visual-v6/audio-settings.png)
- [作业层总览](screenshots/visual-v6/labor-overview.png) / [独立楼梯间](screenshots/visual-v6/stairwell.png)
- [水厂](screenshots/visual-v6/waterworks-overview.png) / [泵房](screenshots/visual-v6/waterworks-detail.png)
- [公社](screenshots/visual-v6/commune-overview.png) / [温室](screenshots/visual-v6/commune-detail.png)
- [谢契](screenshots/visual-v6/sech-overview.png) / [电台](screenshots/visual-v6/sech-detail.png)
- [煤运休养区](screenshots/visual-v6/coal-overview.png) / [探访](screenshots/visual-v6/coal-detail.png)
- [星城](screenshots/visual-v6/starcity-overview.png) / [测控室](screenshots/visual-v6/starcity-detail.png)
- [父亲对白](screenshots/visual-v6/father-dialogue.png) / [终章](screenshots/visual-v6/ending.png)

采集命令：

```sh
DISPLAY=:99 ./tools/run.sh --audio-driver Dummy --resolution 1600x1000 \
  --fixed-fps 60 --script res://tools/visual_capture_v6.gd
```

仅重采楼梯画面时，在末尾加 `-- --stairs-only`。软件渲染结果用于画面与界面检查，不代表独立显卡的性能。未验证平台导出包；交付物为可在 Godot 4.6.3 打开的工程。新增人物目前复用已有美术，参考 HTML 的全部旧结局也没有逐字移植。

机器可读结果：[validation.json](screenshots/visual-v6/validation.json)。
