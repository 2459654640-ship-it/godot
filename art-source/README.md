# D-6 painterly asset sources

Current v11 animation and asset notes: [v11/README.md](v11/README.md). Historical stride sheets below remain as source art; the current game uses aligned idle paintings with articulated 2D leg layers. The v10 model experiment moved to `experiments/ivan-render-lab`, including its native source and upstream licenses.

These PNGs were generated for this project with the session's image generation
tool. The generator's exact model name is not exposed; they are not claimed to
have been made by a specifically named model. No screenshot/reference scene
was imported as a background or used as a substitute for 3D level geometry.

The character direction sheets share the Ivan sheet as a style/identity
reference. Every cast member has a separate design; five authored views mirror
to eight directions. Ivan has idle and two authored stride poses. All ten NPCs now have two authored stride rows and a conversational gesture row;
real physics velocity selects their walk poses, and dialogue selects their talk pose.
The rear-diagonal source column is mirrored during packing to match runtime yaw.
Portraits are cropped from the same figures so their identity matches gameplay.

`tools/painted-sources.json` maps source files to runtime atlases. Rebuild with:

```sh
python tools/pack_painted_assets.py --sources art-source --manifest tools/painted-sources.json
python tools/pack_painted_materials.py --sources art-source
```

Pillow and NumPy are authoring dependencies only. The game uses the prepared
PNGs, not Python or an image generation service. The packing tools slice, align,
resize and derive subtle normal/roughness channels; they do not invent faces or
repaint the character sheets. Original source PNGs are retained unchanged.

Materials: layered plaster/paint, ceramic tiles, worn wood, concrete, wool and
medallion carpet. They are applied to actual modular meshes. Item atlas: fourteen
quest items plus spare satchel and mug illustrations. V4 adds a clean cloth and
a signed heating-maintenance record, bringing usable quest illustrations to sixteen.

V5 adds the 4x2 inventory-v5.png atlas, packed by tools/pack_inventory_v5.py.
The final generated cinematic originals live in assets/cinematics (including
masked and unmasked travel variants); these are illustrations for cutscenes,
never substitutes for the 3D levels. Sergey and the veteran have separate
identities from Semyon. Runtime does not call an image service.

## v6 补充

`assets/visual/corrugated.png` 为本轮生成的旧波纹铁皮材质，采用灰绿旧漆与暗锈色，启用 mipmap 后用于下层隔断与后续设施。未替换原有木材、混凝土和人物图集。新增设施和旅程优先复用现有美术；新人物的专用外观尚未单独制作。音效与稀疏旋律由 `tools/make_campaign_audio.py` 离线合成，不含第三方采样。

## v7 补充

新增 AI 生成的水厂、公社、星城插画在 `assets/cinematics/`，克制的深色织物 UI 底纹在 `assets/visual/interface_cloth.png`。与原有暖灯、灰绿金属和手绘人物配色协调，过场插画仍只用于全屏图文剧情。

`v7-cast.png` 保留安娜与父亲的透明原始五视角图。`tools/pack_v7_cast.gd` 将其规范到原有的 240×352 单元、324 像素身体和 342 像素脚底基线，同时裁切一致的头像。两人是固定位置 NPC，当前各有一组五视角静立姿态，通过镜像支持八方向；没有宣称新增行走动作。原有人物图集保持原样。

脚步声改为 Kenney 的 CC0 walking 素材，原文件保存在 `audio/kenney_walking.ogg`，来源、提交与许可证见 [footsteps.md](../assets/audio/licenses/footsteps.md)。四个短采样经截取、滤波和淡入淡出，播放音量降低并进入独立 Footsteps 总线。UI 音效和音乐仍由原离线脚本生成；该脚本不再覆盖脚步素材。

## v8 补充

`v8/sources.json` 对应七份透明人物原图：八名独立后续角色、伊万常规及面具步态、中尉面具版本。使用 `./tools/run.sh --headless --script res://tools/pack_v8_cast.gd` 重新整理；工具按透明度分辨完整人物行和五个视角，规范尺寸与脚底，输出图集和同源头像。普通与面具伊万各三个姿态，其余新图集为静立姿态。

新插画原图直接保存在 `assets/cinematics/`，新雪地材质在 `assets/visual/ash_snow.png`，均由会话图像生成工具制作。主菜单与叙事面板实际引用这些图，未把生成图冒充三维关卡截图。后续设施用不同的现有木材、金属、旧灰泥与水泥贴图组合，配合独立布局和光照；D-6 原有材质保留。

追加两张双人五向原稿：公社印刷员娜佳、温室工卓娅、谢契轮值员彼得、星城技术员列夫。见 `v8/sources.json`，按相同基线打包；固定岗位使用静立视角，未提供协战动作。

## v9 生活人物与背景

`v8/civilian_crowd.png` 新增普通工人、披肩女居民、儿童与老妇，各五视角；儿童缩放为独立身高与碰撞。战争与母子进入地下的两幅新图用于历史序章。由图像工具生成，沿用现有笔触、比例与色彩方向；角色打包入口仍为 `tools/pack_v8_cast.gd`，保留原始透明底原稿。

## v10 伊万样片与设施素材

`v10/ivan/ivan.blend` 保留原生模型、骨架、动作与打包纹理。人体网格、青年男性形变和权重来自 MakeHuman/MPFB 的 CC0 资产；固定版本和许可证见 `v10/ivan/base/source.json`、`LICENSE-CC0.md`。本项目添加服装、装备、头发并将既有伊万原图投影到同一休止网格，所有帧都由 Blender 离线渲染，未分别生成人物帧。动作与法线重建入口为 `tools/build_ivan_pilot.py` 和 `tools/pack_ivan_pilot.py`。运行时只读预渲染 PNG，正式角色图集与头像未覆盖。完整说明见 `docs/CHARACTER-PILOT-V10.md`。

`v10/facility_materials.png` 和 `v10/commune_posters.png` 为本轮 AI 生成原稿。六类表面分别用于石质地面、旧瓷砖、厂房混凝土、土壤、菜叶与掉漆铁皮；宣传画用于公社的实际平面网格。法线与粗糙度由同一表面图保守推导。原稿与授权的插画编辑均由本会话图像工具完成，未下载来历不明的美术素材。

新增 `assets/cinematics/plant_interior.png`、`filter_return.png`，修订 `commune_threshold.png` 的伊万外观。其余场景人物与构图尽量保留。新增插画只用于图文剧情，没有替代三维地图。
