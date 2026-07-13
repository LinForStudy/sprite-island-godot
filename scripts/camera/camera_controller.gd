extends Camera2D

# Camera policy belongs to the world, not the player prefab. This keeps player
# movement reusable while maps can later add bounds or scripted camera behavior.

@export var target_path: NodePath

var follow_target: Node2D


func _ready() -> void:
	make_current()
	_resolve_follow_target()
	_apply_display_profile(DisplayManager.get_active_profile())
	DisplayManager.profile_changed.connect(_apply_display_profile)


func _exit_tree() -> void:
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)


func _process(_delta: float) -> void:
	if not is_instance_valid(follow_target):
		_resolve_follow_target()
	if is_instance_valid(follow_target):
		global_position = follow_target.global_position


func _resolve_follow_target() -> void:
	follow_target = get_node_or_null(target_path) as Node2D
	if follow_target != null:
		global_position = follow_target.global_position
		return
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		follow_target = players[0] as Node2D
		if follow_target != null:
			global_position = follow_target.global_position

func _apply_display_profile(profile: DeviceProfile) -> void:
	if profile == null:
		zoom = Vector2.ONE
		return
	zoom = profile.camera_zoom
