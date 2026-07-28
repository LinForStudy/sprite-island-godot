class_name BattlePresentation
extends Node

## Presentation-only state machine. BattleManager retains every formula and applies
## the pending result only after this sequence calls its completion callback.
enum PresentationState { SELECT_COMMAND, PLAYER_PREPARE, PLAYER_MOVE, PLAYER_ATTACK, ENEMY_HURT, PLAYER_RETURN, ENEMY_PREPARE, ENEMY_ATTACK, PLAYER_HURT, ROUND_RESOLVE, BATTLE_END }
const LUNGE_DISTANCE := 120.0
const HIT_STOP_DURATION := 0.08
const HP_BAR_DURATION := 0.35
const ACTION_TIMEOUT_SECONDS := 4.0

var current_state: PresentationState = PresentationState.SELECT_COMMAND
var _player_actor: BattleActor
var _enemy_actor: BattleActor
var _player_hp_bar: TextureProgressBar
var _enemy_hp_bar: TextureProgressBar
var _player_hp_value: Label
var _enemy_hp_value: Label
var _floating_text_parent: Control
var _effect_layer: Node2D
var _camera: Camera2D
var _camera_home: Vector2 = Vector2.ZERO
var _callback: Callable = Callable()
var _active_result: BattleActionResult = null
var _is_playing: bool = false
var _all_tweens: Array[Tween] = []

func setup(player_actor: BattleActor, enemy_actor: BattleActor, player_hp_bar: TextureProgressBar, enemy_hp_bar: TextureProgressBar, player_hp_value: Label, enemy_hp_value: Label, floating_text_parent: Control, effect_layer: Node2D, camera: Camera2D) -> void:
	_player_actor = player_actor
	_enemy_actor = enemy_actor
	_player_hp_bar = player_hp_bar
	_enemy_hp_bar = enemy_hp_bar
	_player_hp_value = player_hp_value
	_enemy_hp_value = enemy_hp_value
	_floating_text_parent = floating_text_parent
	_effect_layer = effect_layer
	_camera = camera
	_camera_home = camera.position

func is_playing() -> bool:
	return _is_playing

func play_action(result: BattleActionResult, callback: Callable) -> void:
	if _is_playing:
		return
	_is_playing = true
	_callback = callback
	_active_result = result
	var attacker: BattleActor = _player_actor if result.attacker_side == "player" else _enemy_actor
	var defender: BattleActor = _enemy_actor if result.attacker_side == "player" else _player_actor
	attacker.set_facing_toward(defender.global_position)
	defender.set_facing_toward(attacker.global_position)
	current_state = PresentationState.PLAYER_PREPARE if result.attacker_side == "player" else PresentationState.ENEMY_PREPARE
	_play_audio(&"play_skill")
	if result.is_heal:
		_play_heal(attacker, result)
	elif result.skill != null and result.skill.skill_role == "ultimate":
		_play_tide(attacker, defender, result)
	elif result.skill != null and result.skill.skill_role == "element":
		_play_rush(attacker, defender, result)
	else:
		_play_tap(attacker, defender, result)

func force_cancel() -> void:
	_kill_all_tweens()
	var result: BattleActionResult = BattleManager.pending_result
	if result != null:
		_snap_hp_to_result(result)
		var defeated_actor: BattleActor = _enemy_actor if result.defender_side == "enemy" else _player_actor
		if result.defender_defeated:
			_play_defeat(defeated_actor)
	if _player_actor and (result == null or not result.defender_defeated or result.defender_side != "player"):
		_player_actor.reset_to_home()
	if _enemy_actor and (result == null or not result.defender_defeated or result.defender_side != "enemy"):
		_enemy_actor.reset_to_home()
	if _camera:
		_camera.position = _camera_home
	_active_result = null
	_is_playing = false
	current_state = PresentationState.ROUND_RESOLVE

func _play_tap(attacker: BattleActor, defender: BattleActor, result: BattleActionResult) -> void:
	var direction: Vector2 = (defender.global_position - attacker.global_position).normalized()
	var target: Vector2 = defender.global_position - direction * 92.0
	var tween: Tween = _track(create_tween())
	tween.tween_callback(func() -> void: current_state = PresentationState.PLAYER_MOVE; attacker.play_combat_action(&"move"))
	tween.tween_property(attacker, "global_position", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: current_state = PresentationState.PLAYER_ATTACK if result.attacker_side == "player" else PresentationState.ENEMY_ATTACK; attacker.play_combat_action(&"attack"); _pulse_actor(attacker, Vector2(1.13, 0.88)); _spawn_target_marker(defender); _spawn_splash(defender.get_effect_position()))
	tween.tween_interval(HIT_STOP_DURATION)
	tween.tween_callback(func() -> void: _hit(defender, result))
	tween.tween_interval(0.34)
	tween.tween_callback(func() -> void: attacker.play_combat_action(&"move"))
	tween.tween_property(attacker, "global_position", attacker.get_home_position(), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_finish)

func _play_rush(attacker: BattleActor, defender: BattleActor, result: BattleActionResult) -> void:
	var direction: Vector2 = (defender.global_position - attacker.global_position).normalized()
	var target: Vector2 = defender.global_position - direction * 76.0
	var tween: Tween = _track(create_tween())
	tween.tween_callback(func() -> void: current_state = PresentationState.PLAYER_MOVE; attacker.play_combat_action(&"move"); _pulse_actor(attacker, Vector2(0.85, 1.16)); _spawn_charge(attacker.get_effect_position()))
	tween.tween_interval(0.16)
	tween.tween_property(attacker, "global_position", target, 0.13).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: current_state = PresentationState.PLAYER_ATTACK if result.attacker_side == "player" else PresentationState.ENEMY_ATTACK; attacker.play_combat_action(&"attack"); _spawn_target_marker(defender); _spawn_splash(defender.get_effect_position()); _camera_shake(10.0); _hit(defender, result))
	tween.tween_interval(0.38)
	tween.tween_callback(func() -> void: attacker.play_combat_action(&"move"))
	tween.tween_property(attacker, "global_position", attacker.get_home_position(), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_finish)

func _play_heal(attacker: BattleActor, result: BattleActionResult) -> void:
	var tween: Tween = _track(create_tween())
	tween.tween_callback(func() -> void: attacker.play_combat_action(&"attack"); _spawn_shield(attacker.get_effect_position()); _pulse_actor(attacker, Vector2(1.08, 0.94)); _spawn_floating_text(attacker, result); _tween_hp(result))
	tween.tween_interval(0.68)
	tween.tween_callback(_finish)

func _play_tide(attacker: BattleActor, defender: BattleActor, result: BattleActionResult) -> void:
	var tween: Tween = _track(create_tween())
	tween.tween_callback(func() -> void: attacker.play_combat_action(&"attack"); _darken_field(); _spawn_target_marker(defender); _spawn_tide(attacker.global_position, defender.global_position))
	tween.tween_interval(0.30)
	tween.tween_callback(func() -> void: _camera_shake(9.0); _hit(defender, result))
	tween.tween_interval(0.62)
	tween.tween_callback(_finish)

func _hit(defender: BattleActor, result: BattleActionResult) -> void:
	current_state = PresentationState.ENEMY_HURT if result.attacker_side == "player" else PresentationState.PLAYER_HURT
	defender.play_combat_action(&"hurt")
	_play_audio(&"play_hurt")
	_flash_actor(defender)
	_knockback(defender)
	_spawn_floating_text(defender, result)
	_tween_hp(result)
	if result.defender_defeated:
		var defeat_tween: Tween = _track(create_tween())
		defeat_tween.tween_interval(0.22)
		defeat_tween.tween_callback(func() -> void: _play_defeat(defender))

func _play_defeat(defender: BattleActor) -> void:
	current_state = PresentationState.BATTLE_END
	defender.play_combat_action(&"defeat")
	var tween: Tween = _track(create_tween())
	tween.tween_property(defender.visual_root, "position:y", 14.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(defender.visual_root, "modulate:a", 0.35, 0.34)
	tween.parallel().tween_property(defender.shadow, "modulate:a", 0.14, 0.34)

func _tween_hp(result: BattleActionResult) -> void:
	var bar: TextureProgressBar = _player_hp_bar if (result.is_heal and result.attacker_side == "player") or (not result.is_heal and result.attacker_side == "enemy") else _enemy_hp_bar
	var label: Label = _player_hp_value if bar == _player_hp_bar else _enemy_hp_value
	var target: int = result.attacker_hp_after if result.is_heal else result.defender_hp_after
	var from: float = bar.value
	_track(create_tween()).tween_method(func(v: float) -> void: bar.value = v; label.text = "%d / %d" % [roundi(v), roundi(bar.max_value)], from, float(target), HP_BAR_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _flash_actor(actor: BattleActor) -> void:
	var tween: Tween = _track(create_tween())
	tween.tween_property(actor.visual_root, "modulate", Color(2.3, 2.3, 2.3, 1.0), 0.04)
	tween.tween_property(actor.visual_root, "modulate", Color.WHITE, 0.16)

func _knockback(actor: BattleActor) -> void:
	var direction: Vector2 = (actor.global_position - ( _player_actor.global_position if actor == _enemy_actor else _enemy_actor.global_position)).normalized()
	var home: Vector2 = actor.get_home_position()
	var tween: Tween = _track(create_tween())
	tween.tween_property(actor, "global_position", home + direction * 18.0, 0.10)
	tween.tween_property(actor, "global_position", home, 0.18)

func _pulse_actor(actor: BattleActor, peak: Vector2) -> void:
	var base_scale: Vector2 = actor.visual_root.scale
	var tween: Tween = _track(create_tween())
	tween.tween_property(actor.visual_root, "scale", Vector2(peak.x * base_scale.x, peak.y * base_scale.y), 0.10)
	tween.tween_property(actor.visual_root, "scale", base_scale, 0.16)

func _camera_shake(amplitude: float) -> void:
	if _camera == null: return
	var tween: Tween = _track(create_tween())
	for offset in [Vector2(amplitude, -amplitude * 0.4), Vector2(-amplitude, amplitude * 0.4), Vector2(amplitude * 0.4, 0.0), Vector2.ZERO]:
		tween.tween_property(_camera, "position", _camera_home + offset, 0.045)

func _spawn_target_marker(target: BattleActor) -> void:
	if _effect_layer == null:
		return
	var marker: Node2D = Node2D.new()
	marker.position = target.global_position + Vector2(0.0, -4.0)
	_effect_layer.add_child(marker)
	var ring: Line2D = Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.47, 0.20, 0.96)
	ring.antialiased = true
	for index in range(25):
		var angle: float = TAU * float(index) / 24.0
		ring.add_point(Vector2(cos(angle) * 66.0, sin(angle) * 20.0))
	marker.add_child(ring)
	var arrow: Polygon2D = Polygon2D.new()
	arrow.color = Color(1.0, 0.76, 0.36, 1.0)
	arrow.polygon = PackedVector2Array([Vector2(-18.0, -142.0), Vector2(18.0, -142.0), Vector2(18.0, -154.0), Vector2(34.0, -154.0), Vector2(0.0, -186.0), Vector2(-34.0, -154.0), Vector2(-18.0, -154.0)])
	marker.add_child(arrow)
	var tween: Tween = _track(create_tween())
	marker.scale = Vector2(0.78, 0.78)
	tween.tween_property(marker, "scale", Vector2(1.08, 1.08), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.24)
	tween.tween_property(marker, "modulate:a", 0.0, 0.18)
	tween.tween_callback(marker.queue_free)
func _spawn_splash(pos: Vector2) -> void:
	_spawn_disc(pos, Color(0.35, 0.78, 1.0, 0.82), 18.0, 0.32)
	_spawn_disc(pos + Vector2(22, -12), Color(0.75, 0.94, 1.0, 0.9), 9.0, 0.28)

func _spawn_charge(pos: Vector2) -> void:
	_spawn_disc(pos, Color(0.33, 0.70, 1.0, 0.45), 34.0, 0.30)

func _spawn_shield(pos: Vector2) -> void:
	_spawn_disc(pos, Color(0.34, 0.83, 1.0, 0.34), 58.0, 0.62)

func _spawn_tide(from: Vector2, to: Vector2) -> void:
	var wave: Polygon2D = Polygon2D.new()
	wave.color = Color(0.26, 0.68, 0.96, 0.72)
	wave.polygon = PackedVector2Array([Vector2(-120, -16), Vector2(120, -16), Vector2(160, 12), Vector2(-160, 12)])
	wave.position = from + Vector2(0, 12)
	_effect_layer.add_child(wave)
	var tween: Tween = _track(create_tween())
	tween.tween_property(wave, "position", to + Vector2(0, 12), 0.48).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.48)
	tween.tween_callback(wave.queue_free)

func _darken_field() -> void:
	if _effect_layer == null: return
	var veil: Polygon2D = Polygon2D.new()
	veil.color = Color(0.04, 0.12, 0.26, 0.0)
	veil.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 540), Vector2(0, 540)])
	_effect_layer.add_child(veil)
	var tween: Tween = _track(create_tween())
	tween.tween_property(veil, "color:a", 0.42, 0.14)
	tween.tween_property(veil, "color:a", 0.0, 0.56)
	tween.tween_callback(veil.queue_free)

func _spawn_disc(pos: Vector2, color: Color, radius: float, duration: float) -> void:
	if _effect_layer == null: return
	var disc: Polygon2D = Polygon2D.new()
	disc.color = color
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(14): points.append(Vector2.RIGHT.rotated(TAU * float(i) / 14.0) * radius)
	disc.polygon = points
	disc.position = pos
	_effect_layer.add_child(disc)
	var tween: Tween = _track(create_tween())
	tween.tween_property(disc, "scale", Vector2(1.65, 1.65), duration)
	tween.parallel().tween_property(disc, "modulate:a", 0.0, duration)
	tween.tween_callback(disc.queue_free)

func _spawn_floating_text(target: BattleActor, result: BattleActionResult) -> void:
	var label: Label = Label.new()
	label.text = "+%d" % result.heal if result.is_heal else str(result.damage)
	label.add_theme_color_override("font_color", Color(0.38, 0.88, 0.45, 1.0) if result.is_heal else Color(1.0, 0.72, 0.30, 1.0))
	label.add_theme_font_size_override("font_size", 32)
	label.position = target.get_viewport().get_canvas_transform() * target.get_damage_number_position() - _floating_text_parent.global_position
	_floating_text_parent.add_child(label)
	var tween: Tween = _track(create_tween())
	tween.tween_property(label, "position:y", label.position.y - 44.0, 0.76)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.76)
	tween.tween_callback(label.queue_free)

func _snap_hp_to_result(result: BattleActionResult) -> void:
	_tween_hp(result)

func _track(tween: Tween) -> Tween:
	_all_tweens.append(tween)
	return tween

func _kill_all_tweens() -> void:
	for tween in _all_tweens:
		if tween != null and tween.is_valid(): tween.kill()
	_all_tweens.clear()

func _play_audio(method_name: StringName) -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(method_name)

func _finish() -> void:
	var defeated_side: String = _active_result.defender_side if _active_result != null and _active_result.defender_defeated else ""
	if _player_actor and defeated_side != "player":
		_player_actor.reset_to_home()
	if _enemy_actor and defeated_side != "enemy":
		_enemy_actor.reset_to_home()
	if _camera:
		_camera.position = _camera_home
	_is_playing = false
	current_state = PresentationState.BATTLE_END if defeated_side != "" else PresentationState.ROUND_RESOLVE
	_active_result = null
	var callback: Callable = _callback
	_callback = Callable()
	if callback.is_valid():
		callback.call()