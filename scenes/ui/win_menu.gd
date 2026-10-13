extends CanvasLayer

const WIN_SOUND: AudioStream = preload("res://assets/music/win.mp3")
const RUN_SUMMARY = preload("res://scripts/ui/run_summary.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_sound(WIN_SOUND)
	get_tree().paused = true

	# Dọn dẹp bất kỳ node con cũ nào trong scene tscn nếu có
	for child in get_children():
		child.queue_free()

	# --- VIGNETTE / BACKDROP ---
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.06, 0.86)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# --- LỚP PHÁO HOA TUNG TÓE KHẮP MÀN HÌNH (DƯỚI BẢNG MENU) ---
	var fireworks_holder := Node2D.new()
	add_child(fireworks_holder)

	var vp_size := get_viewport().get_visible_rect().size
	# Đợt bắn pháo hoa đầu tiên chào mừng chiến thắng ở các góc màn hình
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.18, vp_size.y * 0.22), 50)
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.82, vp_size.y * 0.2), 50)
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.5, vp_size.y * 0.14), 55)
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.25, vp_size.y * 0.42), 42)
	RUN_SUMMARY.launch_firework_burst(fireworks_holder, Vector2(vp_size.x * 0.75, vp_size.y * 0.4), 42)

	# Bắn pháo hoa liên tục không dứt theo chu kỳ mỗi 0.45 giây khắp màn hình cho đến khi người chơi thoát
	RUN_SUMMARY.start_continuous_fireworks(self, fireworks_holder, 0.45)

	# --- LỚP PHÁO GIẤY / KIM TUYẾN ĂN MỪNG RƠI CHẬM ---
	var confetti := CPUParticles2D.new()
	confetti.name = "VictoryConfetti"
	confetti.position = Vector2(vp_size.x * 0.5, -15.0)
	confetti.amount = 50
	confetti.lifetime = 3.5
	confetti.explosiveness = 0.15
	confetti.lifetime_randomness = 0.35
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(vp_size.x * 0.65, 10.0)
	confetti.direction = Vector2(0, 1)
	confetti.spread = 30.0
	confetti.gravity = Vector2(0, 80.0)
	confetti.initial_velocity_min = 100.0
	confetti.initial_velocity_max = 220.0
	confetti.damping_min = 25.0
	confetti.damping_max = 50.0
	confetti.scale_amount_min = 3.5
	confetti.scale_amount_max = 6.5
	
	var rainbow_grad := Gradient.new()
	rainbow_grad.colors = PackedColorArray([
		Color(1.0, 0.85, 0.2), # Gold
		Color(1.0, 0.3, 0.4),  # Coral
		Color(0.2, 0.9, 1.0),  # Cyan
		Color(0.3, 1.0, 0.5),  # Lime
		Color(1.0, 0.5, 0.9)   # Pink
	])
	rainbow_grad.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	confetti.color_initial_ramp = rainbow_grad
	add_child(confetti)
	confetti.emitting = true

	# --- CENTER WRAPPER ---
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# --- MAIN DIALOG PANEL ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(530, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.05, 0.08, 0.98)
	panel_style.border_color = Color(1.0, 0.82, 0.24, 0.95) # Gold border
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(1.0, 0.75, 0.15, 0.28)
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

	var crown_icon := Label.new()
	crown_icon.text = "👑  🏆  👑"
	crown_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crown_icon.add_theme_font_size_override("font_size", 24)
	header_vbox.add_child(crown_icon)

	var title := Label.new()
	title.text = "CHIẾN THẮNG HUY HOÀNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25))
	title.add_theme_color_override("font_outline_color", Color(0.45, 0.3, 0.05))
	title.add_theme_constant_override("outline_size", 5)
	header_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Chúc mừng! Bạn đã sinh tồn và tiêu diệt trùm cuối thành công!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	header_vbox.add_child(subtitle)

	# --- SUMMARY PANEL ---
	content.add_child(RUN_SUMMARY.create_panel())

	# --- ACTION BUTTONS (3 BUTTONS) ---
	var buttons_box := HBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 10)
	content.add_child(buttons_box)

	var replay_btn := RUN_SUMMARY.create_styled_button(
		"🔄  CHƠI LƯỢT MỚI",
		Color(0.92, 0.72, 0.15),
		Color(1.0, 0.82, 0.22),
		Color(1.0, 0.9, 0.4, 0.8),
		Color(0.12, 0.09, 0.02)
	)
	replay_btn.pressed.connect(_on_replay_pressed)
	buttons_box.add_child(replay_btn)

	var home_btn := RUN_SUMMARY.create_styled_button(
		"🏠  TRANG CHỦ",
		Color(0.12, 0.15, 0.22, 0.95),
		Color(0.2, 0.25, 0.35, 1.0),
		Color(0.45, 0.4, 0.25, 0.8)
	)
	home_btn.pressed.connect(_on_home_pressed)
	buttons_box.add_child(home_btn)

	var settings_btn := RUN_SUMMARY.create_styled_button(
		"⚙️  CÀI ĐẶT",
		Color(0.12, 0.14, 0.18, 0.9),
		Color(0.18, 0.2, 0.26, 1.0),
		Color(0.3, 0.35, 0.45, 0.6)
	)
	settings_btn.pressed.connect(_on_settings_pressed)
	buttons_box.add_child(settings_btn)

	# --- SMOOTH ENTRY POPUP TWEEN ---
	panel.pivot_offset = Vector2(265, 200)
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.28)

func _on_replay_pressed() -> void:
	get_tree().paused = false
	GameData.start_random_run()
	get_tree().reload_current_scene()

func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")

func _on_settings_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")
