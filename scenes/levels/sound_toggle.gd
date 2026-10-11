extends CheckButton

const MUSIC_BUSES: Array[StringName] = [&"BG_GAME", &"BG_LOBBY"]

func _ready() -> void:
	button_pressed = true
	for bus_name in MUSIC_BUSES:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index >= 0 and AudioServer.is_bus_mute(bus_index):
			button_pressed = false
	toggled.connect(_on_toggled)

func _on_toggled(enabled: bool) -> void:
	for bus_name in MUSIC_BUSES:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index >= 0:
			AudioServer.set_bus_mute(bus_index, not enabled)
