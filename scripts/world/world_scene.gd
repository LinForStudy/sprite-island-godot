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

@export var scene_id: String = ""
@export var map_preset: String = "test_world"
@export var default_spawn_id: String = "entry_default"

@onready var visual_ground_layer: TileMapLayer = get_node_or_null("VisualGroundLayer") as TileMapLayer
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var decoration_layer: TileMapLayer = $DecorationLayer
@onready var collision_layer: TileMapLayer = $CollisionLayer
@onready var tall_grass_layer: TileMapLayer = $TallGrassLayer
@onready var foreground_layer: TileMapLayer = $ForegroundLayer
@onready var collision_geometry: Node2D = $CollisionGeometry
@onready var habitat_points_root: Node2D = $HabitatPoints
@onready var spawn_points: Node2D = $SpawnPoints
@onready var player: Node = $Player
@onready var camera_controller: Camera2D = $CameraController
@onready var dialogue_ui: Node = $DialogueUI
@onready var gameplay_ui: Node = $GameplayUI

var map_size: Vector2i = Vector2i(96, 54)

func _ready() -> void:
	WorldState.register_scene(scene_id)
	_build_map()
	_hide_helper_layers()
	_spawn_habitat_points()
	_place_player()
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
	ground_layer.clear()
	decoration_layer.clear()
	collision_layer.clear()
	tall_grass_layer.clear()
	foreground_layer.clear()
	for child in collision_geometry.get_children():
		child.queue_free()

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
	if visual_ground_layer == null:
		return
	for x in range(24):
		for y in range(14):
			var source_id: int = VISUAL_SOURCE_GRASS_1
			var pattern_index: int = (x * 3 + y * 5) % 6
			if pattern_index == 1 or pattern_index == 4:
				source_id = VISUAL_SOURCE_GRASS_2
			elif pattern_index == 2:
				source_id = VISUAL_SOURCE_GRASS_3
			_set_visual_tile(Vector2i(x, y), source_id)

	_fill_visual_rect(Rect2i(10, 5, 4, 3), VISUAL_SOURCE_PLAZA)
	_fill_visual_rect(Rect2i(9, 5, 2, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(8, 4, 2, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(7, 3, 2, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(8, 7, 3, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(7, 8, 1, 2), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(5, 9, 3, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(13, 5, 3, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(15, 4, 1, 2), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(15, 3, 3, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(11, 7, 1, 3), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(8, 9, 4, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(6, 11, 3, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(13, 7, 3, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(15, 8, 1, 2), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(16, 9, 3, 1), VISUAL_SOURCE_ROAD)
	_fill_visual_rect(Rect2i(18, 10, 4, 1), VISUAL_SOURCE_ROAD)
	_build_grassland_visual_ground()

func _build_grassland_visual_ground() -> void:
	_fill_visual_rect(Rect2i(3, 2, 5, 4), VISUAL_SOURCE_GRASSLAND_1)
	_fill_visual_rect(Rect2i(5, 3, 4, 3), VISUAL_SOURCE_GRASSLAND_2)
	_fill_visual_rect(Rect2i(4, 5, 4, 2), VISUAL_SOURCE_TALL_GRASS)
	_fill_visual_rect(Rect2i(7, 4, 2, 2), VISUAL_SOURCE_TALL_GRASS)
	_fill_visual_rect(Rect2i(6, 3, 2, 1), VISUAL_SOURCE_GRASS_EDGE)
	_fill_visual_rect(Rect2i(8, 5, 1, 2), VISUAL_SOURCE_GRASS_EDGE)
func _set_visual_tile(cell: Vector2i, source_id: int) -> void:
	if visual_ground_layer == null:
		return
	visual_ground_layer.set_cell(cell, source_id, VISUAL_TILE, 0)

func _fill_visual_rect(rect: Rect2i, source_id: int) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_set_visual_tile(Vector2i(x, y), source_id)
func _build_grove_gate() -> void:
	map_size = Vector2i(96, 54)
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