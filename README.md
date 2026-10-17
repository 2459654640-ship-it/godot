# 地铁1982 · D-6

Godot 4 的等距 2.5D 叙事探索游戏。当前为 **v6：两层 D-6、五张后续设施地图、全屏图文旅程与九个可达终章**。保留原有探索、对话、背包、子弹经济及美术风格。

新游戏从伊万醒来开始，缺水与征召把他带向水厂；也能自行离站，经谢尔盖、公社或谢契前往星城，追查父亲与东方-7。设施内部自由探索，设施间的地表、隧道和列车行程用图文对话与选择呈现。

[全屏序幕](docs/screenshots/visual-v6/fullscreen-opening.png) · [下层楼梯间](docs/screenshots/visual-v6/stairwell.png) · [水厂](docs/screenshots/visual-v6/waterworks-overview.png) · [公社](docs/screenshots/visual-v6/commune-overview.png) · [星城](docs/screenshots/visual-v6/starcity-detail.png)

章节说明：[CHAPTER-V6](docs/CHAPTER-V6.md)。测试与实机检查：[VALIDATION-V6](docs/VALIDATION-V6.md)。旧 v5 终点存档可以继续进入后续章节。

## 运行

使用 **Godot 4.6.3 标准版**打开 `project.godot`，按 F6/F5 运行。无需 C#、插件、在线依赖或联网素材。首次打开等待字体和资源导入。

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
| J | 日志：任务背景与当前进展、已发现百科、双层地图 |
| M | 直接打开日志地图；可切换查看上下层 |
| Tab / 滚轮 | 当前楼层总览 / 缩放 |
| 空格 / 点击正文 | 立即补全文字；选择无需等待 |
| Esc | 返回界面；图文旅程中打开暂停、背包与保存 |
| F5 / F9 | 场景内保存 / 读取 |

正常交谈使用头像气泡，旁白独立排版。已读记录随存档保存；未满足条件的剧情选项不展示，不通过灰色选项预告未发现的物品。对话与图文界面暂停移动。

## 地图与经济

生活层保留卧室、食堂、维修区和西翼，增加关闭通路与远景走廊，表示 D-6 还有其它区域。东侧维修出口是木板、铁皮围住的下行坡道，在边缘互动进入图文行程，不会跌落出地图。

下层作业区约 50×27m，含工棚、修配间、医务间、装备库、集合区、煤运口、货物区和正门候车区。封闭钢门连接标准轨道，有守卫和轨道车。中尉与正式装备领取移到这里；煤运口现阶段只提供当班作业信息。

制式弹既是货币也是将来的弹药，土制弹单独保存、不能抵账。初始 18 发制式弹、12 发土制弹。第七供应点不卖武器：黑面包 4、绷带 5、急救包 12、抗辐射药 10、干电池 7、绳与布胶带 3 发；存货有限。战前伏特加可卖 18 发，出售前确认，唯一物品不能重复出售或再拿去交换。每日维生素仍是免费配给。

物资按数量保存，可在背包使用；图文暂停界面也能打开背包。伤药、食物与抗辐射药分别改变体力、饱食与已受辐射。电池和绳带保留给后续场景使用。当前保持探索与选择的玩法。干电池可用于谢契电台供电，绳带可用于水厂物资加固；主线仍有不消耗这些物资的办法。

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

当前实现范围：[V6](docs/CHAPTER-V6.md)。历史版本说明与截图保留在 docs 中。运行工程包可省略原始美术图和历史截图；GitHub 源码保留这些制作资料。
