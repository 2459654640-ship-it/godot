# 伊万已认可步态与装备素材

基础动作取自独立资料库 `reviews/ivan-motion-lab/09-targeted-new-frames`，审阅提交 `98c86c37e5b2e6d9825365ee3f10d71efb90acd1`。base 中保留八方向各三帧：standing、A、B，仅做色调微调，alpha、轮廓与人物比例不变。base-color-report.json 记录各材质的线性 RGB 增益与原图像素校验值，增益限制为 0.88–1.12。

三张 AI 装备原稿分别是 mask-source、ready-source、reload-source，全部直接参考最初的八方向站姿整图，生成提示词见 prompts.json。没有用反复生成的人物继续充当形象参考；没有重新生成全部步态。

运行 `python tools/pack_ivan_v20.py --review /tmp/ivan-v20` 重建四张运行图集。需要 Pillow、NumPy、SciPy。工具使用独立面具图层，武器图层替换上身及手臂，清理被新姿势替换的旧手部遮挡；头部与原有迈步保留。没有裁切、平移或镜像腿部来伪造左右步。髋部接缝使用装备画稿，原帧 y≥340 的下腿和鞋子逐像素保留。三种移动姿态共用于持枪和移动换弹，后坐力由现有角色着色器完成。

运行 `python tools/build_character_reference_v20.py` 更新 docs/characters 的当前人物示意图。审阅循环默认写到工程外，不放进游戏 docs。

没有引入 3D 伊万工程。art-source 已由根目录 .gdignore 排除，不会作为游戏运行贴图导入。

步态回归另以 tests/fixtures/ivan_approved_gait_v20.json 锁定用户认可原图的脚步 alpha 轮廓。该固定样本直接取自资料库原始 PNG，经统一打包坐标变换计算；不以运行图集本身反推样本，也不再用最下方鞋子的横坐标代替解剖左右腿判断。
