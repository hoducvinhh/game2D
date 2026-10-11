extends Node

const LOBBY_MUSIC: AudioStream = preload("res://assets/music/background_loppy.mp3")
const GAME_MUSIC: AudioStream = preload("res://assets/music/background_music.ogg")
const PLAYER_HIT_SOUND: AudioStream = preload("res://assets/music/player_hit.mp3")
const BOSS_SOUND: AudioStream = preload("res://assets/music/sound-boss.mp3")
const PLAYER_HIT_SOUND_INTERVAL_MS: int = 90

var music_player: AudioStreamPlayer
var current_music_context: StringName = &""
var gameplay_paused: bool = false
var last_player_hit_sound_ms: int = -PLAYER_HIT_SOUND_INTERVAL_MS

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_sync_music_with_scene")

func _on_scene_changed(_scene: Node) -> void:
	_sync_music_with_scene()

func _sync_music_with_scene() -> void:
	var scene := get_tree().current_scene
	if not is_instance_valid(scene):
		return

	var is_gameplay := scene.is_in_group("gameplay_scene") or scene.scene_file_path == "res://scenes/levels/main.tscn"
	set_music_context(is_gameplay)

func set_music_context(is_gameplay: bool) -> void:
	var next_context: StringName = &"game" if is_gameplay else &"lobby"
	var next_stream: AudioStream = GAME_MUSIC if is_gameplay else LOBBY_MUSIC
	var next_bus: StringName = &"BG_GAME" if is_gameplay else &"BG_LOBBY"
	if current_music_context == next_context and music_player.playing and music_player.stream == next_stream and music_player.bus == next_bus:
		return

	current_music_context = next_context
	music_player.stop()
	music_player.stream = next_stream
	music_player.bus = next_bus
	music_player.stream_paused = is_gameplay and gameplay_paused
	music_player.play()

func set_gameplay_paused(paused: bool) -> void:
	gameplay_paused = paused
	if current_music_context == &"game" and is_instance_valid(music_player):
		music_player.stream_paused = paused
	for child in get_children():
		if child is AudioStreamPlayer and child != music_player:
			child.stream_paused = paused

func play_sound(stream: AudioStream, bus_name: StringName = &"DR") -> void:
	if not stream:
		push_error("AudioManager.play_sound requires a valid AudioStream.")
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_player_hit_sound() -> void:
	var now_ms := Time.get_ticks_msec()
	if now_ms - last_player_hit_sound_ms < PLAYER_HIT_SOUND_INTERVAL_MS:
		return
	last_player_hit_sound_ms = now_ms
	play_sound(PLAYER_HIT_SOUND)

func play_boss_sound() -> void:
	music_player.stop()
	play_sound(BOSS_SOUND)
