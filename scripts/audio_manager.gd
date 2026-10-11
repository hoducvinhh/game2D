extends Node

const LOBBY_MUSIC: AudioStream = preload("res://assets/music/background_music.ogg")
const GAME_MUSIC: AudioStream = preload("res://assets/music/background_music.ogg")

var music_player: AudioStreamPlayer
var current_music_context: StringName = &""
var gameplay_paused: bool = false

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

	var is_gameplay := scene.scene_file_path == "res://scenes/levels/main.tscn"
	var next_context: StringName = &"game" if is_gameplay else &"lobby"
	if current_music_context == next_context and music_player.playing:
		return

	current_music_context = next_context
	music_player.stream = GAME_MUSIC if is_gameplay else LOBBY_MUSIC
	music_player.bus = &"BG_GAME" if is_gameplay else &"BG_LOBBY"
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
