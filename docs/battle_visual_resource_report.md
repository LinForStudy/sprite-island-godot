# 战斗场景视觉资源检查报告

## 暖尾狐战斗贴图

- 原始文件：`res://assets/spirits/09_nuan_weihu_暖尾狐.png`
- 检查结果：文件是独立 256x256 PNG，当前战斗场景没有使用 AtlasTexture、SpriteFrames 或自动裁切区域引用它。
- 风险点：像素检查发现原始 PNG 自身包含偏蓝像素区域，和验收提出的“暖尾狐附近蓝色其他萌灵残片”现象一致；这不是场景遮挡或 region 错误可以干净修复的问题。
- 本次处理：战斗中暂时改用 `res://assets/spirits/battle_placeholders/09_nuan_weihu_clean_placeholder.png`。该文件是透明背景、单只暖尾狐占位轮廓，不包含其他角色残片，也不是遮盖修补。
- 后续资源需求：需要重新导出一张正式、干净、透明背景、单只暖尾狐 PNG，再替换 `SPIRIT_TEXTURES["emberfox"]` 的战斗贴图路径。

## 泡泡汪战斗贴图

- 文件：`res://assets/spirits/05_paopao_wang_泡泡汪.png`
- 检查结果：独立 256x256 PNG，继续作为玩家战斗 Sprite2D 贴图使用。