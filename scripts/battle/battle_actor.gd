class_name BattleActor
extends CharacterBody2D

## Reusable battle entity. AnimatedSprite2D is reserved for future SpriteFrames;
## the static art fallback receives the same temporary tween-based performance.
const LEAFBUN_FRAMES := preload("res://resources/battle/leafbun_combat_frames.tres")
const TARGET_SPRITE_WIDTH: float = 240.0

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
var _home_position: Vector2 = Vector2.ZERO
var _facing_sign: float = 1.0

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
	_apply_anchor_layout()

func set_facing_toward(target: Vector2) -> void:
	_facing_sign = 1.0 if target.x >= global_position.x else -1.0
	visual_root.scale.x = abs(visual_root.scale.x) * _facing_sign

func set_spirit_texture(texture: Texture2D) -> void:
	spirit_sprite.texture = texture
	spirit_sprite.visible = true
	animated_spirit.visible = false
	_apply_actor_scale()
	_apply_anchor_layout()

func set_spirit_id(spirit_id: String, fallback_texture: Texture2D) -> void:
	if spirit_id == "leafbun":
		animated_spirit.sprite_frames = LEAFBUN_FRAMES
		animated_spirit.animation = &"idle"
		animated_spirit.play()
		animated_spirit.visible = true
		spirit_sprite.visible = false
		_apply_animated_scale()
	else:
		set_spirit_texture(fallback_texture)

func play_combat_action(action: StringName) -> void:
	if animated_spirit.visible and animated_spirit.sprite_frames.has_animation(action):
		animated_spirit.play(action)
	# Static sprites are intentionally animated by BattlePresentation tweens.

func reset_to_home() -> void:
	global_position = _home_position
	visual_root.position = Vector2.ZERO
	visual_root.modulate = Color.WHITE
	visual_root.rotation = 0.0
	visual_root.scale = Vector2(_facing_sign, 1.0)
	shadow.scale = Vector2.ONE

func get_cast_position() -> Vector2:
	return cast_point.global_position

func get_hit_position() -> Vector2:
	return hit_point.global_position

func get_effect_position() -> Vector2:
	return effect_anchor.global_position

func get_damage_number_position() -> Vector2:
	return damage_number_anchor.global_position

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
	var frame_texture: Texture2D = animated_spirit.sprite_frames.get_frame_texture(&"idle", 0)
	if frame_texture == null:
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