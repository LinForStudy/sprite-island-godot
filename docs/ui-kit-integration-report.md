# 萌灵小岛 UI Kit 接入报告

## 接入结论

本次接入 `mengling_ui_kit_and_godot_plan.zip` 中的 UI 切图与参考计划。资源包来自概念设计稿自动切图，适合先做 UI 原型验证；地图参考图不适合直接变成 TileMap。

## 已入库资源

- `assets/ui/panels/`：面板、对话框切图，共 9 张。
- `assets/ui/buttons/`：确认、取消、前进按钮，共 3 张。
- `assets/ui/icons/actions/`：喂食、清洁、交互、休息图标，共 4 张。
- `assets/ui/icons/nav/`：图鉴、小屋、背包、设置导航图标，共 4 张。
- `assets/ui/hud/`：HUD 位置牌和资源条，共 2 张。
- `assets/ui/groups/`：UI 组合参考图，共 9 张。
- `assets/ui/references/`：6 张完整页面参考图，仅作为视觉参考。
- `docs/GODOT_UI_MAP_PLAN.md`：原 ZIP 内 Godot UI 与地图接入计划。

## 已接入到 Godot 的部分

- `scenes/ui/gameplay_ui.tscn`：地图 HUD、探索/遇见/图鉴/小屋/出战准备面板使用 UI kit 的面板、按钮和部分图标。
- `scenes/battle/battle_scene.tscn`：独立战斗页使用 UI kit 的面板和按钮样式。
- `scenes/ui/dialogue_ui.tscn`：对话框背景切到 UI kit 的对话框组图。

## 暂不接入地图的原因

资源包中的 6 张完整页面图和世界地图图是设计参考，不是可行走地图素材。地图后续应按计划拆为 TileSet、独立 props/buildings 场景、Y Sort 对象层、ForegroundLayer 和 CollisionLayer。本次没有替换 `tilesets/world_tiles.tres`，也没有改 TileMapLayer 绘制逻辑。

## 后续建议

1. 在 Godot 编辑器里微调 NinePatch/StyleBoxTexture 的边距，重点看大面板和按钮拉伸边缘。
2. 若要推进地图美术，单独开“地图组件化重建”任务，不要直接套完整岛屿参考图。
3. 等 UI 手感确认后，再把 `cozy_theme.tres` 抽成全局 Theme，减少场景内重复 StyleBox 配置。