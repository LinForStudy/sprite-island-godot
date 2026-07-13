class_name BattlePresentation
extends Node

## BattlePresentation — plays battle action animations.
## Receives a BattleActionResult from BattleManager and animates the sequence:
## lunge -> hit stop -> hit reaction -> damage text -> HP bar smooth -> return.
## Calls back when complete so BattleManager can apply the result to state.
## UI never modifies HP directly; this node tweens the HP bar for display only.

const LUNGE_DISTANCE: float = 120.0
const LUNGE_DURATION: float = 0.18
const RETURN_DURATION: float = 0.22
const HIT_STOP_DURATION: float = 0.06
const KNOCKBACK_DISTANCE: float = 18.0
const KNOCKBACK_DURATION: float = 0.12
const SHAKE_AMP: float = 8.0
const SHAKE_STEP: float = 0.04
const HP_BAR_DURATION: float = 0.35
const FLOATING_TEXT_DURATION: float = 0.8
const FLOATING_TEXT_RISE: float = 40.0

var _player_actor: BattleActor = null
var _enemy_actor: BattleActor = null
var _player_hp_bar: TextureProgressBar = null
var _enemy_hp_bar: TextureProgressBar = null
var _player_hp_value: Label = null
var _enemy_hp_value: Label = null
var _floating_text_parent: Control = null

var _callback: Callable = Callable()
var _is_playing: bool = false
var _all_tweens: Array[Tween] = []

func setup(player_actor: BattleActor, enemy_actor: BattleActor,
		player_hp_bar: TextureProgressBar, enemy_hp_bar: TextureProgressBar,
		player_hp_value: Label, enemy_hp_value: Label,
		floating_text_parent: Control) -> void:
	_player_actor = player_actor
	_enemy_actor = enemy_actor
	_player_hp_bar = player_hp_bar
	_enemy_hp_bar = enemy_hp_bar
	_player_hp_value = player_hp_value
	_enemy_hp_value = enemy_hp_value
	_floating_text_parent = floating_text_parent

func is_playing() -> bool:
	return _is_playing

func play_action(result: BattleActionResult, callback: Callable) -> void:
	if _is_playing:
		return
	_is_playing = true
	_callback = callback

	var attacker: BattleActor = _player_actor if result.attacker_side == "player" else _enemy_actor
	var defender: BattleActor = _enemy_actor if result.attacker_side == "player" else _player_actor

	if result.is_heal:
		var heal_bar: TextureProgressBar = _player_hp_bar if result.attacker_side == "player" else _enemy_hp_bar
		var heal_label: Label = _player_hp_value if result.attacker_side == "player" else _enemy_hp_value
		_play_heal_sequence(attacker, result, heal_bar, heal_label)
	elif result.skill != null and result.skill.skill_role == "basic":
		var def_bar: TextureProgressBar = _enemy_hp_bar if result.attacker_side == "player" else _player_hp_bar
		var def_label: Label = _enemy_hp_value if result.attacker_side == "player" else _player_hp_value
		_play_basic_attack_sequence(attacker, defender, result, def_bar, def_label)
	else:
		var def_bar: TextureProgressBar = _enemy_hp_bar if result.attacker_side == "player" else _player_hp_bar
		var def_label: Label = _enemy_hp_value if result.attacker_side == "player" else _player_hp_value
		_play_simple_sequence(attacker, defender, result, def_bar, def_label)

func force_cancel() -> void:
	_kill_all_tweens()
	if _player_actor != null:
		_player_actor.reset_to_home()
	if _enemy_actor != null:
		_enemy_actor.reset_to_home()
	if BattleManager.pending_result != null:
		_snap_hp_to_result(BattleManager.pending_result)
	_is_playing = false

func _play_basic_attack_sequence(attacker: BattleActor, defender: BattleActor,
		result: BattleActionResult,
		def_bar: TextureProgressBar, def_label: Label) -> void:
	var attacker_home: Vector2 = attacker.get_home_position()
	var defender_home: Vector2 = defender.get_home_position()
	var direction: Vector2 = (defender.get_hit_position() - attacker.get_cast_position()).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var cast_offset: Vector2 = attacker.get_cast_position() - attacker.global_position
	var lunge_target: Vector2 = defender.get_hit_position() - cast_offset - direction * 72.0
	var knockback_target: Vector2 = defender_home + direction * KNOCKBACK_DISTANCE

	var tween: Tween = _track_tween(create_tween())

	tween.tween_property(attacker, "global_position", lunge_target, LUNGE_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_interval(HIT_STOP_DURATION)

	tween.tween_callback(func() -> void:
		_spawn_floating_text(defender, result)
		_tween_hp_bar(def_bar, def_label, result.defender_hp_after)
		_tween_shake(defender.spirit_sprite, SHAKE_AMP)
	)

	tween.tween_property(defender, "global_position", knockback_target, KNOCKBACK_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_interval(HP_BAR_DURATION)

	tween.tween_property(defender, "global_position", defender_home, RETURN_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(attacker, "global_position", attacker_home, RETURN_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(func() -> void: _finish())

func _play_simple_sequence(attacker: BattleActor, defender: BattleActor,
		result: BattleActionResult,
		def_bar: TextureProgressBar, def_label: Label) -> void:
	var tween: Tween = _track_tween(create_tween())

	tween.tween_callback(func() -> void:
		_spawn_floating_text(defender, result)
		_tween_hp_bar(def_bar, def_label, result.defender_hp_after)
		_tween_shake(defender.spirit_sprite, SHAKE_AMP * 0.5)
	)

	tween.tween_interval(HP_BAR_DURATION)

	tween.tween_callback(func() -> void: _finish())

func _play_heal_sequence(attacker: BattleActor, result: BattleActionResult,
		heal_bar: TextureProgressBar, heal_label: Label) -> void:
	var tween: Tween = _track_tween(create_tween())

	tween.tween_callback(func() -> void:
		_spawn_floating_text(attacker, result)
		_tween_hp_bar(heal_bar, heal_label, result.attacker_hp_after)
	)

	tween.tween_interval(HP_BAR_DURATION)

	tween.tween_callback(func() -> void: _finish())

func _tween_hp_bar(bar: TextureProgressBar, label: Label, target_value: int) -> void:
	var from_value: float = float(bar.value)
	var to_value: float = float(target_value)
	var max_hp: int = int(bar.max_value)
	var hp_tween: Tween = _track_tween(create_tween())
	hp_tween.tween_method(
		func(v: float) -> void:
			bar.value = v
			label.text = "%d / %d" % [int(round(v)), max_hp],
		from_value, to_value, HP_BAR_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _tween_shake(sprite: Sprite2D, amplitude: float) -> void:
	var shake_tween: Tween = _track_tween(create_tween())
	shake_tween.tween_property(sprite, "position:x", amplitude, SHAKE_STEP) \
		.set_trans(Tween.TRANS_SINE)
	shake_tween.tween_property(sprite, "position:x", -amplitude * 0.7, SHAKE_STEP) \
		.set_trans(Tween.TRANS_SINE)
	shake_tween.tween_property(sprite, "position:x", amplitude * 0.4, SHAKE_STEP) \
		.set_trans(Tween.TRANS_SINE)
	shake_tween.tween_property(sprite, "position:x", 0.0, SHAKE_STEP) \
		.set_trans(Tween.TRANS_SINE)

func _spawn_floating_text(target: BattleActor, result: BattleActionResult) -> void:
	if _floating_text_parent == null:
		return
	var label: Label = Label.new()
	if result.is_heal:
		label.text = "+%d" % result.heal
		label.add_theme_color_override("font_color", Color(0.47, 0.72, 0.29, 1))
	else:
		label.text = str(result.damage)
		if result.multiplier > 1.0:
			label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.18, 1))
		else:
			label.add_theme_color_override("font_color", Color(0.88, 0.4, 0.22, 1))
	label.add_theme_font_size_override("font_size", 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	var anchor_pos: Vector2 = target.get_floating_text_position()
	var screen_pos: Vector2 = target.get_viewport().get_canvas_transform() * anchor_pos
	label.position = screen_pos - _floating_text_parent.global_position
	_floating_text_parent.add_child(label)

	var text_tween: Tween = _track_tween(create_tween())
	text_tween.tween_property(label, "position:y", label.position.y - FLOATING_TEXT_RISE, FLOATING_TEXT_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	text_tween.parallel().tween_property(label, "modulate:a", 0.0, FLOATING_TEXT_DURATION)
	text_tween.tween_callback(label.queue_free)

func _snap_hp_to_result(result: BattleActionResult) -> void:
	if result.is_heal:
		if result.attacker_side == "player":
			_player_hp_bar.value = float(result.attacker_hp_after)
			_player_hp_value.text = "%d / %d" % [result.attacker_hp_after, int(_player_hp_bar.max_value)]
		else:
			_enemy_hp_bar.value = float(result.attacker_hp_after)
			_enemy_hp_value.text = "%d / %d" % [result.attacker_hp_after, int(_enemy_hp_bar.max_value)]
	else:
		if result.attacker_side == "player":
			_enemy_hp_bar.value = float(result.defender_hp_after)
			_enemy_hp_value.text = "%d / %d" % [result.defender_hp_after, int(_enemy_hp_bar.max_value)]
		else:
			_player_hp_bar.value = float(result.defender_hp_after)
			_player_hp_value.text = "%d / %d" % [result.defender_hp_after, int(_player_hp_bar.max_value)]

func _track_tween(t: Tween) -> Tween:
	_all_tweens.append(t)
	return t

func _kill_all_tweens() -> void:
	for t in _all_tweens:
		if t != null and t.is_valid():
			t.kill()
	_all_tweens.clear()

func _finish() -> void:
	_is_playing = false
	var cb: Callable = _callback
	_callback = Callable()
	if cb.is_valid():
		cb.call()
