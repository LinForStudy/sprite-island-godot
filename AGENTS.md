# 萌灵小岛 Godot 项目入口

## 项目定位

- 项目名：`萌灵小岛：Godot 原型`
- 类型：Godot 4.x 2D 俯视角怪物收集 RPG 原型
- 当前阶段：地图探索基础骨架

## 目录结构

| 目录 | 用途 |
| --- | --- |
| `scenes/` | 玩家、地图、UI、NPC、出口场景 |
| `scripts/` | 核心状态、玩家逻辑、地图构建、交互脚本 |
| `assets/placeholder/` | 第一阶段临时占位素材 |
| `tilesets/` | TileSet 资源 |
| `data/` | 后续怪物、技能、队伍、存档数据入口 |
| `docs/` | 阶段说明 |

## 运行与验证

- 用 Godot 4.x 打开 `project.godot`
- 运行主场景 `scenes/world/test_world.tscn`
- 本地检查：`powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1`

## 当前边界

- 不接入战斗、遇敌、捕捉、队伍和存档系统。
- 不引入第三方素材包；第一阶段全部使用原创占位素材。
- 只搭建后续可扩展的 RPG 地图、交互和切场景骨架。
