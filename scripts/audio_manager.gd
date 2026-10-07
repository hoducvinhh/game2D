extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
