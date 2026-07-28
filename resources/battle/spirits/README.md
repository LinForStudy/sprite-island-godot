# 萌灵战斗 SpriteFrames 契约

每只萌灵使用 `res://resources/battle/spirits/<spirit_id>_combat_frames.tres`。运行时由 `GameCatalog.get_battle_frames(spirit_id)` 加载；旧版根目录资源仅作为迁移兼容。

必需动作与精确帧数：

- `idle`：4 帧，循环
- `move`：4 帧，循环
- `attack`：4 帧，不循环
- `hurt`：2 帧，不循环
- `defeat` 或 `exit`：4 帧，不循环

纹理必须为透明画布、统一脚底锚点与角色高度。正式封版不得以静态立绘回退通过严格检查。