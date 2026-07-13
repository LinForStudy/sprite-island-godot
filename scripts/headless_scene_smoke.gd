extends SceneTree

const SCENES := [
	"res://scenes/world/test_world.tscn",
	"res://scenes/world/grove_gate.tscn"
]

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
		print("SCENE_OK:%s" % scene_path)
		node.queue_free()
		await process_frame
	print("HEADLESS_SCENE_SMOKE_OK")
	quit()