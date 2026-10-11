extends CanvasLayer
class_name PauseMenu

@onready var btn_resume: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BtnResume
@onready var btn_settings: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BtnSettings
@onready var btn_menu: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BtnMenu
@onready var btn_close: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BtnClose

var countdown_active: bool = false
var countdown_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	add_to_group("pause_menu")
	hide()
	
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_close.pressed.connect(_on_close_pressed)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	if get_tree().get_first_node_in_group("settings_overlay"):
		return
	get_viewport().set_input_as_handled()
	if visible:
		if get_tree().paused:
			_on_resume_pressed()
		else:
			hide()
	else:
		open_pause_menu()

func toggle_pause() -> void:
	if visible and get_tree().paused:
		_on_resume_pressed()
	elif visible:
		hide()
	else:
		open_pause_menu()

func open_pause_menu() -> void:
	if countdown_active:
		return
	show()
	get_tree().paused = true
	btn_resume.text = "TIẾP TỤC TRẬN ĐẤU"
	btn_close.disabled = true
	AudioManager.set_gameplay_paused(true)

func open_settings_menu() -> void:
	if countdown_active:
		return
	show()
	if get_tree().paused:
		btn_resume.text = "TIẾP TỤC TRẬN ĐẤU"
	else:
		btn_resume.text = "TẠM DỪNG TRẬN ĐẤU"
	btn_close.disabled = get_tree().paused

func _on_resume_pressed() -> void:
	if countdown_active:
		return
	if not get_tree().paused:
		get_tree().paused = true
		AudioManager.set_gameplay_paused(true)
		btn_resume.text = "TIẾP TỤC TRẬN ĐẤU"
		btn_close.disabled = true
		return
	_start_resume_countdown()

func _on_settings_pressed() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		AudioManager.set_gameplay_paused(true)
		btn_resume.text = "TIẾP TỤC TRẬN ĐẤU"
		btn_close.disabled = true
	hide()
	GameData.settings_return_scene = ""
	var settings: Node = load("res://scenes/ui/settings.tscn").instantiate()
	settings.process_mode = Node.PROCESS_MODE_ALWAYS
	var game_canvas := get_tree().current_scene.get_node_or_null("CanvasLayer")
	if not game_canvas:
		push_error("Cannot open settings: the gameplay CanvasLayer was not found.")
		show()
		return
	game_canvas.add_child(settings)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	AudioManager.set_gameplay_paused(false)
	var error := get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")
	if error != OK:
		push_error("Cannot return to the main menu: %s" % error_string(error))

func _start_resume_countdown() -> void:
	countdown_active = true
	btn_resume.disabled = true
	btn_settings.disabled = true
	btn_menu.disabled = true
	var overlay := _create_countdown_overlay()
	for seconds_left in [3, 2, 1]:
		countdown_label.text = str(seconds_left)
		countdown_label.scale = Vector2(0.65, 0.65)
		countdown_label.modulate.a = 0.35
		var pulse := create_tween().set_parallel(true)
		pulse.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_property(countdown_label, "scale", Vector2.ONE, 0.35)
		pulse.tween_property(countdown_label, "modulate:a", 1.0, 0.35)
		await get_tree().create_timer(1.0, true).timeout

	get_tree().paused = false
	AudioManager.set_gameplay_paused(false)
	hide()
	overlay.queue_free()
	btn_resume.disabled = false
	btn_settings.disabled = false
	btn_menu.disabled = false
	btn_resume.text = "TẠM DỪNG TRẬN ĐẤU"
	btn_close.disabled = false
	countdown_active = false

func _on_close_pressed() -> void:
	if not get_tree().paused:
		hide()

func _create_countdown_overlay() -> Control:
	var overlay := Control.new()
	overlay.name = "ResumeCountdown"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.03, 0.94)
	overlay.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 250)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.075, 0.095, 0.98)
	panel_style.border_color = Color(1.0, 0.76, 0.28, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(18)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	panel_style.shadow_size = 24
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title := Label.new()
	title.text = "SẴN SÀNG TRỞ LẠI?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.87, 0.48))
	content.add_child(title)

	countdown_label = Label.new()
	countdown_label.custom_minimum_size.y = 120
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 88)
	countdown_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.8))
	countdown_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.59, 0.14, 0.75))
	countdown_label.add_theme_constant_override("shadow_offset_x", 2)
	countdown_label.add_theme_constant_override("shadow_offset_y", 3)
	content.add_child(countdown_label)

	var hint := Label.new()
	hint.text = "Trận đấu sẽ tiếp tục sau khi đếm ngược"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.72, 0.77, 0.82))
	content.add_child(hint)
	return overlay
