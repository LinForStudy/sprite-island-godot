# 萌灵小岛 Godot 项目 — 长期记忆

## 项目架构

### 世界地图图层结构
- **VisualGroundLayer** (wind_plaza_tiles.tres, 64px): 正式美术图层，保持可见
- **GroundLayer / DecorationLayer / CollisionLayer / TallGrassLayer / ForegroundLayer** (world_tiles.tres, 16px): 占位图层，运行时通过 `_hide_helper_layers()` 隐藏
- **CollisionGeometry**: 独立 Node2D，承载动态创建的 StaticBody2D，不受 TileMapLayer visible 影响

### 碰撞架构
- `_set_collision_tile()` 同时画 Tile 和创建 StaticBody2D
- `_add_collision_body()` 创建 16×16 RectangleShape2D，添加到 CollisionGeometry
- 隐藏 TileMapLayer 不影响碰撞 — StaticBody2D 独立于 Tile 渲染

### NameLabel 交互规则
- 所有 NameLabel 在 .tscn 中 `visible = false`，脚本在 _ready() 中确认隐藏
- 玩家进入交互 Area 时显示，离开时隐藏
- habitat_point 标签格式: `"探索%s" % display_name`（如"探索草丛"）

### 已知技术约束
- check-project.ps1 禁止 `:=` 推断类型声明和 `: Variant` 标注
- Godot 4.7 SceneTree._process() 返回 bool，不是 void
- `--script` 模式不初始化 Autoload，headless 场景测试用 `--quit-after N "res://scene.tscn"`
- 多个 .gd 文件曾有编码损坏（中文字符丢失为 `?`），已于 2026-07-12 修复
- check-project.ps1 中 Start-Process 不能用 `-FilePath` + ArgumentList 含 `--path`（PS5.1 别名冲突），改用 `Diagnostics.ProcessStartInfo`
- check-project.ps1 中 `Remove-Item -Force -Recurse` 被安全系统拦截，改用 `[System.IO.Directory]::Delete()`

### 探索/遇见/战斗准备流程
```
栖息地面板(探索点) → 开始探索 → 遇见面板(观察/挑战/离开)
  ├→ 观察：展开详情，不重生成 encounter
  ├→ 发起挑战 → 战斗准备面板(选萌灵/开始/返回) → 独立战斗场景
  └→ 离开 → 清空 encounter → HUD
```
- Encounter 只在 `GameState.start_explore()` 中生成一次（`GameCatalog.roll_encounter()`）
- `_observe_encounter()` / `_return_to_encounter()` 不调用 `start_explore()`，保证同一只萌灵
- HabitatPanel 不再有直接挑战按钮；EncounterPanel 不再有直接邀请入住按钮
- `GameState.attempt_direct_capture()` 保留代码但 UI 不连接

### 面板尺寸参考 (1280×720 基准)
| 面板 | 尺寸 |
|------|------|
| HabitatPanel | 700×340 (左右布局：图标120×120 + 文本 + 两按钮) |
| EncounterPanel | 720×460 |
| DexPanel | 920×550 |
| HomePanel | 940×560 |
| BattlePrepPanel | 720×440 |

### 战斗场景视觉架构
```
BattleScene (Control, 全屏)
├─ Background/SkyGradient/GroundLine — 按 habitat_id 三层渐变配色
├─ PlayerArea (左下 0-55%宽, 30-92%高) — 状态卡+TextureRect(280×280)+平台阴影
├─ EnemyArea (右上 45-100%宽, 0-60%高) — 状态卡+TextureRect(280×280)+平台阴影
├─ CommandPanel (底部锚定 80-100%高) — 2×2 SkillGrid + BattleInfo
└─ OverlayLayer — ResultPanel
```
- 立绘: TextureRect, expand_mode=Fit Width, stretch_mode=Keep Aspect Centered
- 状态卡: 名字/等级/属性图标/HP条+值/大招能量条+值/守护徽章
- 技能按钮: display_name 中文名优先，大招显示"需要100大招能量"
- 技能悬停: mouse_entered 在 BattleInfo 显示技能说明+属性克制
- 背景无美术素材时使用 HABITAT_BG_COLORS 渐变配色（6 habitat × 3层）

### 战斗状态机 (BattlePhase)
- `current_phase: BattlePhase` 是唯一状态来源，`battle_state.status` 是向后兼容投影
- `_set_phase()` 统一入口，保证 enum 与 status 字符串不矛盾
- 防重复：`_input_consumed_this_turn`（每回合一次输入）、`_result_finalized`（一次结算）、`_exiting`（一次场景切换）
- `use_skill()` 只在 PLAYER_CHOOSE 阶段接受输入
- 行动流程：PLAYER_CHOOSE → RESOLVING_PLAYER → (VICTORY 或 RESOLVING_ENEMY → DEFEAT 或 PLAYER_CHOOSE)
- 所有战斗数值（伤害/克制/经验/收服/大招能量/防御）未改变

### 战斗演出系统 (Phase 1)
- **计算-演出-应用三阶段分离**: use_skill()只计算不应用 → BattlePresentation播放动画 → apply_result()才修改HP/energy
- **BattleActionResult**: 不可变 RefCounted 数据结构，连接 BattleManager(计算)与 BattlePresentation(演出)
- **BattleActor**: 可复用 Node2D 角色（SpiritSprite/Shadow/Marker2D锚点/AnimationPlayer），set_spirit_texture自动缩放到240px
- **BattlePresentation**: Node节点，play_action(result, callback)分发到 _play_basic_attack_sequence 等
- **演出时序**: lunge(0.18s) → hit_stop(0.06s) → floating_text+hp_bar_tween+shake(并行0.35s) → knockback(0.12s) → return(0.22s) → callback
- **超时保护**: ACTION_TIMEOUT_SECONDS=4.0, SceneTreeTimer, 超时→force_cancel(kill tweens+reset positions)+apply_result
- **HP条平滑**: resolving阶段_refresh()跳过HP bar直接更新，由presentation._tween_hp_bar()控制
- **battle_scene.tscn节点**: PlayerActor/EnemyActor(instance battle_actor.tscn) + BattlePresentation + FloatingTextLayer
- 新增 class_name 文件后必须先 `godot --headless --import` 更新 global_script_class_cache.cfg
