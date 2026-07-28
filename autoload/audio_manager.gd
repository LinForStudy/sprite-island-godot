extends Node

const MUSIC_PATHS: Dictionary = {
	"test_world": "res://assets/audio/music/new_island_theme.wav",
	"grove_gate": "res://assets/audio/music/grove_theme.wav",
	"battle": "res://assets/audio/music/battle_theme.wav"
}
const SFX_PATHS: Dictionary = {
	"ui": "res://assets/audio/sfx/ui_click.wav",
	"move": "res://assets/audio/sfx/footstep.wav",
	"skill": "res://assets/audio/sfx/skill.wav",
	"hurt": "res://assets/audio/sfx/hurt.wav",
	"capture": "res://assets/audio/sfx/capture.wav"
}
const SFX_POOL_SIZE := 5

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_music_id: String = ""
var next_sfx_player: int = 0


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	for index in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % index
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	var settings_manager: Node = get_node_or_null("/root/SettingsManager")
	if settings_manager != null:
		settings_manager.call("apply_settings")


func play_world_music(scene_id: String) -> void:
	play_music(scene_id if MUSIC_PATHS.has(scene_id) else "test_world")


func play_battle_music() -> void:
	play_music("battle")


func play_music(music_id: String) -> void:
	if current_music_id == music_id and music_player.playing:
		return
	var path: String = String(MUSIC_PATHS.get(music_id, ""))
	if path == "":
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("AudioManager could not load music: %s" % path)
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.stream = stream
	music_player.play()
	current_music_id = music_id


func stop_music(fade_seconds: float = 0.0) -> void:
	if fade_seconds <= 0.0:
		music_player.stop()
		current_music_id = ""
		return
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", -60.0, fade_seconds)
	tween.tween_callback(func() -> void:
		music_player.stop()
		music_player.volume_db = 0.0
		current_music_id = ""
	)


func play_ui() -> void:
	play_sfx("ui")


func play_move() -> void:
	play_sfx("move", -8.0)


func play_skill() -> void:
	play_sfx("skill")


func play_hurt() -> void:
	play_sfx("hurt")


func play_capture() -> void:
	play_sfx("capture")


func play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	if sfx_players.is_empty():
		return
	var path: String = String(SFX_PATHS.get(sfx_id, ""))
	if path == "":
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	var player: AudioStreamPlayer = sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus_index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
