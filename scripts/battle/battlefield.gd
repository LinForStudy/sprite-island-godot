class_name Battlefield
extends Node2D

## 独立战场的分层、逻辑网格、碰撞与场景钩子契约。
## 可视地面来自项目 TileSet；角色、前景遮挡和边界始终保持为独立运行时层。
const REQUIRED_LAYERS: Array[String] = [
	"FoundationTiles",
	"BackgroundProps",
	"ActorPlatforms",
	"ForegroundOccluders",
	"SceneHooks",
	"ArenaCollision"
]
const POSITION_MARKERS: Dictionary = {
	"left": "PlayerSpawnLeft",
	"center": "PlayerSpawnCenter",
	"right": "PlayerSpawnRight"
}

@export var habitat_id: String = "grassland"
@export var field_signature: String = "grassland-v1"
@export var logical_grid_size: int = 16
@export var camera_bounds: Rect2 = Rect2(0.0, 0.0, 1280.0, 720.0)
@export var foundation_source_ids: PackedInt32Array = PackedInt32Array([5, 6])
@export var foundation_start_row: int = 6
@export var foundation_end_row: int = 11

func _ready() -> void:
	_paint_foundation_tiles()

func get_player_spawn(slot: String) -> Vector2:
	var marker_name: String = String(POSITION_MARKERS.get(slot, POSITION_MARKERS["center"]))
	var marker: Marker2D = get_node_or_null("SceneHooks/%s" % marker_name) as Marker2D
	return marker.position if marker != null else Vector2(384.0, 472.0)

func get_enemy_spawn() -> Vector2:
	var marker: Marker2D = get_node_or_null("SceneHooks/EnemySpawn") as Marker2D
	return marker.position if marker != null else Vector2(822.0, 306.0)

func get_camera_bounds() -> Rect2:
	return camera_bounds

func validate_contract(expected_habitat_id: String = "") -> PackedStringArray:
	var issues: PackedStringArray = PackedStringArray()
	if habitat_id == "" or habitat_id == "fallback":
		issues.append("habitat_id 必须是真实地区 ID")
	if expected_habitat_id != "" and habitat_id != expected_habitat_id:
		issues.append("habitat_id 应为 %s，当前为 %s" % [expected_habitat_id, habitat_id])
	if field_signature == "" or field_signature == "fallback":
		issues.append("field_signature 不能使用 fallback")
	if logical_grid_size != 16:
		issues.append("逻辑网格必须为 16px")
	for layer_name in REQUIRED_LAYERS:
		if get_node_or_null(String(layer_name)) == null:
			issues.append("缺少分层节点 %s" % layer_name)
	var foundation: TileMapLayer = get_node_or_null("FoundationTiles") as TileMapLayer
	if foundation == null or foundation.tile_set == null:
		issues.append("FoundationTiles 必须绑定项目 TileSet")
	for marker_name in POSITION_MARKERS.values():
		if get_node_or_null("SceneHooks/%s" % String(marker_name)) == null:
			issues.append("缺少场景钩子 %s" % marker_name)
	if get_node_or_null("SceneHooks/EnemySpawn") == null:
		issues.append("缺少场景钩子 EnemySpawn")
	var collision_root: Node = get_node_or_null("ArenaCollision")
	if collision_root == null or collision_root.get_child_count() < 4:
		issues.append("ArenaCollision 至少需要四条独立边界")
	return issues

func _paint_foundation_tiles() -> void:
	var foundation: TileMapLayer = get_node_or_null("FoundationTiles") as TileMapLayer
	if foundation == null or foundation.tile_set == null or foundation_source_ids.is_empty():
		return
	if not foundation.get_used_cells().is_empty():
		return
	var tile_size: Vector2i = foundation.tile_set.tile_size
	if tile_size.x <= 0 or tile_size.y <= 0:
		return
	var column_count: int = int(ceil(camera_bounds.size.x / float(tile_size.x))) + 1
	for tile_y in range(foundation_start_row, foundation_end_row + 1):
		for tile_x in range(column_count):
			var source_index: int = posmod(tile_x + tile_y, foundation_source_ids.size())
			foundation.set_cell(Vector2i(tile_x, tile_y), foundation_source_ids[source_index], Vector2i.ZERO, 0)