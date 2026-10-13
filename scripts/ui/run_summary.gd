extends RefCounted

const TEXT_PRIMARY := Color(0.96, 0.96, 1.0)
const TEXT_MUTED := Color(0.65, 0.7, 0.8)
const TEXT_GOLD := Color(1.0, 0.86, 0.35)

static func create_panel() -> PanelContainer:
	var stats: Dictionary = GameData.current_run_stats
	var upgrades: Array = stats.get("upgrades", [])
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(490, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.048, 0.078, 0.95)
	panel_style.border_color = Color(0.24, 0.28, 0.42, 0.75)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 14.0
	panel_style.content_margin_right = 14.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	# --- HEADER VỚI TIÊU ĐỀ & HUY HIỆU XẾP HẠNG (RANK) ---
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var heading := Label.new()
	heading.text = "THỐNG KÊ CHIẾN TÍCH"
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", TEXT_GOLD)
	title_box.add_child(heading)

	var total_seconds := maxi(0, int(float(stats.get("time_seconds", 0.0))))
	var kills := int(stats.get("kills", 0))

	# Tên nhân vật & độ khó
	var char_name := "Lil' Boy Tộc Trưởng"
	if GameData.CHARACTERS.has(GameData.selected_character_id):
		char_name = GameData.CHARACTERS[GameData.selected_character_id].get("name", "Chiến Binh")
	var subtitle := Label.new()
	subtitle.text = "%s  •  Độ khó: %s" % [char_name, GameData.selected_difficulty_id.capitalize()]
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", TEXT_MUTED)
	title_box.add_child(subtitle)

	# Đánh giá xếp hạng dựa trên thành tích
	var rank_str := "C"
	var rank_color := Color(0.75, 0.8, 0.9)
	if kills >= 120 or total_seconds >= 360:
		rank_str = "S"
		rank_color = Color(1.0, 0.82, 0.15) # Gold
	elif kills >= 70 or total_seconds >= 220:
		rank_str = "A"
		rank_color = Color(0.85, 0.45, 1.0) # Purple
	elif kills >= 30 or total_seconds >= 100:
		rank_str = "B"
		rank_color = Color(0.3, 0.85, 1.0) # Cyan
	
	var rank_badge := _create_rank_badge(rank_str, rank_color)
	header.add_child(rank_badge)

	# --- ĐƯỜNG PHÂN CÁCH ---
	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 2.0
	divider.color = Color(0.5, 0.4, 0.22, 0.7)
	content.add_child(divider)

	# --- LƯỚI THẺ THỐNG KÊ (3 CỘT x 2 HÀNG) ---
	var stat_items: Array[Dictionary] = [
		{"icon": "⏱️", "label": "THỜI GIAN", "value": "%02d:%02d" % [floori(total_seconds / 60.0), total_seconds % 60], "color": Color(0.38, 0.78, 1.0)},
		{"icon": "💀", "label": "HẠ QUÁI", "value": _format_number(kills), "color": Color(0.35, 0.95, 0.6)},
		{"icon": "⚔️", "label": "SÁT THƯƠNG", "value": _format_number(int(stats.get("damage_dealt", 0))), "color": Color(1.0, 0.68, 0.28)},
		{"icon": "🛡️", "label": "BỊ THƯƠNG", "value": _format_number(int(stats.get("damage_received", 0))), "color": Color(1.0, 0.44, 0.44)},
		{"icon": "💰", "label": "VÀNG NHẶT", "value": _format_number(int(stats.get("gold_collected", 0))), "color": Color(1.0, 0.86, 0.32)},
		{"icon": "🎒", "label": "NÂNG CẤP", "value": str(upgrades.size()), "color": Color(0.82, 0.58, 1.0)}
	]

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	for item in stat_items:
		grid.add_child(_create_stat_card(item["icon"], item["label"], item["value"], item["color"]))

	# --- DANH SÁCH NÂNG CẤP ĐÃ CHỌN ---
	var upgrades_header := HBoxContainer.new()
	upgrades_header.add_theme_constant_override("separation", 6)
	content.add_child(upgrades_header)

	var upgrades_heading := _create_label("✦ KỸ NĂNG & TRANG BỊ", TEXT_PRIMARY, 11)
	upgrades_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_header.add_child(upgrades_heading)

	var count_label := _create_label("%d đã chọn" % upgrades.size(), TEXT_MUTED, 10)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	upgrades_header.add_child(count_label)

	var upgrades_scroll := ScrollContainer.new()
	upgrades_scroll.custom_minimum_size = Vector2(0, 60)
	upgrades_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(upgrades_scroll)

	var upgrades_list := VBoxContainer.new()
	upgrades_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_list.add_theme_constant_override("separation", 4)
	upgrades_scroll.add_child(upgrades_list)

	if upgrades.is_empty():
		var empty_lbl := _create_label("Chưa chọn nâng cấp nào trong lượt này", TEXT_MUTED, 11)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		upgrades_list.add_child(empty_lbl)
	else:
		for upgrade in upgrades:
			var pill := _create_upgrade_pill(str(upgrade))
			upgrades_list.add_child(pill)

	return panel

static func _create_rank_badge(rank_letter: String, color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.16)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	badge.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = "HẠNG " + rank_letter
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	badge.add_child(lbl)
	return badge

static func _create_stat_card(icon: String, label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(146, 56)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.08)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	card.add_theme_stylebox_override("panel", style)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	card.add_child(stack)

	var name_label := _create_label("%s %s" % [icon, label_text], Color(accent.r, accent.g, accent.b, 0.85), 9)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(name_label)

	var value_label := _create_label(value_text, accent, 18)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(value_label)
	return card

static func _create_upgrade_pill(text: String) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.8)
	style.border_color = Color(0.25, 0.3, 0.42, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	pill.add_theme_stylebox_override("panel", style)

	var lbl := _create_label("• " + text, TEXT_PRIMARY, 11)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pill.add_child(lbl)
	return pill

static func _create_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

static func _format_number(value: int) -> String:
	var digits := str(value)
	var formatted := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			formatted += "."
		formatted += digits[index]
	return formatted

static func create_styled_button(text: String, bg_normal: Color, bg_hover: Color, border_color: Color = Color.TRANSPARENT, font_color: Color = Color.WHITE) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = bg_normal
	normal_style.set_corner_radius_all(8)
	if border_color != Color.TRANSPARENT:
		normal_style.border_color = border_color
		normal_style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = bg_hover
	hover_style.set_corner_radius_all(8)
	if border_color != Color.TRANSPARENT:
		hover_style.border_color = border_color.lightened(0.2)
		hover_style.set_border_width_all(1)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = bg_normal.darkened(0.2)
	pressed_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	return btn

# --- BẮN PHÁO HOA ĐA SẮC TUNG TÓE KHẮP MÀN HÌNH ---
static func launch_firework_burst(parent: Node, pos: Vector2, count: int = 45) -> void:
	if not is_instance_valid(parent):
		return
		
	var burst := CPUParticles2D.new()
	burst.name = "FireworkBurst"
	burst.position = pos
	burst.amount = count
	burst.lifetime = 1.25 # Kéo dài thời gian tồn tại để tàn pháo hoa lấp lánh lâu hơn
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.lifetime_randomness = 0.4
	burst.direction = Vector2.ZERO
	burst.spread = 180.0
	burst.gravity = Vector2(0, 95.0) # Trọng lực nhẹ để hạt pháo bay lượn tự nhiên
	burst.initial_velocity_min = 170.0
	burst.initial_velocity_max = 350.0
	burst.damping_min = 90.0
	burst.damping_max = 160.0
	burst.scale_amount_min = 3.5
	burst.scale_amount_max = 7.0

	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.7, 0.85))
	scale_curve.add_point(Vector2(1.0, 0.0))
	burst.scale_amount_curve = scale_curve

	var rainbow_grad := Gradient.new()
	rainbow_grad.colors = PackedColorArray([
		Color(1.0, 0.2, 0.25),  # Crimson Red
		Color(1.0, 0.6, 0.05),  # Orange
		Color(1.0, 0.95, 0.15), # Bright Yellow
		Color(0.2, 1.0, 0.35),  # Neon Lime
		Color(0.1, 0.9, 1.0),   # Electric Cyan
		Color(0.35, 0.45, 1.0), # Royal Blue
		Color(1.0, 0.2, 0.85)   # Hot Pink
	])
	rainbow_grad.offsets = PackedFloat32Array([0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0])
	burst.color_initial_ramp = rainbow_grad

	var fade_grad := Gradient.new()
	fade_grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	fade_grad.offsets = PackedFloat32Array([0.0, 0.75, 1.0])
	burst.color_ramp = fade_grad

	parent.add_child(burst)
	burst.emitting = true

	# Tự động giải phóng node pháo hoa sau khi tàn pháo tắt hẳn
	var tree := parent.get_tree()
	if tree:
		tree.create_timer(1.5).timeout.connect(func():
			if is_instance_valid(burst):
				burst.queue_free()
		)

# --- VÒNG LẶP BẮN PHÁO HOA LIÊN TỤC KHÔNG DỨT ĐẾN KHI RỜI MÀN HÌNH ---
static func start_continuous_fireworks(parent_node: CanvasLayer, holder: Node2D, interval: float = 0.5) -> Timer:
	if not is_instance_valid(parent_node) or not is_instance_valid(holder):
		return null
		
	var timer := Timer.new()
	timer.name = "ContinuousFireworksTimer"
	timer.process_mode = Node.PROCESS_MODE_ALWAYS # Hoạt động xuyên suốt cả khi game đang pause
	timer.wait_time = interval
	timer.autostart = true
	timer.one_shot = false
	
	timer.timeout.connect(func():
		if is_instance_valid(parent_node) and is_instance_valid(holder):
			var vp := parent_node.get_viewport().get_visible_rect().size
			# Mỗi nhịp nổ 1-2 chùm pháo hoa tại các tọa độ ngẫu nhiên khắp bầu trời
			var count := randi_range(1, 2)
			for i in range(count):
				var rand_pos := Vector2(
					randf_range(vp.x * 0.1, vp.x * 0.9),
					randf_range(vp.y * 0.12, vp.y * 0.65)
				)
				launch_firework_burst(holder, rand_pos, randi_range(38, 50))
	)
	
	parent_node.add_child(timer)
	return timer
