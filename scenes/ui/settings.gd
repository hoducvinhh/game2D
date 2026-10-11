extends Control

@onready var master_slider: HSlider = $CenterContainer/Panel/MarginContainer/Content/MasterSlider
@onready var btn_back: Button = $CenterContainer/Panel/MarginContainer/Content/BtnBack
@onready var touch_controls_check: CheckButton = $CenterContainer/Panel/MarginContainer/Content/TouchControlsCheck

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("settings_overlay")
	_configure_audio_slider(master_slider, &"Master")
	_configure_audio_slider($CenterContainer/Panel/MarginContainer/Content/LobbyMusicSlider, &"BG_LOBBY")
	_configure_audio_slider($CenterContainer/Panel/MarginContainer/Content/GameMusicSlider, &"BG_GAME")
	_configure_audio_slider($CenterContainer/Panel/MarginContainer/Content/SoundEffectsSlider, &"DR")
	
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

func _configure_audio_slider(slider: HSlider, bus_name: StringName) -> void:
	slider.value = GameData.get_audio_volume(bus_name)
	slider.value_changed.connect(_on_audio_slider_changed.bind(bus_name))

func _on_audio_slider_changed(value: float, bus_name: StringName) -> void:
	GameData.set_audio_volume(bus_name, value)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func _on_back_pressed() -> void:
	if GameData.settings_return_scene.is_empty():
		queue_free()
		var pause_menu := get_tree().get_first_node_in_group("pause_menu")
		if pause_menu:
			pause_menu.show()
	else:
		get_tree().change_scene_to_file(GameData.settings_return_scene)
