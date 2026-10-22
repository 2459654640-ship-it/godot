# v23 文案修订 · 2026-10-22

[下载当前工程](https://github.com/2459654640-ship-it/godot/archive/refs/heads/metro-v23-exterior-routing.zip) · [下载同步更新的全文案 Word](https://github.com/2459654640-ship-it/godot/raw/refs/heads/metro-reference-library/updates/v23/copy/metro1982-v23-copy.docx)

对应游戏提交 `245d9306c506acb3062826c3f82a3edc91c4da7d`。这轮修改了 79 处文字来源，包括 D-6 闲聊、公社与谢契部分对话、安娜救援、阵营汇报及相关保留稿。相同回复在任务配置、过场和交互数据里重复存放时同步修改。

修改重点是让玩家直接知道谁在做什么、谈的是什么物品、事情发生在什么时候。去掉“锅记性好”“靠猜的把他再活一遍”等含义模糊的比喻，理顺米哈伊尔忘记吃饭与加琳娜留汤的对话，补全储水期限和机械知识等问句，减少与当前话题无关的训话。保留人物关系、生活细节和必要的环境描写；正常的否定、疑问与有具体含义的对比没有机械删除。

任务触发条件、奖励、状态标记、选项 ID 和分支连接未变。结构检查逐项对照了 JSON 的非文案值，并移除字符串后比较三个 GDScript，确认代码逻辑没有改动。9 组相关流程检查均通过，见 [验证记录](verification.json) 和 [日志](logs)。本次没有修改人物或场景素材。

- [79 处改前／改后原文及来源](changes.json)
- [结构与代码逻辑核对](structure-validation.json)
- [最新全文案索引与校验](../copy/README.md)
