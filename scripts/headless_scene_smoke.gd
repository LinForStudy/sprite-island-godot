extends SceneTree

const SCENES := [
	"res://scenes/world/test_world.tscn",
	"res://scenes/world/grove_gate.tscn"
]
const WORLD_EXPECTATIONS: Dictionary = {
	"res://scenes/world/test_world.tscn": {"collision_count": 499, "habitat_count": 3},
	"res://scenes/world/grove_gate.tscn": {"collision_count": 339, "habitat_count": 3}
}
const LOGICAL_MAP_SIZE := Vector2i(96, 54)
const VISUAL_GRID_SIZE := Vector2i(24, 14)
const TILE_SIZE := 16

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for scene_path in SCENES:
		var packed: PackedScene = load(scene_path)
		if packed == null:
			push_error("LOAD_FAIL:%s" % scene_path)
			quit(1)
			return
		var node: Node = packed.instantiate()
		if node == null:
			push_error("INSTANTIATE_FAIL:%s" % scene_path)
			quit(1)
			return
		root.add_child(node)
		for i in 3:
			await process_frame
		if not _validate_world_contract(node, scene_path):
			node.queue_free()
			quit(1)
			return
		print("SCENE_OK:%s" % scene_path)
		node.queue_free()
		await process_frame
	print("HEADLESS_SCENE_SMOKE_OK")
	quit()

func _validate_world_contract(world: Node, scene_path: String) -> bool:
	var expected: Dictionary = Dictionary(WORLD_EXPECTATIONS.get(scene_path, {}))
	if expected.is_empty():
		return _fail("missing world expectation: %s" % scene_path)
	if Vector2i(world.get("map_size")) != LOGICAL_MAP_SIZE:
		return _fail("%s logical map size should remain %s" % [scene_path, LOGICAL_MAP_SIZE])
	var visual_ground: TileMapLayer = world.get_node_or_null("VisualGroundLayer") as TileMapLayer
	var path_layer: TileMapLayer = world.get_node_or_null("PathLayer") as TileMapLayer
	var detail_layer: TileMapLayer = world.get_node_or_null("GroundDetailLayer") as TileMapLayer
	if visual_ground == null or path_layer == null or detail_layer == null:
		return _fail("%s is missing editable visual TileMap layers" % scene_path)
	if visual_ground.get_used_cells().size() != VISUAL_GRID_SIZE.x * VISUAL_GRID_SIZE.y:
		return _fail("%s visual ground grid should remain %d cells" % [scene_path, VISUAL_GRID_SIZE.x * VISUAL_GRID_SIZE.y])
	if path_layer.get_used_cells().is_empty() or detail_layer.get_used_cells().is_empty():
		return _fail("%s should keep both path and detail visual layers" % scene_path)
	var collision_geometry: Node2D = world.get_node_or_null("CollisionGeometry") as Node2D
	if collision_geometry == null or collision_geometry.get_child_count() != int(expected.get("collision_count", -1)):
		return _fail("%s collision count does not match its layout contract" % scene_path)
	var habitat_points: Node2D = world.get_node_or_null("HabitatPoints") as Node2D
	if habitat_points == null or habitat_points.get_child_count() != int(expected.get("habitat_count", -1)):
		return _fail("%s should provide the expected number of habitat points" % scene_path)
	var ysort_entities: Node2D = world.get_node_or_null("YSortEntities") as Node2D
	if ysort_entities == null or not ysort_entities.y_sort_enabled:
		return _fail("%s must retain Y-sorted actors" % scene_path)
	var camera: Camera2D = world.get_node_or_null("CameraController") as Camera2D
	if camera == null or camera.limit_right != LOGICAL_MAP_SIZE.x * TILE_SIZE or camera.limit_bottom != LOGICAL_MAP_SIZE.y * TILE_SIZE:
		return _fail("%s camera limits do not match the logical map bounds" % scene_path)
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false
