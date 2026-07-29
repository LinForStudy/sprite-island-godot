# 世界地图生产规范

## 当前正式边界

- 逻辑碰撞网格固定为 16×16px；两张世界地图均为 96×54 格，即 1536×864px。
- 视觉 TileMap 使用 64×64px 大格，每个视觉格覆盖 4×4 个逻辑格；因此当前视觉布局为 24×14 格。
- 可编辑布局数据位于 `data/maps/world_visual_layouts.json`。该文件保存视觉地表、道路矩形、细节、逻辑碰撞格与非规则碰撞矩形；`world_scene.gd` 只负责装配、动态对象与状态。
- `test_world` 与 `grove_gate` 都必须保留 `VisualGroundLayer`、`PathLayer`、`GroundDetailLayer`、`CollisionGeometry`、`HabitatPoints`、`YSortEntities` 和 `CameraController`。

## 分层与摆放

- 地表、道路、细节分别放入三个视觉 TileMapLayer；不要把整张地图重新画回脚本。
- 房屋、树干、NPC、玩家和可交互物放入启用 Y Sort 的对象层；树冠、屋顶等遮挡物放入独立前景层并使用更高 `z_index`。
- 可行走范围以 `world_visual_layouts.json` 的 `collision_cells` 与 `collision_blockers` 为准；每一个逻辑碰撞格对应 16×16px 的 `StaticBody2D`。
- 地图出口保持 `144×40px` 的交互范围，并以 `required_habitat_id` 作为单向解锁门槛；新增出口不得直接修改存档解锁状态。

## 相机与边界

- `CameraController` 由世界根节点持有并跟随 `YSortEntities/Player`；缩放来自 `DisplayManager`。
- 相机边界必须等于逻辑地图边界：左/上为 0，右/下为 `map_size × 16`。
- 新区域若修改地图尺寸，必须同步修改布局 JSON 的 `map_size`、世界 smoke 期望值和出生点/出口位置。

## 修改后的固定验证

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1
powershell -ExecutionPolicy Bypass -File scripts/run-regression.ps1
```

运行时 world smoke 会验证两张地图的逻辑尺寸、视觉网格、道路/细节层、碰撞数量、三个探索点、Y 排序与相机边界。
