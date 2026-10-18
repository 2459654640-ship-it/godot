# v11.1 素材来源与复现

下列新绘画由本次任务中的 OpenAI 图像生成工具制作，以项目现有角色/材质为风格参考。未引入网络素材或新的第三方许可。未采用外观不合格的候选稿。

| 源文件 | 用途 | 输出 |
|---|---|---|
| commune_surfaces.png | 四格材质：灰色水磨石、砖褐油毡、米色小瓷砖、旧粉刷墙 | assets/visual/commune_*.png |
| commune_resident_groups.png | 3 名工人、4 名候领居民、3 人家庭、2 名读者 | assets/characters/group_*.png |
| ivan_opposite_step.png | 原伊万形象的另一侧斜向迈步完整画稿 | ivan.png 的第 2 列、第 3 行 |
| ivan_masked_opposite_step.png | 同一迈步画稿加防毒面具 | ivan_masked.png 的同一格 |
| ivan_base.png / ivan_masked_base.png | v11 原始生产图集，用于保持其它格子不变 | 重打包基底 |

```bash
python3 tools/pack_commune_surfaces.py
python3 tools/pack_resident_groups.py
python3 tools/pack_ivan_step_fix.py
```

脚本只裁切、按统一高度缩放、对齐头部与脚底、打包，不重绘人物，也不使用网格变形制造迈步。伊万两张图集仅替换一格，其余像素保持不变；左下方向由同一原画镜像提供。没有更换头像、其它视角、战斗姿态或整个 NPC 动作库。

固定群体每组使用一张完整绘画，脚底同一基线，碰撞范围与图画宽度及固定镜头朝向对应。人物数量为背景表现，不增加可接任务或可交谈对象。
