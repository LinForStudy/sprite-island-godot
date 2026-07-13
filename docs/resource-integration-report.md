# 萌灵小岛美术资源接入问题报告

## 接入结论

本次资源包 `mengling_island_assets.zip` 已按“只接入合格资源、不降低项目质量”的原则处理。

已直接接入：

- `player/*.png`：8 张玩家四方向 idle / walk 图，64×64，透明背景。
- `npc/npc_keeper.png`：守望员 NPC，64×64，透明背景。
- `ui/dialog_panel.png`：对话框背景，363×309，透明背景。
- `spirits/*.png`：24 只萌灵，256×256，透明背景，已入库备用。
- `exploration_points/*.png`：6 个探索点，128×128，透明背景，已入库备用。

未直接接入地图 TileSet：

- `world/world_tiles.png`
- `world/world_tiles_64px.png`
- `world/tiles/*.png`

原因：ZIP 内 README 明确说明地图 tile 是概念美术、自动裁切图，不保证无缝拼接。为了避免地图错位或拼接质量下降，本次保留原 `assets/placeholder/world/world_tiles.png` 和 `tilesets/world_tiles.tres`，仅将这些 world 资源放入 `assets/incoming/world/` 作为后续人工确认素材。

未接入：

- `reference/full_asset_sheet.png`

原因：它是展示总图，不是可直接用于游戏的正式分层素材。

## Godot 配置处理

- 玩家图片从 32×32 替换为 64×64 后，在 `scenes/player/player.tscn` 中为 `AnimatedSprite2D` 设置 `scale = Vector2(0.5, 0.5)`，保持原视觉尺寸和碰撞体不变。
- NPC 图片从 32×32 替换为 64×64 后，在 `scenes/world/test_npc.tscn` 中为 `Sprite2D` 设置 `scale = Vector2(0.5, 0.5)`，保持原交互区域不变。
- 对话框背景替换为新图，保留原 `dialogue_ui.tscn` 的 `TextureRect` 拉伸配置。
- 本次不修改 TileSet、不修改 TileMap、不改玩法逻辑。

## 后续建议

如果要使用 ZIP 中的高清 TileSet，建议单独开一个 TileSet 实验任务：

1. 人工确认 64×64 tile 是否接受非无缝拼接。
2. 重建 `tilesets/world_tiles.tres` 的 `tile_size` 和 atlas source。
3. 同步调整地图构建脚本中的 tile 尺寸、碰撞体尺寸和相机边界。
4. 重新跑地图移动、碰撞、场景切换和探索点位置验收。