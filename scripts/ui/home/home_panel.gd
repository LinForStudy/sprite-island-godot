extends Control

const PORTRAIT_CATALOG: Script = preload("res://scripts/ui/components/spirit_portrait_catalog.gd")
const STAT_METER_SCENE: PackedScene = preload("res://scenes/ui/components/stat_meter.tscn")
const PORTRAIT_CARD_SCENE: PackedScene = preload("res://scenes/ui/components/spirit_portrait_card.tscn")

@onready var partner_list: VBoxContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/PartnerPanel/Margin/PartnerScroll/PartnerList
@onready var portrait: TextureRect = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/PetStage/StageLayout/Portrait
@onready var pet_name: Label = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/PetStage/StageLayout/PetName
@onready var hint: Label = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/PetStage/StageLayout/EmptyHint
@onready var feedback: Label = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/PetStage/Feedback
@onready var actions: HBoxContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/Actions
@onready var stats: VBoxContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/StatsPanel/StatsMargin/Stats

var selected_spirit_id: String = ""
var feedback_tween: Tween = null
var last_pet_snapshot: Dictionary = {}

func _ready() -> void:
	$ModalShell.close_requested.connect(GameState.close_panel)
	for button in actions.get_children():
		button.pressed.connect(func() -> void: _care(button.name))
	_style_panels()
	_refresh()

func refresh() -> void:
	if not $ModalShell.visible:
		$ModalShell.open()
	_refresh()

func _refresh() -> void:
	var captured: Array[String] = SaveManager.get_captured_spirit_ids()
	if GameState.home_selected_spirit_id != "" and captured.has(GameState.home_selected_spirit_id):
		selected_spirit_id = GameState.home_selected_spirit_id
	if selected_spirit_id == "" or not captured.has(selected_spirit_id):
		selected_spirit_id = captured[0] if not captured.is_empty() else ""
		GameState.home_selected_spirit_id = selected_spirit_id
	_rebuild_partner_list(captured)
	var empty: bool = selected_spirit_id == ""
	hint.visible = empty
	portrait.visible = not empty
	for button in actions.get_children():
		button.disabled = empty
	if empty:
		pet_name.text = "欢迎回到小屋"
		last_pet_snapshot.clear()
		_clear_stats()
		return
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(selected_spirit_id)
	var pet: Dictionary = SaveManager.get_pet_state(selected_spirit_id)
	pet_name.text = "%s  Lv.%d · %s" % [spirit.display_name, int(pet.level), _mood_label(String(pet.mood))]
	portrait.texture = PORTRAIT_CATALOG.get_texture(selected_spirit_id)
	_build_stats(pet)
	last_pet_snapshot = pet.duplicate(true)

func _rebuild_partner_list(captured: Array[String]) -> void:
	for child in partner_list.get_children():
		child.queue_free()
	for spirit_id in captured:
		var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
		var pet: Dictionary = SaveManager.get_pet_state(spirit_id)
		if spirit == null or pet.is_empty():
			continue
		var card: Button = PORTRAIT_CARD_SCENE.instantiate()
		partner_list.add_child(card)
		card.configure("%s Lv.%d" % [spirit.display_name, int(pet.level)], PORTRAIT_CATALOG.get_texture(spirit_id), card.CardState.SELECTED if spirit_id == selected_spirit_id else card.CardState.RESIDENT, _element_label(spirit.element), _mood_label(String(pet.mood)))
		card.pressed.connect(func() -> void:
			selected_spirit_id = spirit_id
			GameState.home_selected_spirit_id = spirit_id
			_refresh()
		)

func _build_stats(pet: Dictionary) -> void:
	_clear_stats()
	var values: Array = [["生命", int(pet.current_hp), 100], ["经验", int(pet.exp), 100], ["亲密", int(pet.affection), 100], ["饱腹", int(pet.hunger), 100], ["清洁", int(pet.cleanliness), 100]]
	for entry in values:
		var meter: VBoxContainer = STAT_METER_SCENE.instantiate()
		meter.label_text = String(entry[0])
		stats.add_child(meter)
		meter.set_value(float(entry[1]), float(entry[2]), true)

func _clear_stats() -> void:
	for child in stats.get_children():
		if child.name != "StatsTitle":
			child.queue_free()

func _care(action_name: String) -> void:
	if selected_spirit_id == "":
		return
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(selected_spirit_id)
	if spirit == null:
		return
	var action: String = "feed" if action_name == "Feed" else "clean" if action_name == "Clean" else "pet" if action_name == "Pet" else "rest"
	var before: Dictionary = SaveManager.get_pet_state(selected_spirit_id).duplicate(true)
	if action == "rest":
		GameState.set_message(SaveManager.restore_all_pets())
	else:
		GameState.set_message(SaveManager.care_for(spirit, action))
	var after: Dictionary = SaveManager.get_pet_state(selected_spirit_id).duplicate(true)
	_show_feedback(action, _build_change_text(before, after))
	_refresh()

func _show_feedback(action: String, change_text: String = "") -> void:
	feedback.text = change_text if change_text != "" else "休息完成" if action == "rest" else "好感 +5" if action == "pet" else "状态已改善"
	feedback.visible = true
	feedback.modulate = Color(1, 1, 1, 1)
	if is_instance_valid(feedback_tween):
		feedback_tween.kill()
	feedback_tween = create_tween()
	feedback_tween.tween_property(feedback, "modulate:a", 0.7, 0.12)
	feedback_tween.tween_property(feedback, "modulate:a", 0.0, 0.7)
	feedback_tween.tween_callback(func() -> void: feedback.visible = false)

func _build_change_text(before: Dictionary, after: Dictionary) -> String:
	var changes: PackedStringArray = []
	_collect_positive_change(changes, "亲密", before, after, "affection")
	_collect_positive_change(changes, "饱腹", before, after, "hunger")
	_collect_positive_change(changes, "清洁", before, after, "cleanliness")
	_collect_positive_change(changes, "生命", before, after, "current_hp")
	if changes.is_empty():
		return "状态已改善"
	return "  ".join(changes)

func _collect_positive_change(changes: PackedStringArray, label: String, before: Dictionary, after: Dictionary, key: String) -> void:
	var delta: int = int(after.get(key, 0)) - int(before.get(key, 0))
	if delta > 0:
		changes.append("%s +%d" % [label, delta])

func _element_label(element: String) -> String:
	match element:
		"grass":
			return "草"
		"water":
			return "水"
		"fire":
			return "火"
		"electric":
			return "电"
		"earth":
			return "土"
		"wind":
			return "风"
		_:
			return element

func _mood_label(mood: String) -> String:
	match mood:
		"happy":
			return "开心"
		"full":
			return "吃饱"
		"clean":
			return "清爽"
		"close":
			return "亲近"
		"rested":
			return "精神满满"
		_:
			return mood

func _style_panels() -> void:
	var shell: PanelContainer = $ModalShell/ModalCenter/ModalPanel
	var partner: PanelContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/PartnerPanel
	var stage: PanelContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/PetStage
	var status: PanelContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/HomeContent/StatsPanel
	shell.add_theme_stylebox_override("panel", _box(Color("fff9e9"), Color("8b6842"), 3, 20))
	partner.add_theme_stylebox_override("panel", _box(Color("f8f0da"), Color("c29a6c"), 2, 16))
	stage.add_theme_stylebox_override("panel", _box(Color("fff9e9"), Color("c29a6c"), 2, 16))
	status.add_theme_stylebox_override("panel", _box(Color("f8f0da"), Color("c29a6c"), 2, 16))
	pet_name.add_theme_color_override("font_color", Color("4a3b2c"))

func _box(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box