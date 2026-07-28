extends CharacterBody2D

# The player owns movement, facing and interaction selection.
# Dialogue presentation and camera policy stay in the world scene.

@export var move_speed: float = 90.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
var facing_direction: String = "down"
var nearby_interactables: Array[Area2D] = []

func _ready() -> void:
	add_to_group("player")
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	_update_animation(false)

func _physics_process(_delta: float) -> void:
	if InputRouter.consume_interact():
		if WorldState.dialogue_open:
			_close_world_dialogue()
			return
		if not GameState.is_modal_open():
			_trigger_interaction()

	if WorldState.dialogue_open or GameState.is_modal_open():
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(false)
		WorldState.remember_player_state(global_position, facing_direction)
		return

	var input_vector: Vector2 = InputRouter.get_move_vector()
	if input_vector.length() > 0.0:
		velocity = input_vector.normalized() * move_speed
		_update_facing(input_vector)
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_update_animation(velocity.length() > 0.0)
	WorldState.remember_player_state(global_position, facing_direction)

func get_facing_direction() -> String:
	return facing_direction

func set_facing_direction(new_direction: String) -> void:
	facing_direction = new_direction
	_update_animation(false)

func _update_facing(input_vector: Vector2) -> void:
	if absf(input_vector.x) > absf(input_vector.y):
		facing_direction = "right" if input_vector.x > 0.0 else "left"
	else:
		facing_direction = "down" if input_vector.y > 0.0 else "up"

func _update_animation(is_moving: bool) -> void:
	var prefix: String = "walk_" if is_moving else "idle_"
	var animation_name: StringName = StringName(prefix + facing_direction)
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play(animation_name)

func _trigger_interaction() -> void:
	var candidate: Area2D = _get_closest_interactable()
	if candidate != null and candidate.has_method("interact"):
		candidate.call("interact", self)

func _get_closest_interactable() -> Area2D:
	var closest: Area2D = null
	var best_distance: float = INF
	for candidate in nearby_interactables:
		if not is_instance_valid(candidate):
			continue
		var distance: float = global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			closest = candidate
	return closest

func _close_world_dialogue() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("close_dialogue_panel"):
		current_scene.call("close_dialogue_panel")

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable") and not nearby_interactables.has(area):
		nearby_interactables.append(area)

func _on_interaction_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)