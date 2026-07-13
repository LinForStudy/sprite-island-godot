# 萌灵小岛：Godot 原型

这是《萌灵小岛》的 Godot 4.x 第一阶段原型。

当前阶段只实现：

- 2D 俯视角玩家移动
- 四方向待机与行走动画
- Camera2D 跟随
- 多个 TileMapLayer 构成的测试地图
- 地图碰撞
- NPC 交互对话
- Area2D 场景出口
- 进入新场景后按出生点恢复玩家位置

## 运行

1. 用 Godot 4.x 打开 `sprite-island-godot/project.godot`
2. 运行主场景 `res://scenes/world/test_world.tscn`

## 操作

- `WASD` / 方向键：移动
- `Space` / `Enter` / `E`：交互

## 检查

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1
```
