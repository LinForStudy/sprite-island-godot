extends Node

var failure_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_check_settings_persistence()
	_check_audio_buses_and_resources()
	if failure_count == 0:
		print("SETTINGS_AUDIO_SMOKE_OK")
	get_tree().quit(failure_count)


func _check_settings_persistence() -> void:
	SettingsManager.set_master_volume(0.55)
	SettingsManager.set_music_volume(0.45)
	SettingsManager.set_sfx_volume(0.35)
	SettingsManager.set_fullscreen(false)
	var expected: Dictionary = {
		"master_volume": 0.55,
		"music_volume": 0.45,
		"sfx_volume": 0.35,
		"fullscreen": false
	}
	_expect(SettingsManager.get_settings() == expected, "settings should update in memory")
	_expect(FileAccess.file_exists("user://settings.json"), "settings should persist separately in user storage")
	var file: FileAccess = FileAccess.open("user://settings.json", FileAccess.READ)
	var persisted = JSON.parse_string(file.get_as_text()) if file != null else null
	_expect(typeof(persisted) == TYPE_DICTIONARY and Dictionary(persisted) == expected, "settings file should contain the selected values")
	SettingsManager.load_settings()
	_expect(SettingsManager.get_settings() == expected, "settings should survive a reload")


func _check_audio_buses_and_resources() -> void:
	_expect(AudioServer.get_bus_index("Music") >= 0, "Music bus should exist")
	_expect(AudioServer.get_bus_index("SFX") >= 0, "SFX bus should exist")
	for path_value in AudioManager.MUSIC_PATHS.values():
		var path: String = String(path_value)
		_expect(ResourceLoader.exists(path), "music resource should exist: %s" % path)
	for path_value in AudioManager.SFX_PATHS.values():
		var path: String = String(path_value)
		_expect(ResourceLoader.exists(path), "sound resource should exist: %s" % path)
	AudioManager.play_world_music("test_world")
	await get_tree().process_frame
	_expect(AudioManager.current_music_id == "test_world" and AudioManager.music_player.stream != null, "world music should load")
	AudioManager.play_battle_music()
	await get_tree().process_frame
	_expect(AudioManager.current_music_id == "battle" and AudioManager.music_player.stream != null, "battle music should load")
	var previous_sfx_player: int = AudioManager.next_sfx_player
	AudioManager.play_capture()
	await get_tree().process_frame
	_expect(AudioManager.next_sfx_player != previous_sfx_player, "successful capture sound should use the SFX pool")
	AudioManager.stop_music()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error(message)
