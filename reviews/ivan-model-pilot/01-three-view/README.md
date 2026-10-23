# 伊万 · 三视图 AI 建模试作 / 01

本轮完成的是**建模参考图与上传包**，尚未生成 3D 网格、骨骼或动画。游戏工程没有改动。

## 推荐查看：B 稿

B 稿比 A 稿身形修长、头部相对收敛。两版均直接参考最初认可的八方向站姿中的正面、侧面、背面，没有将 A 稿再投喂生成 B 稿。新稿属于待确认的外观候选，并不自动替代原来的伊万。

![B 稿三视图](candidate-B/three-view-preview.png)

[三视图原始大图](candidate-B/three-view-original.png) · [对照 A 稿](candidate-A/three-view-preview.png) · [最初使用的认可原图](references)

## 用于上传的三张单图

每张 1024×1024，一张图只包含一个人物。三视图使用相同的全局缩放比例，保留原绘制的身体比例，未分别拉伸身体、缩放头部或拼接肢体。B 稿原图中三个全身轮廓的高度差约 0.425%；这是轮廓高度检查，不代表骨架与服装已经完全一致。

| 视角 | 透明底 | 浅灰底 |
| --- | --- | --- |
| 正面 | [front.png](candidate-B/transparent/front.png) | [front.png](candidate-B/neutral/front.png) |
| 侧面 | [side.png](candidate-B/transparent/side.png) | [side.png](candidate-B/neutral/side.png) |
| 背面 | [back.png](candidate-B/transparent/back.png) | [back.png](candidate-B/neutral/back.png) |

[下载推荐参考图包 ZIP](ivan-model-input-B.zip?raw=true)

支持多视图的服务应分别上传三张单图，并使用它提供的方向标注。不要把三个人并排的总览图作为单张角色照片上传。透明底和浅灰底选择一套即可。

## 当前设计

普通伊万，保留原来的夹克、围巾、皮带、裤子、靴子与小背包；不带枪、不戴面具。改为适合建模的平视正交视图、轻度 A 字站姿。先验证身体外形，再处理装备组合与动画。本轮背包可先随胸腔整体运动，正式资产再评估独立挂接。

## 下一步需要什么

当前环境尚未配置 Meshy、Tripo、Rodin 等 AI 建模服务接口，也没有已安装的本地 AI 建模模型。因此本轮没有提交付费生成任务，也没有以手工粗模代替 AI 建模结果。

参考图确认后，可在支持多视图的建模平台中上传生成，再提供导出的 GLB（或配套 FBX、贴图）继续检查外形、关节网格、绑定与动作。若使用 API，需要通过安全配置提供凭据，不要在聊天或公开 GitHub 中放密钥。实际接口、费用和可导出内容以所选平台当时的功能为准。

[详细建模与验收说明](model-brief.md) · [生成提示词 B](generation-prompt-B.txt) · [参考图来源](reference-provenance.json) · [图像整理记录](candidate-B/preparation-report.json)
