# 地铁1982 · D-6

Godot 4 的等距 2.5D 叙事探索游戏。当前为 **v10：伊万角色样片、对话校对、公社与水厂场景细化**。包含两层 D-6、五张后续设施地图、全屏图文旅程与十四个可达终章，保留探索、对话、背包、子弹经济及原有美术方向。

新游戏先交代战争与伊万的童年，再从地下生活的早晨开始，缺水与征召把他带向水厂；也能自行离站，经谢尔盖、公社或谢契前往星城，追查父亲与东方-7。设施内部自由探索，设施间的地表、隧道和列车行程用图文对话与选择呈现。

[主菜单](docs/screenshots/visual-v8/main-menu.png) · [历史序章](docs/screenshots/visual-v9/prologue-family.png) · [水厂](docs/screenshots/visual-v8/waterworks-overview.png) · [公社](docs/screenshots/visual-v8/commune-overview.png) · [谢契车厢](docs/screenshots/visual-v9/sech-overview.png) · [星城](docs/screenshots/visual-v8/starcity-control.png)

[伊万行走对比动图](docs/screenshots/visual-v10/ivan-walk.webp) · [公社](docs/screenshots/visual-v10/commune-hall.png) · [水厂铁门](docs/screenshots/visual-v10/factory-exit-closed.png)

本轮改动：[对话与设施](docs/NARRATIVE-AND-FACILITIES-V10.md) · [伊万角色样片](docs/CHARACTER-PILOT-V10.md)。上一轮：[PROGRESSION-V9](docs/PROGRESSION-V9.md)。设定与支线：[WORLD-AND-QUESTS-V8](docs/WORLD-AND-QUESTS-V8.md)。测试与实机检查：[VALIDATION-V10](docs/VALIDATION-V10.md)。基础章节说明保留在 [CHAPTER-V6](docs/CHAPTER-V6.md)。旧存档可继续使用，旧地图坐标安全迁移到新入口。

## 运行

使用 **Godot 4.6.3 标准版**打开 `project.godot`，按 F6/F5 运行。无需 C#、插件、在线依赖或联网素材。首次打开等待字体和资源导入。主菜单新增「伊万角色样片」，可对比原角色与模型预渲染动画，切换暖光、冷光和暗处；独立入口不读写游戏存档，正式旅程尚未替换角色。

F5 从主菜单启动，可继续手记、新开旅程或调节声音；暂停与图文暂停页可以保存后返回主界面。直接 F6 运行单个设施场景仍可用于开发检查。

Linux / 当前云环境：

```bash
cd /workspace/godot
./tools/run.sh
```

脚本准备可写的配置、缓存和用户存档目录。可用 `GODOT_BIN` 指定 Godot，`METRO_RUNTIME_ROOT` 指定独立用户目录。桌面用户可以直接从编辑器运行。

## 操作

| 按键 | 功能 |
|---|---|
| WASD / 方向键 | 相对镜头的八方向移动 |
| E | 调查、交谈、楼梯换层 |
| I | 背包、两种弹药和物资使用 |
| J | 手记：正在跟进、已接待办、地图、百科、线索与已读记录 |
| M | 同一手记直接翻到地图；可切换查看上下层 |
| Tab / 滚轮 | 当前楼层总览 / 缩放 |
| 空格 / 点击正文 | 立即补全文字，随后选择回答 |
| Esc | 返回界面；图文旅程中打开暂停、背包与保存 |
| F5 / F9 | 场景内保存 / 读取 |

正常交谈使用头像气泡，旁白独立排版。已读记录随存档保存；未满足条件的剧情选项不展示，不通过灰色选项预告未发现的物品。对话与图文界面暂停移动。

HUD 只有一个手记入口，旁边的「留意的事」提供含蓄的当地接任务线索。未接任务不混入待办；可选一件正在跟进，其余已接任务单列。地图标出线索所在房间，不绘制精确寻路箭头。读过的信息话题收入记录，不再反复点击；往返设施和必要操作仍能重复使用。Esc 中可以分别调节音乐、一般音效和脚步声。

## 地图与经济

生活层保留卧室、食堂、维修区和西翼，增加关闭通路与远景走廊，表示 D-6 还有其它区域。东侧维修出口是木板、铁皮围住的下行坡道，在边缘互动进入图文行程，不会跌落出地图。

下层作业区约 50×27m，含工棚、修配间、医务间、装备库、集合区、煤运口、货物区和正门候车区。封闭钢门连接标准轨道，有守卫和轨道车。中尉与正式装备领取移到这里；煤运口现阶段只提供当班作业信息。

制式弹既是货币也是将来的弹药，土制弹单独保存、不能抵账。初始 18 发制式弹、12 发土制弹。第七供应点不卖武器：黑面包 4、绷带 5、急救包 12、抗辐射药 10、干电池 7、绳与布胶带 3 发；存货有限。战前伏特加可卖 18 发，出售前确认，唯一物品不能重复出售或再拿去交换。每日维生素仍是免费配给。

物资按数量保存，可在背包使用；图文暂停界面也能打开背包。伤药、食物与抗辐射药分别改变生命、饱食与已受辐射。生命与饱食常驻显示。每实际行走两分钟消耗 1 点饱食，站立、阅读、交谈和暂停不消耗；饱食为零不会持续扣血。饱食至少 40 时，每活动 90 秒恢复 1 点轻伤生命。新游戏序幕后有两份面包，D-6 厨房、公社委员会、谢契长老和煤运医护可提供每剧情日一次的免费热饭。电池可用于谢契电台供电，绳带可用于水厂物资加固；主线仍有不消耗这些物资的办法。

## 验证

```bash
./tools/run.sh --test
./tools/run.sh --headless --fixed-fps 60 --script res://tests/visual_contract.gd
./tools/run.sh --headless --script res://tests/narrative_contract.gd
./tools/run.sh --headless --fixed-fps 60 --script res://tests/resident_contract.gd
./tools/run.sh --headless --fixed-fps 60 --script res://tests/chapter_contract.gd
./tools/run.sh --headless --fixed-fps 60 --script res://tests/floor_contract.gd
```

更新字体时先完成子集生成，再单独运行一次资源导入，随后运行测试。不要同时让多个编辑器导入同一缓存，或覆盖正在导入的字体。实机截图需可用 X11 显示；云端使用临时 Xorg dummy 与实际 OpenGL，不把无界面测试冒充游戏画面。

当前打磨说明：[V10](docs/NARRATIVE-AND-FACILITIES-V10.md)。当前版本保留历史序章、v9 的三条扩展主线路径与五条支线内容，以及十四个终章，战斗系统尚未加入；即时射击与老兵同行的后续讨论稿见 [COMBAT-PROPOSAL](docs/COMBAT-PROPOSAL.md)，尚未加入敌人；既有商品价格、饱食与生命回复参数保持原值，新增防护套装售价八发制式弹。历史版本说明与截图保留在 docs 中。
