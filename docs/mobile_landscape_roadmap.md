# 手机横屏长期路线图

> 2026-07-23 状态校正：本项目已经具备遇见、战斗、直接/战后收服、小屋照料与 JSON 存档。后续 Demo 的首要重构不是从零接入这些系统，而是把现有图片式战斗升级为独立 2D 实体回合制战场。权威现状见 `demo-current-state-audit.md`，战斗规则见 `battle-design-2d-entity.md`，验收见 `demo-acceptance.md`。

## Demo 优先顺序（替代旧 Epic 排序）

1. M0：文档基线与真实运行验收。
2. M1：草丛、池塘、暖石的 2D 实体战场与有限站位。
3. M2：三系十二只萌灵的战斗动画资源生产与接入。
4. M3：三栖息地渐进解锁、探索/战斗/收服/小屋闭环。
5. M4：横屏触控、性能回归与 Demo 封版。


## 1. 项目基线（2026-07-11）

### 当前真实项目状态

- 主场景：`res://scenes/world/test_world.tscn`
- 当前 Autoload：`WorldState`
- 玩家场景：`res://scenes/player/player.tscn`
- 玩家脚本：`res://scripts/player/player.gd`
- Camera2D：已从玩家场景拆出，由世界场景的 `CameraController` 持有
- 测试地图：`res://scenes/world/test_world.tscn`、`res://scenes/world/grove_gate.tscn`
- 地图组织：多个 `TileMapLayer`，地图内容由 `res://scripts/world/world_scene.gd` 在代码中动态生成
- Tile 基础尺寸：16x16
- 当前地图尺寸：96x54 tile（由 `world_scene.gd` 动态生成）
- 对话 UI：`res://scenes/ui/dialogue_ui.tscn` + `res://scripts/ui/DialogueUI.gd`
- 输入配置来源：运行时由 `WorldState._ensure_input_map()` 注册，不在 `project.godot` 中声明
- 场景切换：`res://scripts/world/scene_exit.gd` 调用 `change_scene_to_file()`，出生点由 `WorldState` 记录 `spawn_id`
- 基线窗口：1280x720，`stretch_mode="canvas_items"`，`aspect="expand"`
- 玩家移动速度：`90.0`
- 玩家碰撞体：`CapsuleShape2D(radius=7, height=16)`
- 玩家交互范围：`CircleShape2D(radius=14)`
- 相机参数：世界场景持有 `CameraController`，启用平滑，并消费 `DisplayManager` 的 `camera_zoom`
- 当前检查：`powershell -ExecutionPolicy Bypass -File scripts/check-project.ps1` 可通过
- 当前运行验证结论：本轮未能通过 Godot CLI 实机启动；“可运行”仍主要基于 `.godot` 导入痕迹与检查脚本结果推断

### 已存在能力（保留）

- 四方向移动
- AnimatedSprite2D 行走/待机动画
- 世界级 CameraController 跟随玩家
- 两张测试地图
- TileMapLayer 基础分层
- 出生点切换
- NPC 对话
- 键盘输入动作名

### 需要重构的部分

- `WorldState` 同时承担输入注册与世界状态
- 玩家脚本直接读取 `Input`
- 相机挂在玩家内且没有设备配置层
- 地图尺寸、交互半径、道路和门宽缺乏统一标准
- 对话 UI 为固定底栏，未考虑安全区与触控

### 当前主要风险

- R1 输入耦合：`player.gd` 直接调用 `Input.get_vector()` / `Input.is_action_just_pressed()`
- R2 相机边界：基础解耦已完成，后续还需支持剧情镜头、区域镜头与动态边界
- R3 配置扩展：`DisplayManager` / `DeviceProfile` 已存在，后续要继续接 UI、安全区和触控输入
- R4 UI 固定布局：对话框写死底部偏移，未考虑异形屏与系统手势区
- R5 地图标准：测试地图已扩至 96x54 tile，但长期地图尺度、门宽、道路宽仍需成文
- R6 地图生成方式：完全脚本绘制不利于长期规模化制图与美术协作
- R7 状态散落：目前只有 `dialogue_open`，后续菜单/战斗/暂停容易冲突
- R8 文档缺失：路线图、尺度标准、输入架构、测试矩阵尚未落库
- R9 运行基线证据不足：缺少“每个任务完成后都能真实运行”的固定验证路径

### 本轮不建议动的范围

- 不重写玩家移动手感
- 不提前接入战斗、捕捉、背包
- 不批量制作正式地图
- 不一次性引入复杂 UI 主题系统
- 不把更多职责继续堆进 `WorldState`

## 2. 执行顺序原则

1. 先补审计与文档，再做配置层。
2. 先做显示/设备配置，再做相机。
3. 先做相机，再做地图尺度扩张。
4. 先做响应式 UI 基础，再做触控输入。
5. 先做输入抽象，再接摇杆和按钮。
6. 先做全局状态协调，再接探索/战斗双模式。
7. 先定 Resource 数据结构，再扩怪物和技能内容。

## 3. 阶段路线图

### 已完成

- 第一阶段探索骨架：移动、碰撞、NPC 对话、双测试图、场景出口、出生点恢复
- 基线审计文档落库
- 测试矩阵文档落库
- 设备配置 Resource 首版
- DisplayManager Autoload 首版
- 相机控制器从玩家预制体拆出，并消费设备 profile 的 zoom
- 两张测试地图从 24x16 tile 扩展到 96x54 tile，出入口、NPC 与出生点已迁移

### 进行中

- 双端长期架构从“探索演示”向“手机横屏主线架构”过渡

### 待办 Epic

- Epic 3：相机系统解耦
- Epic 4：地图尺度规范
- Epic 5：响应式 UI 基础
- Epic 6：输入架构
- Epic 7：全局游戏状态协调
- Epic 8：探索交互统一化
- Epic 9：草丛遇敌闭环
- Epic 10：战斗 UI 框架
- Epic 11：数据驱动战斗与怪物系统
- Epic 12：捕捉、队伍、背包、存档

## 4. 第一批任务状态

| Task | 标题 | 优先级 | 状态 | 备注 |
| --- | --- | --- | --- | --- |
| 0.1 | 基线审计报告 | P0 | 已完成 | 本文档基线章节已固化 |
| 0.2 | 基线运行验证能力补齐 | P0 | 进行中 | 当前先补测试矩阵与编辑器运行约定 |
| 1.1 | 建立路线图文档骨架 | P0 | 已完成 | 本文档已建立 |
| 1.2 | 建立测试矩阵文档 | P0 | 已完成 | `docs/testing_matrix.md` |
| 2.1 | 创建设备配置 Resource 类型 | P0 | 已完成 | `resources/device_profile.gd` + 两份 profile |
| 2.2 | 实现 DisplayManager Autoload | P0 | 已完成 | 已接入 `project.godot` |
| 2.3 | 显示调试面板或日志输出 | P1 | 待办 | 先保留日志接口即可 |
| 3.1 | 相机控制器解耦并接入 DisplayManager | P0 | 已完成 | CameraController 由世界场景持有 |
| 4.1 | 扩大测试地图基准尺寸 | P0 | 已完成 | 两张测试图统一为 96x54 tile |

## 5. 技术债与后续依赖

- 对话 UI 仍是固定底栏，尚未进入响应式重构。
- 输入读取仍在 `player.gd` 内，`InputRouter` 未创建。
- `WorldState` 仍保留输入注册职责，后续应迁出。
- 测试地图仍为脚本生成，长期世界尺度规范尚未成文。

## 6. 预计文件边界

### 已新增

- `docs/mobile_landscape_roadmap.md`
- `docs/testing_matrix.md`
- `resources/device_profile.gd`
- `resources/mobile_landscape_profile.tres`
- `resources/desktop_profile.tres`
- `autoload/display_manager.gd`
- `scripts/camera/camera_controller.gd`

### 后续预计新增

- `docs/world_scale_standard.md`
- `docs/ui_responsive_standard.md`
- `docs/input_architecture.md`
- `autoload/input_router.gd`
- `autoload/game_state_manager.gd`
- `ui/core/*`
- `ui/touch/*`
- `scripts/interaction/interactable.gd`
- `data/resources/*`

