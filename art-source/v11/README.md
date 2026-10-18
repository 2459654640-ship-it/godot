# v11 素材

人物、持枪姿态、怪物与左轮图标由本会话图像生成工具制作，沿用既有人物形象和绘画方向。工具未披露准确模型名。原稿在本目录，图文插画原稿直接保存在 assets/cinematics；映射见 sources.json。没有下载第三方人物图或把插画当作三维关卡。

```bash
python tools/pack_combat_v11.py
python tools/pack_residents_v11.py
python tools/make_combat_audio.py
```

打包使用 Pillow 和 NumPy，运行游戏无需这些依赖。人物按头部锚点和 324 像素身体高度对齐；持枪画幅预留足够空间，不因枪管方向改变缩放。五视角通过镜像支持八方向，持枪采用准备、后坐和装填三种姿态，移动由 2D 图层变形驱动，不是完整 3D 骨骼动画。

独立物品原稿用于背包左轮图标。音效是短时离线合成，走路仍使用原来有来源记录的 Kenney CC0 采样；未添加持续噪声底。

v10 原生 3D 人物及其上游 CC0 许可证已移到 experiments/ivan-render-lab/art-source/v10/ivan，保留作未验收的独立技术基线，正式游戏不加载。
