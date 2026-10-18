# v12 素材与重建

本批角色、居民群体、场景表面和过场图由本次会话的图像工具生成。工具没有提供精确模型版本；未下载外部素材。风格参照工程原有的手绘人物、旧苏式设施与过场插画。

- `commune_cast.png`：莫罗和亚历山德拉，每人五个静态方向。莫罗是虚构的哈萨克族锅炉工；新静态角色固定在工作区域，不套用假走路动画。
- `commune_groups.png`：三名议事厅听众、两名守备人员，整组静态绘制；每组有实际占地碰撞并参与灯光取样。
- `ivan_volume.png`：伊万及戴面具版本的中立过渡姿态，校正外套体积；保留原有两张完整迈步帧。画布中人物集中在中央，因此重建脚本明确裁去左右留白后再分格。
- `ivan_armed_walk.png`、`veteran_armed_walk.png`：持枪的两个相反迈步姿态。原有准备、射击、装填图保留；移动循环采用迈步 A → 准备姿态 → 迈步 B → 准备姿态。
- `ivan_unmasked_armed.png`：地下安全区域手动拔枪使用的无面具准备与迈步图，避免拔枪时突然戴上面具。
- `factory_materials.png`：六种水厂材料，顺序为潮湿混凝土地面、褪色蓝墙、旧瓷砖、锈钢板、橡胶检修垫、干燥档案室灰墙。
- `factory_decals.png`：泵维护图、安全须知、值班表、1962 滤芯标签、工具板、电气警告。图中的小字只作环境装饰，解谜所需信息由可读界面给出。
- `moro_scenes.png`：公开排练、锅炉房排练两幅过场。`assets/cinematics/memory_alcove.png` 是独立的家属房插画。

重建命令（Python 3、Pillow、NumPy）：

```sh
python3 tools/pack_commune_cast_v12.py
python3 tools/pack_character_v12.py
python3 tools/pack_factory_v12.py
python3 tools/make_moro_music.py
```

以上图像脚本只裁切、对齐、缩放完整画面，不用程序重画角色或生成肢体。人物头部中心对齐，统一脚底基线。AI 帧仍需人工逐帧和实景观察，不能用对齐测试替代动作质量判断。

`tools/make_moro_music.py` 制作 25 秒原创器乐小样，使用自行编排的拨弦、低音与轻打击，没有现成歌曲、歌词或录音；用于莫罗支线过场，由音乐音量控制。它不是配音或完整人声演唱。

v10 的 3D 伊万独立项目、原生模型及试验预览已经按用户要求删除，不作为本版人物来源。
