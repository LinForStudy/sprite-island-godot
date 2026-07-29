extends Node2D

# Runtime world assembly reads editable visual and collision data from JSON.
# Scenes keep only the visual TileMap layers, interactive regions and dynamic entities.

const VISUAL_SOURCE_GRASS_1 := 0
const VISUAL_SOURCE_GRASS_2 := 1
const VISUAL_SOURCE_GRASS_3 := 2
const VISUAL_SOURCE_PLAZA := 3
const VISUAL_SOURCE_ROAD := 4
const VISUAL_SOURCE_GRASSLAND_1 := 5
const VISUAL_SOURCE_GRASSLAND_2 := 6
const VISUAL_SOURCE_TALL_GRASS := 7
const VISUAL_SOURCE_GRASS_EDGE := 8
const VISUAL_SOURCE_WATER := 9
const VISUAL_SOURCE_WARM_SOIL := 10
const VISUAL_TILE := Vector2i(0, 0)
const HABITAT_POINT_SCENE := preload("res://scenes/world/habitat_point.tscn")
const WORLD_VISUAL_LAYOUTS_PATH := "res://data/maps/world_visual_layouts.json"
const VISUAL_SOURCE_BY_NAME: Dictionary = {
	"grass_1": VISUAL_SOURCE_GRASS_1,
	"grass_2": VISUAL_SOURCE_GRASS_2,
	"grass_3": VISUAL_SOURCE_GRASS_3,
	"plaza": VISUAL_SOURCE_PLAZA,
	"road": VISUAL_SOURCE_ROAD,
	"grassland_1": VISUAL_SOURCE_GRASSLAND_1,
	"grassland_2": VISUAL_SOURCE_GRASSLAND_2,
	"tall_grass": VISUAL_SOURCE_TALL_GRASS,
	"grass_edge": VISUAL_SOURCE_GRASS_EDGE,
	"water": VISUAL_SOURCE_WATER,
	"warm_soil": VISUAL_SOURCE_WARM_SOIL
}

@export var scene_id: String = ""
@export var map_preset: String = "test_world"
@export var default_spawn_id: String = "entry_default"

@onready var visual_ground_layer: TileMapLayer = get_node_or_null("VisualGroundLayer") as TileMapLayer
@onready var visual_path_layer: TileMapLayer = get_node_or_null("PathLayer") as TileMapLayer
@onready var visual_detail_layer: TileMapLayer = get_node_or_null("GroundDetailLayer") as TileMapLayer
@onready var collision_geometry: Node2D = $CollisionGeometry
@onready var habitat_points_root: Node2D = $HabitatPoints
@onready var spawn_points: Node2D = $SpawnPoints
@onready var player: Node = get_node_or_null("YSortEntities/Player") if get_node_or_null("YSortEntities/Player") != null else get_node_or_null("Player")
@onready var camera_controller: Camera2D = $CameraController
@onready var dialogue_ui: Node = $DialogueUI
@onready var gameplay_ui: Node = $GameplayUI

var map_size: Vector2i = Vector2i(96, 54)
var interaction_prompt_candidates: Array[Area2D] = []

func _ready() -> void:
	WorldState.register_scene(scene_id)
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call("play_world_music", scene_id)
	_build_map()
	_build_visual_blockers()
	_hide_helper_layers()
	_spawn_habitat_points()
	_place_player()
	_bind_world_interaction_prompt()
	_sync_camera_limits()
	_validate_scene_setup()

func toggle_dialogue_panel(speaker: String, text: String) -> void:
	dialogue_ui.call("toggle_dialogue", speaker, text)

func close_dialogue_panel() -> void:
	dialogue_ui.call("hide_dialogue")

func open_habitat_panel(habitat_id: String) -> void:
	if WorldState.dialogue_open:
		close_dialogue_panel()
	GameState.open_habitat_panel(habitat_id)

func _build_map() -> void:
	_clear_layers()
	match map_preset:
		"grove_gate":
			_build_grove_gate()
		_:
			_build_test_world()

func _clear_layers() -> void:
	if visual_ground_layer != null:
		visual_ground_layer.clear()
	if visual_path_layer != null:
		visual_path_layer.clear()
	if visual_detail_layer != null:
		visual_detail_layer.clear()
	for child in collision_geometry.get_children():
		child.queue_free()
func _build_visual_blockers() -> void:
	var layouts: Dictionary = _read_world_visual_layouts()
	var layout: Dictionary = Dictionary(layouts.get(map_preset, {}))
	for cell_value in Array(layout.get("collision_cells", [])):
		_add_collision_cell(_vector2i_from_array(Array(cell_value)))
	for blocker_value in Array(layout.get("collision_blockers", [])):
		var blocker: Dictionary = Dictionary(blocker_value)
		_add_visual_blocker(_vector2_from_array(Array(blocker.get("center", []))), _vector2_from_array(Array(blocker.get("size", []))), String(blocker.get("name", "MapBlocker")))

func _add_collision_cell(cell: Vector2i) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(16.0, 16.0)
	shape.shape = rectangle
	body.position = Vector2(cell.x * 16 + 8, cell.y * 16 + 8)
	body.collision_layer = 2
	body.collision_mask = 0
	body.add_child(shape)
	collision_geometry.add_child(body)

func _add_visual_blocker(center: Vector2, size: Vector2, blocker_name: String) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	body.name = blocker_name
	body.position = center
	body.collision_layer = 2
	body.collision_mask = 0
	body.add_child(shape)
	collision_geometry.add_child(body)
func _hide_helper_layers() -> void:
	# Legacy phase-one layers remain in the scenes for backward-compatible edits,
	# but visual and collision data are now supplied by world_visual_layouts.json.
	for layer_name in ["GroundLayer", "DecorationLayer", "CollisionLayer", "TallGrassLayer", "ForegroundLayer"]:
		var layer: TileMapLayer = get_node_or_null(layer_name) as TileMapLayer
		if layer != null:
			layer.visible = false
func _build_test_world() -> void:
	map_size = _map_size_from_layout("test_world")
	_build_visual_layout("test_world")
func _build_visual_layout(layout_id: String) -> void:
	if visual_ground_layer == null or visual_path_layer == null or visual_detail_layer == null:
		return
	var layouts: Dictionary = _read_world_visual_layouts()
	var layout: Dictionary = Dictionary(layouts.get(layout_id, {}))
	if layout.is_empty():
		push_warning("Missing world visual layout: %s" % layout_id)
		return
	var visual_size: Array = Array(layout.get("visual_size", [24, 14]))
	var width: int = int(visual_size[0]) if visual_size.size() > 0 else 24
	var height: int = int(visual_size[1]) if visual_size.size() > 1 else 14
	var ground_source: int = _visual_source_id(String(layout.get("ground_source", "grass_1")))
	for x in range(width):
		for y in range(height):
			_set_visual_ground_tile(Vector2i(x, y), ground_source)
	for variant_value in Array(layout.get("ground_variants", [])):
		var variant: Dictionary = Dictionary(variant_value)
		var variant_source: int = _visual_source_id(String(variant.get("source", "grass_2")))
		for cell_value in Array(variant.get("cells", [])):
			_set_visual_ground_tile(_vector2i_from_array(Array(cell_value)), variant_source)
	for rect_value in Array(layout.get("rects", [])):
		var rect_entry: Dictionary = Dictionary(rect_value)
		var rect_values: Array = Array(rect_entry.get("rect", []))
		if rect_values.size() < 4:
			continue
		var rect: Rect2i = Rect2i(int(rect_values[0]), int(rect_values[1]), int(rect_values[2]), int(rect_values[3]))
		_fill_visual_rect(rect, _visual_source_id(String(rect_entry.get("source", "road"))))
	for detail_value in Array(layout.get("details", [])):
		var detail: Dictionary = Dictionary(detail_value)
		var detail_source: int = _visual_source_id(String(detail.get("source", "grass_edge")))
		for cell_value in Array(detail.get("cells", [])):
			_set_visual_tile(_vector2i_from_array(Array(cell_value)), detail_source)


func _map_size_from_layout(layout_id: String) -> Vector2i:
	var layouts: Dictionary = _read_world_visual_layouts()
	var layout: Dictionary = Dictionary(layouts.get(layout_id, {}))
	return _vector2i_from_array(Array(layout.get("map_size", [96, 54])))

func _read_world_visual_layouts() -> Dictionary:
	if not FileAccess.file_exists(WORLD_VISUAL_LAYOUTS_PATH):
		return {}
	var file: FileAccess = FileAccess.open(WORLD_VISUAL_LAYOUTS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _visual_source_id(source_name: String) -> int:
	return int(VISUAL_SOURCE_BY_NAME.get(source_name, VISUAL_SOURCE_GRASS_1))


func _vector2_from_array(values: Array) -> Vector2:
	return Vector2(float(values[0]), float(values[1])) if values.size() >= 2 else Vector2.ZERO

func _vector2i_from_array(values: Array) -> Vector2i:
	return Vector2i(int(values[0]), int(values[1])) if values.size() >= 2 else Vector2i.ZERO

func _set_visual_ground_tile(cell: Vector2i, source_id: int) -> void:
	if visual_ground_layer == null:
		return
	visual_ground_layer.set_cell(cell, source_id, VISUAL_TILE, 0)

func _set_visual_tile(cell: Vector2i, source_id: int) -> void:
	if visual_detail_layer == null:
		return
	visual_detail_layer.set_cell(cell, source_id, VISUAL_TILE, 0)

func _fill_visual_rect(rect: Rect2i, source_id: int) -> void:
	if visual_path_layer == null:
		return
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			visual_path_layer.set_cell(Vector2i(x, y), source_id, VISUAL_TILE, 0)

func _build_grove_gate() -> void:
	map_size = _map_size_from_layout("grove_gate")
	_build_visual_layout("grove_gate")
func _spawn_habitat_points() -> void:
	for child in habitat_points_root.get_children():
		child.queue_free()
	var point_configs: Array[Dictionary] = []
	match map_preset:
		"grove_gate":
			point_configs = [
				{"habitat_id": "windmill", "display_name": "风车", "position": Vector2(560, 728)},
				{"habitat_id": "cave", "display_name": "山洞", "position": Vector2(272, 272)},
				{"habitat_id": "cloud", "display_name": "云台", "position": Vector2(1152, 208)}
			]
		_:
			point_configs = [
				{"habitat_id": "grassland", "display_name": "草丛", "position": Vector2(392, 264)},
				{"habitat_id": "pond", "display_name": "池塘", "position": Vector2(312, 552)},
				{"habitat_id": "warmstone", "display_name": "暖石", "position": Vector2(1184, 296)}
			]
	for config in point_configs:
		var point: Area2D = HABITAT_POINT_SCENE.instantiate() as Area2D
		point.set("habitat_id", String(config.get("habitat_id", "")))
		point.set("display_name", String(config.get("display_name", "")))
		point.position = config.get("position", Vector2.ZERO) as Vector2
		habitat_points_root.add_child(point)

func _place_player() -> void:
	var spawn_id: String = WorldState.consume_spawn_id(default_spawn_id)
	var marker: Node = spawn_points.get_node_or_null(spawn_id)
	if marker == null:
		marker = spawn_points.get_node_or_null(default_spawn_id)
	if marker is Marker2D and player is Node2D:
		(player as Node2D).global_position = marker.global_position
	player.call("set_facing_direction", WorldState.last_player_facing)
	var player_position: Vector2 = (player as Node2D).global_position
	camera_controller.global_position = player_position
	var facing: String = str(player.call("get_facing_direction"))
	WorldState.remember_player_state(player_position, facing)

func _bind_world_interaction_prompt() -> void:
	var interaction_area: Area2D = player.get_node_or_null("InteractionArea") as Area2D
	if interaction_area == null:
		return
	if not interaction_area.area_entered.is_connected(_on_prompt_area_entered):
		interaction_area.area_entered.connect(_on_prompt_area_entered)
	if not interaction_area.area_exited.is_connected(_on_prompt_area_exited):
		interaction_area.area_exited.connect(_on_prompt_area_exited)
	if not GameState.ui_state_changed.is_connected(_on_world_ui_state_changed):
		GameState.ui_state_changed.connect(_on_world_ui_state_changed)
	for area in interaction_area.get_overlapping_areas():
		_on_prompt_area_entered(area)
	_refresh_world_interaction_prompt()

func _on_prompt_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable") and not interaction_prompt_candidates.has(area):
		interaction_prompt_candidates.append(area)
	_refresh_world_interaction_prompt()

func _on_prompt_area_exited(area: Area2D) -> void:
	interaction_prompt_candidates.erase(area)
	_refresh_world_interaction_prompt()

func _on_world_ui_state_changed(_panel: String) -> void:
	_refresh_world_interaction_prompt()

func _refresh_world_interaction_prompt() -> void:
	if gameplay_ui == null or not gameplay_ui.has_method("hide_interaction_prompt"):
		return
	for index in range(interaction_prompt_candidates.size() - 1, -1, -1):
		if not is_instance_valid(interaction_prompt_candidates[index]):
			interaction_prompt_candidates.remove_at(index)
	if GameState.current_panel != "hud" or interaction_prompt_candidates.is_empty():
		gameplay_ui.call("hide_interaction_prompt")
		return
	var closest: Area2D = null
	var best_distance: float = INF
	for candidate in interaction_prompt_candidates:
		var distance: float = (player as Node2D).global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			closest = candidate
	if closest != null and gameplay_ui.has_method("show_interaction_prompt"):
		gameplay_ui.call("show_interaction_prompt", _interaction_prompt_text(closest))

func _interaction_prompt_text(area: Area2D) -> String:
	var script_path: String = area.get_script().resource_path if area.get_script() != null else ""
	if script_path.ends_with("habitat_point.gd"):
		return "开始探索"
	if script_path.ends_with("home_entry.gd"):
		return "进入小屋"
	if script_path.ends_with("starter_guide.gd"):
		return "与向导交谈"
	if script_path.ends_with("TestNpc.gd"):
		return "与村民交谈"
	return "互动"

func _sync_camera_limits() -> void:
	var limit_right: int = map_size.x * 16
	var limit_bottom: int = map_size.y * 16
	camera_controller.limit_left = 0
	camera_controller.limit_top = 0
	camera_controller.limit_right = limit_right
	camera_controller.limit_bottom = limit_bottom

func _validate_scene_setup() -> void:
	assert(visual_ground_layer != null)
	assert(visual_path_layer != null)
	assert(visual_detail_layer != null)
	assert(collision_geometry != null)
	assert(player != null)
	assert(dialogue_ui != null)
	assert(gameplay_ui != null)