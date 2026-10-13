extends CanvasLayer

const LOSS_SOUND: AudioStream = preload("res://assets/music/loss.mp3")
const RUN_SUMMARY = preload("res://scripts/ui/run_summary.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_sound(LOSS_SOUND)
	get_tree().paused = true

	# --- VIGNETTE / BACKDROP ---
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.015, 0.02, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# --- LỚP HIỆU ỨNG PHÁO HOA TUNG TÓE KHẮP MÀN HÌNH (DƯỚI BẢNG MENU) ---
	var fireworks_holder := Node2D.new()
	add_child(fireworks_holder)

	var vp_size := get_viewport().get_visible_rect().size
	# Đợt bắn pháo hoa đầu tiên mở màn
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.2, vp_size.y * 0.25), 45)
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.8, vp_size.y * 0.22), 45)
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.5, vp_size.y * 0.16), 50)
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.15, vp_size.y * 0.55), 38)
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.85, vp_size.y * 0.52), 38)

	# Kích hoạt bắn pháo hoa liên tục không dứt cho đến khi người chơi bấm nút thoát hoặc chơi lại
	RUN_SUMMARY.start_continuous_fireworks(self, fireworks_holder, 0.55)

	# --- CENTER WRAPPER ---
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# --- MAIN DIALOG PANEL ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(530, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.045, 0.05, 0.98)
	panel_style.border_color = Color(0.85, 0.22, 0.2, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0.85, 0.15, 0.15, 0.3)
	panel_style.shadow_size = 22
	panel_style.content_margin_left = 20
	panel_style.content_margin_top = 18
	panel_style.content_margin_right = 20
	panel_style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	# --- BANNER HEADER ---
	var header_vbox := VBoxContainer.new()
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.add_theme_constant_override("separation", 2)
	content.add_child(header_vbox)

	var skull_icon := Label.new()
	skull_icon.text = "☠️"
	skull_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skull_icon.add_theme_font_size_override("font_size", 28)
	header_vbox.add_child(skull_icon)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.28, 0.24))
	title.add_theme_color_override("font_outline_color", Color(0.4, 0.06, 0.06))
	title.add_theme_constant_override("outline_size", 5)
	header_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Chiến binh đã ngã xuống! Hãy nâng cấp và phục thù!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.75, 0.75))
	header_vbox.add_child(subtitle)

	# --- SUMMARY PANEL ---
	content.add_child(RUN_SUMMARY.create_panel())

	# --- ACTION BUTTONS (HBOX) ---
	var buttons_box := HBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 12)
	content.add_child(buttons_box)

	var replay_btn := RUN_SUMMARY.create_styled_button(
		"🔄  CHƠI LẠI",
		Color(0.82, 0.22, 0.2),
		Color(0.96, 0.3, 0.28),
		Color(1.0, 0.45, 0.4, 0.6)
	)
	replay_btn.pressed.connect(_on_replay_pressed)
	buttons_box.add_child(replay_btn)

	var home_btn := RUN_SUMMARY.create_styled_button(
		"🏠  MÀN HÌNH CHÍNH",
		Color(0.12, 0.15, 0.22, 0.95),
		Color(0.2, 0.25, 0.35, 1.0),
		Color(0.35, 0.42, 0.58, 0.8)
	)
	home_btn.pressed.connect(_on_home_pressed)
	buttons_box.add_child(home_btn)

	# --- SMOOTH ENTRY POPUP TWEEN ---
	panel.pivot_offset = Vector2(265, 200)
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)

func _on_replay_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")