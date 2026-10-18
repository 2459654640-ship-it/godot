# v12：公社生活、完整支线与水厂修复

公社议事厅从 345 平方米缩至 184 平方米，增加坐着的听众；北侧腾出的空间成为机修绕线、缝补制鞋、锅炉三间生产用房，并设生产联络廊。温室从 288 平方米扩至 594 平方米，区分平菇、芽菜、白菜、土豆和育苗用途。

家属区改成四个双人床隔间，各有门洞、储物和照明，中间走道连通厨房与守备室。暖气片靠隔间后墙，供回水管沿墙布置。原第二个空卧室成为守备值班与军需空间，有女守备员、武器清理桌、枪架、路线板与储物柜。固定居民群体从四组十二人增至六组十七人，另有可交谈角色。

[公社总览](screenshots/visual-v12/commune-overview.png) · [议事厅](screenshots/visual-v12/small-assembly.png) · [生产房](screenshots/visual-v12/production-wing.png) · [居住隔间](screenshots/visual-v12/family-alcoves.png) · [守备室](screenshots/visual-v12/militia-room.png)

新委托需要明确接受，普通介绍和拒绝不会添任务。原有工作按当地进度逐步开放；已经接下的旧版任务保留原进度。公社后续主线先做完回水维修，再转入工人联络，避免同时塞来几份工作。

两条新长支线：

- **轮班之后的歌**：认识锅炉工莫罗，检查报废扬声器、核实独立照明余量、修音箱、申请不妨碍值守的场地、问居民是否愿意听、准备海报；可决定公开演出或小范围排练。看过演出后回到设施继续探索，再领取一次性补给和歌页。可以拒绝，也能日后重新考虑。
- **补上的那一页**：先前餐食、公报委托完成后，调查巴拉诺娃亡夫被略去的记述。对照交接本、守备员和温室工的见证，保留其过去在中央苏维埃任职的事实与救人的经过，由家属决定是否公开。制作抄页，送回家属房一起读完，再结束委托。

[莫罗首次交谈](screenshots/visual-v12/moro-first-talk.png) · [公开演出](screenshots/visual-v12/moro_public_night.png) · [家属房阅读](screenshots/visual-v12/memory_reading.png)

水厂的档案室门曾被额外叠加的整片瓷砖墙挡住。现在分区材质绘制在实际墙体面上，门洞没有额外墙片；移除了各设施通用的长墙裙和任意地面补丁。积雪按真实建筑外轮廓摆放，撤去落进档案室和走廊的白色雪块。湿泵房、工具间、仓库、干燥档案室和电气房使用不同表面；增加对应设备的检修图、值班表、工具板、标签、抽屉柜、滤芯和检修垫。

[档案室门](screenshots/visual-v12/factory-archive-door.png) · [泵房](screenshots/visual-v12/factory-pump-room.png) · [修配间](screenshots/visual-v12/factory-repair-room.png) · [滤芯仓库](screenshots/visual-v12/factory-filter-warehouse.png)

水厂默认遭遇从 2 / 2 / 3 只调整为 3 / 3 / 4 只，每场有一只速度稍快。伤害没有抬高，咬击仍有 0.42 秒预警，新出现的敌人有 0.9 秒起步时间。战前保证每只敌人四发的最低总弹量；保留老兵射击、倒地救援、精确资源回滚和无损重试。已经清过的战斗不重新刷怪。

背包新增独立**武器栏**。当前可装备小队左轮；装备与持有分开，卸下不丢物品。**1 拔枪 / 收枪，鼠标瞄准，左键射击，R 换弹**。遇敌不会自动拔枪，收枪时按射击不扣弹。装备选择和拔枪状态写入存档；旧存档中的左轮迁入武器栏并保持收起。

[武器栏](screenshots/visual-v12/weapon-equipment-slot.png) · [战斗](screenshots/visual-v12/factory-combat.png)

人物保持 2D 完整绘制帧，重新校正伊万的中立过渡姿态；保留迈步之间的过渡帧，补伊万与老兵持枪行走。没有使用切腿横摆或 3D 伊万。以下预览是实际 Godot 场景中的固定相位采样，可检查动作；静态背景和固定位置便于逐帧比较，并非移动实录。

[伊万右下](screenshots/visual-v12/ivan-right-down.webp) · [伊万左下](screenshots/visual-v12/ivan-left-down.webp) · [持枪伊万](screenshots/visual-v12/armed-ivan-right-down.webp) · [持枪老兵](screenshots/visual-v12/veteran-right-down.webp)

没有新增公社大战或谢契狩猎地图，没有新增其他武器的伤害与动作。角色帧与强度仍需要实际游玩反馈；本版未进行硬件性能或声音听感验收。

低台阶补充修复：角色碰撞增加脚底支撑，并进行上方、前方和落脚面检测，允许 24 厘米内的实际跨步。公社讲台可直接走上、走下；较高设施和头顶空间不足时拒绝跨步。台上讲桌与桌子抬到实际台面高度。导航包含低台面，读档保留台上位置；没有单独把角色图片抬起来掩盖碰撞问题。

[台沿支撑](screenshots/visual-v12/stage-edge-support.png) · [站在讲台上](screenshots/visual-v12/stage-feet-on.png) · [走回地面](screenshots/visual-v12/stage-feet-off.png)

验证：Godot 4.6.3，21 组无界面回归，共 6586 项检查，失败 0。包含真实碰撞移动、任务分支、存读档、物资回滚、武器栏按钮与低台阶跨步。图形使用 OpenGL Compatibility / Mesa llvmpipe；实景截图和固定相位动画记录见 [validation.json](screenshots/visual-v12/validation.json)。

整套回归后，对公社分阶段主线及旧存档的未完成工作指引做了定向复查（135 项，通过）。
