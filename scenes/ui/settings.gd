extends Control

@onready var master_slider: HSlider = $MasterSlider
@onready var btn_back: Button = $BtnBack
@onready var touch_controls_check: CheckButton = get_node_or_null("TouchControlsCheck")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var master_bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(maxf(GameData.master_volume, 0.001)))
	
	if master_slider:
		master_slider.value = GameData.master_volume
		master_slider.value_changed.connect(func(value: float):
			GameData.master_volume = value
			AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(maxf(value, 0.001)))
			GameData.save_settings()
		)
	
	if touch_controls_check:
		touch_controls_check.button_pressed = GameData.touch_controls_enabled
		touch_controls_check.toggled.connect(func(enabled: bool):
			GameData.touch_controls_enabled = enabled
			GameData.save_settings()
			var touch := get_tree().get_first_node_in_group("touch_controls")
			if touch and touch.has_method("set_controls_visible"):
				touch.set_controls_visible(enabled)
		)

	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	if GameData.settings_return_scene.is_empty():
		queue_free()
		var pause_menu := get_tree().get_first_node_in_group("pause_menu")
		if pause_menu:
			pause_menu.show()
	else:
		get_tree().change_scene_to_file(GameData.settings_return_scene)
