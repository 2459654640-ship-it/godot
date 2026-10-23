# 伊万 · 开放权重三视图建模入口

**当前状态：参考图、输入检查和运行入口已准备；尚未运行 GPU 推理，尚无 3D 模型。**

优先方案为 [Hunyuan3D-2mv 官方仓库](https://github.com/Tencent-Hunyuan/Hunyuan3D-2)，可联合输入正面、侧面、背面。它是采用腾讯社区许可的开放权重模型，许可与使用范围见官方 LICENSE。[TripoSR](https://github.com/VAST-AI-Research/TripoSR) 为 MIT 许可，官方入口支持 CPU 回退，但只做单图重建，不能把传入三张图片理解为同一个角色的三视图。

本目录脚本根据已读取的官方多视图示例编写，不调用 Meshy、Tripo 或 Rodin 的付费服务接口。软件不要求购买这些建模平台的会员；实际执行仍需要下载权重和合适的硬件。

## 当前机器检查

- 无 NVIDIA/CUDA GPU，CPU 5 核，约 33 GiB 内存。
- 官方 GitHub 源码可下载；Hugging Face 权重下载返回网络代理 403，申请额外网络访问后仍未成功。
- 已完成三张 RGBA 输入的完整性、尺寸、轮廓高度与哈希检查。
- `--dry-run` 已在当前环境执行；正式入口在没有 GPU 时明确退出，不输出或伪装成已经生成的模型。
- 未安装大型推理依赖、未下载权重、未执行 GPU 推理，不能将本目录称为已验证的一键建模软件。

## 输入图

`inputs/front.png`、`inputs/side.png`、`inputs/back.png` 来自 [B 稿](../01-three-view/README.md)。同为 1024×1024，透明底。

特别处理了视图标注：官方示例里的 `left.png` 人物面朝画面左侧，本稿的 `side.png` 人物面朝画面右侧，因此脚本将它传入模型的 **right** 视角。没有镜像或重新生成参考图。

## 在具备 NVIDIA GPU 的机器上试运行

官方 README 标示：形状生成约需 6 GB 显存，形状与贴图完整流程约 16 GB；实际峰值依模型、分辨率、依赖版本与卸载策略而变。先做白模验收，再决定是否做贴图。

1. 建议独立 Python 环境，按 [官方安装说明](https://github.com/Tencent-Hunyuan/Hunyuan3D-2#-code) 安装与显卡兼容的 PyTorch 和依赖。源码固定提交见 source-lock.json。若做贴图，还需要官方说明中的 CUDA 光栅化及 mesh_processor 扩展。
2. 在该环境安装本目录脚本所需的 Pillow、NumPy；保留 inputs 目录。
3. 检查输入和 GPU：

```sh
python generate_ivan.py --dry-run
```

4. 先生成未绑定的三视图白模：

```sh
python generate_ivan.py --output-dir output
```

5. 外形合格后，可重新生成并附带多图条件贴图：

```sh
python generate_ivan.py --paint --output-dir output-textured
```

如已自行下载权重，可使用 `--model-path` 与 `--paint-model-path` 指定本地模型快照目录。首次在线运行将通过官方加载器下载权重。本环境尚未验证该下载和 GPU 运行步骤。

默认启用模型卸载；形状网络释放后才载入贴图网络，避免两套模型同时常驻显存。官方原始多视图形状与多图贴图示例见 source-lock.json。

## 预期输出与后续

真正成功后才会生成 `ivan-shape-unrigged.glb`、可选 `ivan-textured-unrigged.glb` 以及 generation-report.json。输出保留生成器原始坐标，待检查后再统一人物高度与游戏坐标。

**这些文件仍是未绑定的 AI 网格候选。** 需要另验头身比例、脸、手指、腋下与裆部粘连、衣服与背包结构，以及骨骼绑定后的关节变形；没有自动完成走路、持枪或换弹。不能将其直接作为角色替换进游戏。

[当前输入检查报告](preflight-result.json) · [脚本](generate_ivan.py) · [官方源码版本](source-lock.json)
