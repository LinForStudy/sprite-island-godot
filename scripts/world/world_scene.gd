extends Node2D

# This script builds small placeholder maps directly into TileMapLayer nodes.
# The map data stays in code for phase one so the project can run without editor-authored tile painting.

const TILE_SOURCE_ID := 0
const VISUAL_SOURCE_GRASS_1 = 0
const VISUAL_SOURCE_GRASS_2 = 1
const VISUAL_SOURCE_GRASS_3 = 2
const VISUAL_SOURCE_PLAZA = 3
const VISUAL_SOURCE_ROAD = 4
const VISUAL_SOURCE_GRASSLAND_1 = 5
const VISUAL_SOURCE_GRASSLAND_2 = 6
const VISUAL_SOURCE_TALL_GRASS = 7
const VISUAL_SOURCE_GRASS_EDGE = 8
const VISUAL_SOURCE_WATER = 9
const VISUAL_SOURCE_WARM_SOIL = 10
const VISUAL_TILE := Vector2i(0, 0)
const TILE_GRASS := Vector2i(0, 0)
const TILE_ROAD := Vector2i(1, 0)
const TILE_WATER := Vector2i(2, 0)
const TILE_TALL_GRASS := Vector2i(3, 0)
const TILE_FENCE := Vector2i(0, 1)
const TILE_TREE_TRUNK := Vector2i(1, 1)
const TILE_WALL := Vector2i(2, 1)
const TILE_ROOF := Vector2i(3, 1)
const TILE_FLOWER := Vector2i(0, 2)
const TILE_STONE := Vector2i(1, 2)
const TILE_DOOR := Vector2i(2, 2)
const TILE_CANOPY := Vector2i(3, 2)
const TILE_SOIL := Vector2i(0, 3)
const TILE_SIGN := Vector2i(1, 3)
const TILE_BUSH := Vector2i(2, 3)
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
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var decoration_layer: TileMapLayer = $DecorationLayer
@onready var collision_layer: TileMapLayer = $CollisionLayer
@onready var tall_grass_layer: TileMapLayer = $TallGrassLayer
@onready var foreground_layer: TileMapLayer = $ForegroundLayer
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
	ground_layer.clear()
	decoration_layer.clear()
	collision_layer.clear()
	tall_grass_layer.clear()
	foreground_layer.clear()
	for child in collision_geometry.get_children():
		child.queue_free()

func _build_visual_blockers() -> void:
	# Runtime collision stays separate from the visual TileMap and prop scenes.
	match map_preset:
		"grove_gate":
			_add_visual_blocker(Vector2(176, 162), Vector2(42, 24), "GroveTreeNorthWest")
			_add_visual_blocker(Vector2(520, 132), Vector2(46, 26), "GroveTreeNorthCenter")
			_add_visual_blocker(Vector2(1370, 140), Vector2(42, 24), "GroveTreeNorthEast")
			_add_visual_blocker(Vector2(126, 504), Vector2(42, 24), "GroveTreeWest")
			_add_visual_blocker(Vector2(1402, 482), Vector2(44, 26), "GroveTreeEast")
			_add_visual_blocker(Vector2(238, 790), Vector2(40, 22), "GroveTreeSouthWest")
			_add_visual_blocker(Vector2(1308, 772), Vector2(40, 22), "GroveTreeSouthEast")
			_add_visual_blocker(Vector2(268, 262), Vector2(86, 54), "CaveRockBlocker")
		_:
			_add_visual_blocker(Vector2(500, 402), Vector2(42, 24), "PlazaTreeWestBlocker")
			_add_visual_blocker(Vector2(1020, 416), Vector2(42, 24), "PlazaTreeEastBlocker")
			_add_visual_blocker(Vector2(356, 652), Vector2(38, 22), "PondTreeBlocker")
			_add_visual_blocker(Vector2(1326, 142), Vector2(40, 24), "WarmTreeBlocker")
			_add_visual_blocker(Vector2(210, 676), Vector2(38, 22), "HomeTreeBlocker")
			_add_visual_blocker(Vector2(590, 476), Vector2(34, 20), "PlazaStoneWestBlocker")
			_add_visual_blocker(Vector2(1080, 486), Vector2(32, 20), "PlazaStoneEastBlocker")
			_add_visual_blocker(Vector2(1168, 278), Vector2(56, 38), "WarmStoneMainBlocker")
			_add_visual_blocker(Vector2(1260, 234), Vector2(42, 30), "WarmStoneSideBlocker")
			_add_visual_blocker(Vector2(238, 586), Vector2(140, 82), "PondWaterBlocker")
			_add_visual_blocker(Vector2(268, 730), Vector2(70, 12), "HomeFenceWestBlocker")
			_add_visual_blocker(Vector2(452, 730), Vector2(70, 12), "HomeFenceEastBlocker")

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
	# All TileMapLayers using world_tiles.tres render placeholder coloured
	# squares.  Collision is handled by StaticBody2D nodes created in
	# CollisionGeometry, so hiding these layers does not affect collision,
	# navigation or interaction.
	# VisualGroundLayer (wind_plaza_tiles.tres) is the formal art layer and
	# is intentionally left visible.
	if collision_layer != null:
		collision_layer.visible = false
	if ground_layer != null:
		ground_layer.visible = false
	if decoration_layer != null:
		decoration_layer.visible = false
	if tall_grass_layer != null:
		tall_grass_layer.visible = false
	if foreground_layer != null:
		foreground_layer.visible = false

func _build_test_world() -> void:
	map_size = Vector2i(96, 54)
	_build_wind_plaza_visual_ground()
	_fill_rect(ground_layer, Rect2i(0, 0, map_size.x, map_size.y), TILE_GRASS)

	# Center plaza: welcoming open space instead of the old hard cross-road.
	_fill_rect(ground_layer, Rect2i(41, 22, 12, 8), TILE_ROAD)
	_fill_rect(decoration_layer, Rect2i(44, 24, 6, 3), TILE_SOIL)
	_paint_cells(decoration_layer, [Vector2i(43, 23), Vector2i(50, 23), Vector2i(45, 28), Vector2i(49, 28)], TILE_FLOWER)
	_paint_cells(decoration_layer, [Vector2i(46, 25), Vector2i(47, 25)], TILE_STONE)

	# Curved paths leading to each key area.
	_fill_rect(ground_layer, Rect2i(36, 23, 5, 2), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(34, 18, 2, 5), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(30, 16, 4, 2), TILE_ROAD)

	_fill_rect(ground_layer, Rect2i(33, 28, 8, 2), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(28, 30, 2, 8), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(20, 36, 8, 2), TILE_ROAD)

	_fill_rect(ground_layer, Rect2i(53, 23, 8, 2), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(60, 19, 2, 5), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(62, 17, 7, 2), TILE_ROAD)

	_fill_rect(ground_layer, Rect2i(45, 30, 3, 7), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(34, 36, 11, 2), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(32, 38, 2, 8), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(22, 44, 10, 2), TILE_ROAD)

	_fill_rect(ground_layer, Rect2i(52, 27, 10, 2), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(61, 29, 2, 8), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(63, 35, 9, 2), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(71, 37, 2, 7), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(72, 42, 15, 2), TILE_ROAD)

	# Grassland exploration area: upper-left, nested away from the main road.
	_fill_rect(tall_grass_layer, Rect2i(16, 10, 11, 7), TILE_TALL_GRASS)
	_fill_rect(tall_grass_layer, Rect2i(23, 12, 8, 6), TILE_TALL_GRASS)
	_fill_rect(tall_grass_layer, Rect2i(14, 17, 6, 5), TILE_TALL_GRASS)
	_paint_cells(decoration_layer, [Vector2i(18, 9), Vector2i(24, 9), Vector2i(21, 18), Vector2i(27, 18)], TILE_FLOWER)
	_paint_cells(decoration_layer, [Vector2i(15, 14), Vector2i(28, 15), Vector2i(23, 20)], TILE_STONE)
	_paint_cells(collision_layer, [Vector2i(12, 11), Vector2i(31, 14), Vector2i(29, 20)], TILE_BUSH)

	# Pond exploration area: irregular water body on the left / left-bottom.
	_fill_rect(ground_layer, Rect2i(8, 31, 10, 6), TILE_WATER)
	_fill_rect(ground_layer, Rect2i(13, 28, 7, 5), TILE_WATER)
	_fill_rect(ground_layer, Rect2i(18, 33, 4, 4), TILE_WATER)
	_fill_rect(ground_layer, Rect2i(9, 37, 7, 3), TILE_WATER)
	_paint_cells(ground_layer, [Vector2i(19, 31), Vector2i(20, 32), Vector2i(21, 34), Vector2i(17, 39)], TILE_WATER)
	_paint_collision_only_cells([Vector2i(8, 31), Vector2i(9, 31), Vector2i(10, 31), Vector2i(11, 31), Vector2i(12, 31), Vector2i(13, 31), Vector2i(14, 31), Vector2i(15, 31), Vector2i(16, 31), Vector2i(17, 31), Vector2i(13, 28), Vector2i(14, 28), Vector2i(15, 28), Vector2i(16, 28), Vector2i(17, 28), Vector2i(18, 28), Vector2i(19, 28), Vector2i(8, 32), Vector2i(9, 32), Vector2i(10, 32), Vector2i(11, 32), Vector2i(12, 32), Vector2i(13, 32), Vector2i(14, 32), Vector2i(15, 32), Vector2i(16, 32), Vector2i(17, 32), Vector2i(18, 32), Vector2i(19, 32), Vector2i(8, 33), Vector2i(9, 33), Vector2i(10, 33), Vector2i(11, 33), Vector2i(12, 33), Vector2i(13, 33), Vector2i(14, 33), Vector2i(15, 33), Vector2i(16, 33), Vector2i(17, 33), Vector2i(18, 33), Vector2i(19, 33), Vector2i(20, 33), Vector2i(21, 33), Vector2i(8, 34), Vector2i(9, 34), Vector2i(10, 34), Vector2i(11, 34), Vector2i(12, 34), Vector2i(13, 34), Vector2i(14, 34), Vector2i(15, 34), Vector2i(16, 34), Vector2i(17, 34), Vector2i(18, 34), Vector2i(19, 34), Vector2i(20, 34), Vector2i(21, 34), Vector2i(8, 35), Vector2i(9, 35), Vector2i(10, 35), Vector2i(11, 35), Vector2i(12, 35), Vector2i(13, 35), Vector2i(14, 35), Vector2i(15, 35), Vector2i(16, 35), Vector2i(17, 35), Vector2i(18, 35), Vector2i(19, 35), Vector2i(20, 35), Vector2i(21, 35), Vector2i(8, 36), Vector2i(9, 36), Vector2i(10, 36), Vector2i(11, 36), Vector2i(12, 36), Vector2i(13, 36), Vector2i(14, 36), Vector2i(15, 36), Vector2i(16, 36), Vector2i(17, 36), Vector2i(18, 36), Vector2i(19, 36), Vector2i(20, 36), Vector2i(21, 36), Vector2i(9, 37), Vector2i(10, 37), Vector2i(11, 37), Vector2i(12, 37), Vector2i(13, 37), Vector2i(14, 37), Vector2i(15, 37), Vector2i(9, 38), Vector2i(10, 38), Vector2i(11, 38), Vector2i(12, 38), Vector2i(13, 38), Vector2i(14, 38), Vector2i(15, 38), Vector2i(9, 39), Vector2i(10, 39), Vector2i(11, 39), Vector2i(12, 39), Vector2i(13, 39), Vector2i(14, 39), Vector2i(15, 39), Vector2i(19, 31), Vector2i(20, 32), Vector2i(17, 39)], TILE_WATER)
	_fill_rect(tall_grass_layer, Rect2i(6, 29, 3, 5), TILE_TALL_GRASS)
	_fill_rect(tall_grass_layer, Rect2i(21, 30, 3, 4), TILE_TALL_GRASS)
	_paint_cells(decoration_layer, [Vector2i(7, 37), Vector2i(18, 27), Vector2i(22, 36)], TILE_STONE)
	_paint_cells(decoration_layer, [Vector2i(19, 30), Vector2i(18, 38), Vector2i(12, 28)], TILE_FLOWER)

	# Warm stone exploration area: upper-right with warm soil and stone clusters.
	_fill_rect(decoration_layer, Rect2i(68, 12, 10, 6), TILE_SOIL)
	_fill_rect(decoration_layer, Rect2i(73, 16, 7, 5), TILE_SOIL)
	_fill_rect(decoration_layer, Rect2i(66, 18, 7, 4), TILE_SOIL)
	_paint_cells(decoration_layer, [Vector2i(72, 15), Vector2i(74, 14), Vector2i(76, 18), Vector2i(69, 19), Vector2i(78, 20)], TILE_STONE)
	_paint_cells(decoration_layer, [Vector2i(67, 12), Vector2i(79, 17), Vector2i(71, 21)], TILE_FLOWER)
	_paint_cells(collision_layer, [Vector2i(80, 15), Vector2i(81, 18), Vector2i(64, 21)], TILE_BUSH)

	# Home area in the lower-left with a fenced yard and path to the door.
	_build_house(Rect2i(18, 40, 8, 6), Rect2i(16, 37, 12, 3), Vector2i(22, 45))
	_fill_rect(decoration_layer, Rect2i(13, 45, 4, 3), TILE_SOIL)
	_fill_rect(decoration_layer, Rect2i(27, 45, 4, 3), TILE_SOIL)
	_paint_cells(decoration_layer, [Vector2i(14, 45), Vector2i(15, 46), Vector2i(28, 45), Vector2i(29, 46)], TILE_FLOWER)
	_paint_cells(decoration_layer, [Vector2i(30, 44), Vector2i(29, 43)], TILE_STONE)
	_paint_cells(decoration_layer, [Vector2i(25, 44)], TILE_SIGN)
	_build_fence_row(12, 44, 5)
	_build_fence_row(27, 44, 5)
	_build_fence_column(12, 45, 4)
	_build_fence_column(31, 45, 4)

	# Exit lane to grove_gate on the right-bottom.
	_paint_cells(decoration_layer, [Vector2i(83, 41), Vector2i(85, 42)], TILE_SIGN)
	_paint_cells(decoration_layer, [Vector2i(81, 40), Vector2i(86, 44), Vector2i(88, 43)], TILE_STONE)
	_fill_rect(tall_grass_layer, Rect2i(78, 45, 6, 4), TILE_TALL_GRASS)

	# Natural borders and grouped decoration clusters.
	_build_tree_cluster([
		Vector2i(6, 8), Vector2i(10, 10), Vector2i(13, 8), Vector2i(35, 8), Vector2i(40, 9), Vector2i(57, 7),
		Vector2i(83, 9), Vector2i(88, 11), Vector2i(90, 16), Vector2i(8, 24), Vector2i(12, 26), Vector2i(86, 24),
		Vector2i(90, 28), Vector2i(6, 46), Vector2i(10, 49), Vector2i(15, 50), Vector2i(88, 47), Vector2i(92, 49)
	])
	_paint_cells(collision_layer, [Vector2i(5, 14), Vector2i(7, 16), Vector2i(89, 36), Vector2i(91, 39), Vector2i(54, 46), Vector2i(56, 47)], TILE_BUSH)
	_paint_cells(decoration_layer, [Vector2i(38, 20), Vector2i(55, 23), Vector2i(35, 41), Vector2i(63, 33), Vector2i(74, 39)], TILE_FLOWER)
	_build_border_colliders()

func _build_wind_plaza_visual_ground() -> void:
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
	map_size = Vector2i(96, 54)
	_build_grove_visual_ground()
	_fill_rect(ground_layer, Rect2i(0, 0, map_size.x, map_size.y), TILE_GRASS)
	_fill_rect(ground_layer, Rect2i(40, 37, 16, 7), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(46, 0, 4, map_size.y), TILE_ROAD)
	_fill_rect(ground_layer, Rect2i(8, 8, 16, 9), TILE_WATER)
	_fill_rect(tall_grass_layer, Rect2i(64, 10, 14, 8), TILE_TALL_GRASS)
	_fill_rect(tall_grass_layer, Rect2i(14, 35, 16, 8), TILE_TALL_GRASS)
	_set_tile(decoration_layer, Vector2i(30, 20), TILE_FLOWER)
	_set_tile(decoration_layer, Vector2i(58, 41), TILE_FLOWER)
	_set_tile(decoration_layer, Vector2i(51, 36), TILE_SIGN)
	_fill_rect(decoration_layer, Rect2i(74, 35, 9, 5), TILE_SOIL)
	_build_fence_row(73, 34, 12)
	_build_fence_column(73, 35, 7)
	_build_fence_column(84, 35, 7)
	_build_tree_cluster([Vector2i(11, 24), Vector2i(18, 25), Vector2i(25, 21), Vector2i(66, 24), Vector2i(74, 27), Vector2i(85, 18), Vector2i(88, 22), Vector2i(10, 49), Vector2i(30, 48)])
	_build_border_colliders()

func _build_grove_visual_ground() -> void:
	_build_visual_layout("grove_gate")


func _build_house(wall_rect: Rect2i, roof_rect: Rect2i, door_cell: Vector2i) -> void:
	for x in range(wall_rect.position.x, wall_rect.end.x):
		for y in range(wall_rect.position.y, wall_rect.end.y):
			_set_collision_tile(Vector2i(x, y), TILE_WALL)
	for x in range(roof_rect.position.x, roof_rect.end.x):
		for y in range(roof_rect.position.y, roof_rect.end.y):
			_set_tile(foreground_layer, Vector2i(x, y), TILE_ROOF)
			if y == roof_rect.position.y:
				_set_tile(foreground_layer, Vector2i(x, y), TILE_CANOPY)
	_set_tile(decoration_layer, door_cell, TILE_DOOR)
	_remove_collision_at(door_cell)
	_remove_collision_at(door_cell + Vector2i(0, -1))

func _build_tree_cluster(cells: Array[Vector2i]) -> void:
	for cell in cells:
		_set_collision_tile(cell, TILE_TREE_TRUNK)
		_set_tile(foreground_layer, cell + Vector2i(0, -1), TILE_CANOPY)

func _build_fence_row(start_x: int, y: int, width: int) -> void:
	for x in range(start_x, start_x + width):
		_set_collision_tile(Vector2i(x, y), TILE_FENCE)

func _build_fence_column(x: int, start_y: int, height: int) -> void:
	for y in range(start_y, start_y + height):
		_set_collision_tile(Vector2i(x, y), TILE_FENCE)

func _build_border_colliders() -> void:
	for x in range(map_size.x):
		_set_collision_tile(Vector2i(x, 0), TILE_BUSH)
		_set_collision_tile(Vector2i(x, map_size.y - 1), TILE_BUSH)
	for y in range(1, map_size.y - 1):
		_set_collision_tile(Vector2i(0, y), TILE_BUSH)
		_set_collision_tile(Vector2i(map_size.x - 1, y), TILE_BUSH)

func _set_tile(layer: TileMapLayer, cell: Vector2i, atlas_coords: Vector2i) -> void:
	layer.set_cell(cell, TILE_SOURCE_ID, atlas_coords, 0)

func _set_collision_tile(cell: Vector2i, atlas_coords: Vector2i) -> void:
	collision_layer.set_cell(cell, TILE_SOURCE_ID, atlas_coords, 0)
	_add_collision_body(cell)

func _fill_rect(layer: TileMapLayer, rect: Rect2i, atlas_coords: Vector2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_set_tile(layer, Vector2i(x, y), atlas_coords)

func _paint_cells(layer: TileMapLayer, cells: Array[Vector2i], atlas_coords: Vector2i) -> void:
	for cell in cells:
		_set_tile(layer, cell, atlas_coords)

func _paint_collision_only_cells(cells: Array[Vector2i], atlas_coords: Vector2i) -> void:
	for cell in cells:
		_add_collision_body(cell)
		collision_layer.set_cell(cell, TILE_SOURCE_ID, atlas_coords, 0)

func _add_collision_body(cell: Vector2i) -> void:
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

func _remove_collision_at(cell: Vector2i) -> void:
	for child in collision_geometry.get_children():
		if child is StaticBody2D and child.position == Vector2(cell.x * 16 + 8, cell.y * 16 + 8):
			child.queue_free()

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
	assert(ground_layer != null)
	assert(decoration_layer != null)
	assert(collision_layer != null)
	assert(tall_grass_layer != null)
	assert(foreground_layer != null)
	assert(player != null)
	assert(dialogue_ui != null)
	assert(gameplay_ui != null)