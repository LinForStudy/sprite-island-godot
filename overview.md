# Phase 1 战斗演出基础框架 — 完成报告

## 新增文件

| 文件 | 类型 | 说明 |
|------|------|------|
| `scripts/battle/battle_action_result.gd` | GDScript (RefCounted) | 不可变数据结构，描述单次行动计算结果 |
| `scripts/battle/battle_actor.gd` | GDScript (Node2D) | 可复用战斗角色节点 |
| `scenes/battle/battle_actor.tscn` | Scene | BattleActor 场景（SpiritSprite/Shadow/锚点/AnimationPlayer） |
| `scripts/battle/battle_presentation.gd` | GDScript (Node) | 演出控制器，播放攻击/受击/HP条/飘字动画 |

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `autoload/battle_manager.gd` | 重构为计算-演出-应用三阶段分离，新增 pending_result/apply_player_result/apply_enemy_result/超时保护 |
| `scripts/ui/battle_scene.gd` | 集成 BattleActor + BattlePresentation，HP 条在 resolving 阶段由 presentation 控制 |
| `scenes/battle/battle_scene.tscn` | PlayerSpirit/EnemySpirit(TextureRect) → PlayerActor/EnemyActor(BattleActor实例)，新增 BattlePresentation + FloatingTextLayer |
| `scripts/check-project.ps1` | 新增 battle 系统文件和 token 检查，修复清理容错 |

## BattleActor 节点结构

```
BattleActor (Node2D, battle_actor.gd)
├── Shadow (ColorRect, 椭圆阴影)
├── SpiritSprite (Sprite2D, centered, 自动缩放到 240px 宽)
├── HomeAnchor (Marker2D, 记录初始位置)
├── CastPoint (Marker2D, 施法点)
├── HitPoint (Marker2D, 受击点)
├── EffectAnchor (Marker2D, 特效锚点)
├── FloatingTextAnchor (Marker2D, 飘字锚点)
└── AnimationPlayer (AnimationPlayer)
```

## BattleActionResult 字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `attacker_side` | String | "player" 或 "enemy" |
| `defender_side` | String | "player" 或 "enemy" |
| `skill` | SpiritSkill | 使用的技能 |
| `skill_display_name` | String | 技能显示名 |
| `damage` | int | 伤害值 |
| `heal` | int | 治疗值 |
| `multiplier` | float | 属性克制倍率 |
| `defender_hp_before` | int | 防御方行动前 HP |
| `defender_hp_after` | int | 防御方行动后 HP |
| `attacker_hp_before` | int | 攻击方行动前 HP |
| `attacker_hp_after` | int | 攻击方行动后 HP |
| `defender_defeated` | bool | 防御方是否被击败 |
| `is_heal` | bool | 是否为治疗行动 |
| `guard_gained` | int | 获得的守护层数 |
| `guard_consumed` | bool | 是否消耗了守护 |
| `new_energy` | int | 攻击方行动后大招能量 |
| `log_messages` | Array[String] | 战斗日志条目 |

## 玩家普通攻击完整时序

```
1. 玩家点击技能按钮
   → BattleManager.use_skill(skill_index)
   → 检查 current_phase == PLAYER_CHOOSE && !_input_consumed_this_turn
   → _input_consumed_this_turn = true (输入锁)
   → _calculate_player_action() → pending_result = BattleActionResult
   → _set_phase(RESOLVING_PLAYER)
   → _start_action_timeout() (4秒超时计时器)
   → battle_state_changed.emit()

2. battle_scene._refresh() 触发
   → _try_start_presentation()
   → battle_presentation.play_action(pending_result, _on_player_presentation_done)

3. BattlePresentation._play_basic_attack_sequence()
   → 攻击者前冲 (LUNGE_DISTANCE=120px, 0.18s)
   → 命中停顿 (HIT_STOP_DURATION=0.06s)
   → 并行: 伤害飘字 + HP条平滑下降(0.35s) + 目标震动(4步正弦)
   → 目标后退 (KNOCKBACK_DISTANCE=18px, 0.12s)
   → 目标回位 (0.12s)
   → 攻击者回位 (RETURN_DURATION=0.22s)
   → callback()

4. _on_player_presentation_done()
   → BattleManager.apply_player_result()
   → _cancel_action_timeout()
   → 从 pending_result 应用 HP/energy/guard 变更
   → 若 defender_defeated → _finish_battle(true) → VICTORY
   → 否则 → _prepare_enemy_action() → RESOLVING_ENEMY → 重复步骤 2-4
   → 若敌人未击败 → _set_phase(PLAYER_CHOOSE) → _input_consumed_this_turn = false
```

## 敌人普通攻击完整时序

```
1. apply_player_result() 完成后
   → _prepare_enemy_action()
   → _pick_enemy_skill() (AI决策不变)
   → _calculate_enemy_action() → pending_result = BattleActionResult
   → _set_phase(RESOLVING_ENEMY)
   → _start_action_timeout()
   → battle_state_changed.emit()

2-4. 与玩家流程相同，callback 为 _on_enemy_presentation_done
   → BattleManager.apply_enemy_result()
   → 若 defender_defeated → _finish_battle(false) → DEFEAT
   → 否则 → _set_phase(PLAYER_CHOOSE) → _input_consumed_this_turn = false
```

## 输入锁实现

- **双重判断**: `use_skill()` 入口同时检查 `current_phase != PLAYER_CHOOSE` 和 `_input_consumed_this_turn`
- **设置时机**: 进入 RESOLVING_PLAYER 时立即设 `_input_consumed_this_turn = true`
- **释放时机**: `apply_enemy_result()` 完成后回到 PLAYER_CHOOSE 时设 `_input_consumed_this_turn = false`
- **效果**: 连续点击技能按钮不会重复触发行动

## 超时保护实现

- **常量**: `ACTION_TIMEOUT_SECONDS: float = 4.0`
- **启动**: `_start_action_timeout()` 创建 `SceneTreeTimer`，timeout 信号连接 `_on_action_timeout`
- **触发**: 超时后 emit `presentation_timed_out` 信号 → battle_scene 调用 `battle_presentation.force_cancel()`
- **force_cancel**: kill 所有活跃 tween，reset 角色到 home 位置，snap HP 条到最终值
- **恢复**: `_on_action_timeout` 调用对应的 `apply_player_result()` 或 `apply_enemy_result()`，状态机继续推进
- **取消**: 各 apply 函数和 `close_battle_result()` 中调用 `_cancel_action_timeout()`

## 自动检查结果

- **check-project.ps1**: ✅ 通过（所有 token 检查 + Godot --script 验证）
- **verify_phase1_rules.gd**: ✅ phase-1 rules runtime check passed
- **battle_scene.tscn 3帧 headless**: ✅ 零错误退出 (exit code 0)
