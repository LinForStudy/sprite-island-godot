extends Node

signal ui_state_changed(panel: String)
signal message_changed(message: String)
signal encounter_changed(spirit_id: String)

var current_panel: String = "hud"
var active_habitat_id: String = ""
var current_encounter_id: String = ""
var current_encounter_habitat_id: String = ""
var home_selected_spirit_id: String = ""
var selected_battle_spirit_id: String = ""
var message: String = "欢迎来到萌灵小岛，先找一个探索点吧。"

func is_modal_open() -> bool:
	return current_panel != "hud"

func set_message(text: String) -> void:
	message = text
	message_changed.emit(message)

func open_habitat_panel(habitat_id: String) -> void:
	if not SaveManager.is_habitat_unlocked(habitat_id):
		var locked_habitat: HabitatData = GameCatalog.get_habitat_by_id(habitat_id)
		var locked_name: String = locked_habitat.display_name if locked_habitat != null else habitat_id
		set_message("%s还在等待新的小岛伙伴。先收服萌灵并照料它们吧。" % locked_name)
		return
	active_habitat_id = habitat_id
	current_panel = "habitat"
	ui_state_changed.emit(current_panel)
	var habitat: HabitatData = GameCatalog.get_habitat_by_id(habitat_id)
	if habitat != null:
		set_message("来到%s。%s" % [habitat.display_name, habitat.intro_text])

func open_dex() -> void:
	current_panel = "dex"
	ui_state_changed.emit(current_panel)
	set_message("图鉴会记录未发现、已发现和已入住的萌灵。")

func open_home(spirit_id: String = "") -> void:
	if spirit_id != "":
		home_selected_spirit_id = spirit_id
	elif home_selected_spirit_id == "":
		var captured_ids: Array[String] = SaveManager.get_captured_spirit_ids()
		if not captured_ids.is_empty():
			home_selected_spirit_id = captured_ids[0]
	current_panel = "home"
	ui_state_changed.emit(current_panel)
	set_message("回到小屋，看看入住的萌灵吧。")

func close_panel() -> void:
	current_panel = "hud"
	ui_state_changed.emit(current_panel)

func clear_encounter() -> void:
	current_encounter_id = ""
	current_encounter_habitat_id = ""
	encounter_changed.emit("")

func leave_encounter() -> void:
	clear_encounter()
	close_panel()

func start_explore() -> SpiritData:
	if active_habitat_id == "":
		return null
	var streak: int = SaveManager.add_exploration_streak(active_habitat_id)
	var discovered: Dictionary = Dictionary(SaveManager.get_save_data().get("discovered", {}))
	var spirit: SpiritData = GameCatalog.roll_encounter(active_habitat_id, discovered, streak)
	if spirit == null:
		set_message("这里暂时还没有可以遇见的萌灵。")
		return null
	SaveManager.mark_discovered(spirit.spirit_id)
	current_encounter_id = spirit.spirit_id
	current_encounter_habitat_id = active_habitat_id
	current_panel = "encounter"
	encounter_changed.emit(current_encounter_id)
	ui_state_changed.emit(current_panel)
	var status: String = "已入住" if SaveManager.has_captured(spirit.spirit_id) else "新朋友"
	var habitat: HabitatData = GameCatalog.get_habitat_by_id(active_habitat_id)
	var habitat_name: String = habitat.display_name if habitat != null else active_habitat_id
	set_message("在%s遇见了%s（%s）。" % [habitat_name, spirit.display_name, status])
	return spirit

func ensure_battle_target() -> SpiritData:
	if current_encounter_habitat_id == active_habitat_id and current_encounter_id != "":
		return GameCatalog.get_spirit_by_id(current_encounter_id)
	return start_explore()

func attempt_direct_capture() -> Dictionary:
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(current_encounter_id)
	if spirit == null:
		return {"status": "none", "message": "还没有可以邀请的萌灵。"}
	if SaveManager.has_captured(spirit.spirit_id):
		var already_message: String = "%s已经住进小屋啦。" % spirit.display_name
		set_message(already_message)
		return {"status": "already", "message": already_message}
	var success: bool = randf() <= spirit.catch_rate
	if success and SaveManager.capture_spirit(spirit):
		var captured_message: String = "%s愿意住进小屋啦！" % spirit.display_name
		set_message(captured_message)
		return {"status": "captured", "message": captured_message}
	var failed_message: String = "%s还有点害羞，再试试吧。" % spirit.display_name
	set_message(failed_message)
	return {"status": "failed", "message": failed_message}