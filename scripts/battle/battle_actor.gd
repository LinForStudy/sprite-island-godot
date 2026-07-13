class_name BattleActor
extends Node2D

## Reusable Node2D battle actor. The actor origin is the foot/home point.
## BattlePresentation moves this node in world coordinates and always returns it home.

@onready var shadow: Polygon2D = $Shadow
@onready var visual_root: Node2D = $VisualRoot
@onready var spirit_sprite: Sprite2D = $VisualRoot/SpiritSprite
@onready var cast_point: Marker2D = $VisualRoot/CastPoint
@onready var hit_point: Marker2D = $VisualRoot/HitPoint
@onready var effect_anchor: Marker2D = $VisualRoot/EffectAnchor
@onready var floating_text_anchor: Marker2D = $FloatingTextAnchor
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const TARGET_SPRITE_WIDTH: float = 240.0

var target_sprite_height: float = 230.0
var _home_position: Vector2 = Vector2.ZERO

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

func set_spirit_texture(texture: Texture2D) -> void:
	spirit_sprite.texture = texture
	_apply_actor_scale()
	_apply_anchor_layout()

func reset_to_home() -> void:
	global_position = _home_position
	visual_root.position = Vector2.ZERO
	visual_root.modulate = Color.WHITE
	visual_root.rotation = 0.0
	if spirit_sprite != null:
		spirit_sprite.modulate = Color.WHITE
		spirit_sprite.rotation = 0.0

func get_cast_position() -> Vector2:
	return cast_point.global_position

func get_hit_position() -> Vector2:
	return hit_point.global_position

func get_floating_text_position() -> Vector2:
	return floating_text_anchor.global_position

func _apply_actor_scale() -> void:
	if spirit_sprite == null or spirit_sprite.texture == null:
		return
	var tex_size: Vector2 = spirit_sprite.texture.get_size()
	if tex_size.y <= 0.0:
		return
	var scale_factor: float = target_sprite_height / tex_size.y
	spirit_sprite.scale = Vector2(scale_factor, scale_factor)
	spirit_sprite.position = Vector2(0.0, -target_sprite_height * 0.5)

func _apply_anchor_layout() -> void:
	if spirit_sprite == null:
		return
	var height: float = target_sprite_height
	cast_point.position = Vector2(42.0, -height * 0.48)
	hit_point.position = Vector2(0.0, -height * 0.48)
	effect_anchor.position = Vector2(0.0, -height * 0.68)
	floating_text_anchor.position = Vector2(0.0, -height * 0.94)
	if shadow != null:
		var half_width: float = max(54.0, height * 0.32)
		shadow.polygon = PackedVector2Array([
			Vector2(-half_width, -10.0), Vector2(-half_width * 0.74, -22.0),
			Vector2(0.0, -29.0), Vector2(half_width * 0.74, -22.0),
			Vector2(half_width, -10.0), Vector2(half_width * 0.74, 3.0),
			Vector2(0.0, 10.0), Vector2(-half_width * 0.74, 3.0)
		])