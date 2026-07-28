class_name BattleActor
extends CharacterBody2D

## 可复用战斗实体。正式动画一律按 spirit_id 通过 GameCatalog 加载。
## 静态立绘仅用于资源制作期间的可见回退，并会输出明确的资源契约错误。
signal combat_action_started(action: StringName)

@onready var shadow: Polygon2D = $Shadow
@onready var visual_root: Node2D = $VisualRoot
@onready var spirit_sprite: Sprite2D = $VisualRoot/SpiritSprite
@onready var animated_spirit: AnimatedSprite2D = $VisualRoot/AnimatedSpirit
@onready var cast_point: Marker2D = $VisualRoot/CastPoint
@onready var hit_point: Marker2D = $VisualRoot/HitPoint
@onready var effect_anchor: Marker2D = $VisualRoot/EffectAnchor
@onready var damage_number_anchor: Marker2D = $DamageNumberAnchor
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var target_sprite_height: float = 230.0
var spirit_id: String = ""
var _home_position: Vector2 = Vector2.ZERO
var _facing_sign: float = 1.0
var _resource_issue_reported: bool = false

func _ready() -> void:
	_home_position = global_position
	_apply_anchor_layout()

func set_home_position(home_position: Vector2) -> void:
	_home_position = home_position
	global_position = home_position

func get_home_position() -> Vector2:
	return _home_position

func set_target_height(height: float) -> void:
	target_sprite_height = height
	_apply_actor_scale()
	_apply_animated_scale()
	_apply_anchor_layout()

func set_facing_toward(target: Vector2) -> void:
	_facing_sign = 1.0 if target.x >= global_position.x else -1.0
	visual_root.scale.x = abs(visual_root.scale.x) * _facing_sign

func set_spirit_texture(texture: Texture2D) -> void:
	spirit_sprite.texture = texture
	spirit_sprite.visible = texture != null
	animated_spirit.visible = false
	animated_spirit.sprite_frames = null
	_apply_actor_scale()
	_apply_anchor_layout()

func set_spirit_id(next_spirit_id: String, fallback_texture: Texture2D = null) -> void:
	if spirit_id == next_spirit_id and (animated_spirit.visible or spirit_sprite.texture == fallback_texture):
		return
	spirit_id = next_spirit_id
	_resource_issue_reported = false
	var frames: SpriteFrames = GameCatalog.get_battle_frames(spirit_id)
	if frames != null and not frames.get_animation_names().is_empty():
		animated_spirit.sprite_frames = frames
		animated_spirit.visible = true
		spirit_sprite.visible = false
		var initial_action: StringName = &"idle" if frames.has_animation(&"idle") else frames.get_animation_names()[0]
		animated_spirit.animation = initial_action
		animated_spirit.play(initial_action)
		_apply_animated_scale()
		_report_frame_contract_issues()
	else:
		set_spirit_texture(fallback_texture)
		_report_missing_frames()
	_apply_anchor_layout()

func play_combat_action(action: StringName) -> void:
	var resolved_action: StringName = _resolve_action(action)
	if animated_spirit.visible and animated_spirit.sprite_frames != null and resolved_action != &"":
		animated_spirit.play(resolved_action)
	combat_action_started.emit(action)

func has_combat_action(action: StringName) -> bool:
	return _resolve_action(action) != &""

func is_using_animated_frames() -> bool:
	return animated_spirit.visible and animated_spirit.sprite_frames != null

func reset_to_home(reset_animation: bool = true) -> void:
	global_position = _home_position
	visual_root.position = Vector2.ZERO
	visual_root.modulate = Color.WHITE
	visual_root.rotation = 0.0
	visual_root.scale = Vector2(_facing_sign, 1.0)
	shadow.scale = Vector2.ONE
	shadow.modulate = Color.WHITE
	if reset_animation:
		play_combat_action(&"idle")

func get_cast_position() -> Vector2:
	return cast_point.global_position

func get_hit_position() -> Vector2:
	return hit_point.global_position

func get_effect_position() -> Vector2:
	return effect_anchor.global_position

func get_damage_number_position() -> Vector2:
	return damage_number_anchor.global_position

func _resolve_action(action: StringName) -> StringName:
	if not animated_spirit.visible or animated_spirit.sprite_frames == null:
		return &""
	if animated_spirit.sprite_frames.has_animation(action):
		return action
	if action == &"defeat" and animated_spirit.sprite_frames.has_animation(&"exit"):
		return &"exit"
	if action == &"exit" and animated_spirit.sprite_frames.has_animation(&"defeat"):
		return &"defeat"
	return &""

func _report_frame_contract_issues() -> void:
	if _resource_issue_reported:
		return
	var issues: PackedStringArray = GameCatalog.get_battle_frame_issues(spirit_id)
	if issues.is_empty():
		return
	_resource_issue_reported = true
	push_error("%s 的战斗动画未满足资源契约：%s" % [spirit_id, "；".join(issues)])

func _report_missing_frames() -> void:
	if _resource_issue_reported or spirit_id == "":
		return
	_resource_issue_reported = true
	var expected_path: String = GameCatalog.get_battle_frame_paths(spirit_id)[0]
	push_error("%s 缺少战斗 SpriteFrames（需要 idle4/move4/attack4/hurt2/defeat4）：%s" % [spirit_id, expected_path])

func _apply_actor_scale() -> void:
	if spirit_sprite.texture == null:
		return
	var tex_size: Vector2 = spirit_sprite.texture.get_size()
	if tex_size.y <= 0.0:
		return
	var scale_factor: float = target_sprite_height / tex_size.y
	spirit_sprite.scale = Vector2(scale_factor, scale_factor)
	spirit_sprite.position = Vector2(0.0, -target_sprite_height * 0.5)

func _apply_animated_scale() -> void:
	if animated_spirit.sprite_frames == null:
		return
	var animation_name: StringName = &"idle" if animated_spirit.sprite_frames.has_animation(&"idle") else animated_spirit.animation
	if not animated_spirit.sprite_frames.has_animation(animation_name) or animated_spirit.sprite_frames.get_frame_count(animation_name) <= 0:
		return
	var frame_texture: Texture2D = animated_spirit.sprite_frames.get_frame_texture(animation_name, 0)
	if frame_texture == null or frame_texture.get_height() <= 0:
		return
	var scale_factor: float = target_sprite_height / float(frame_texture.get_height())
	animated_spirit.scale = Vector2(scale_factor, scale_factor)
	animated_spirit.position = Vector2(0.0, -target_sprite_height * 0.5)

func _apply_anchor_layout() -> void:
	var height: float = target_sprite_height
	cast_point.position = Vector2(42.0, -height * 0.48)
	hit_point.position = Vector2(0.0, -height * 0.48)
	effect_anchor.position = Vector2(0.0, -height * 0.68)
	damage_number_anchor.position = Vector2(0.0, -height * 0.94)
	var half_width: float = max(54.0, height * 0.32)
	shadow.polygon = PackedVector2Array([Vector2(-half_width, -10.0), Vector2(-half_width * 0.74, -22.0), Vector2(0.0, -29.0), Vector2(half_width * 0.74, -22.0), Vector2(half_width, -10.0), Vector2(half_width * 0.74, 3.0), Vector2(0.0, 10.0), Vector2(-half_width * 0.74, 3.0)])