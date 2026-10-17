# D-6 painterly asset sources

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
