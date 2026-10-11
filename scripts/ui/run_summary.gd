extends RefCounted

const TEXT_PRIMARY := Color(0.95, 0.95, 1.0)
const TEXT_MUTED := Color(0.62, 0.67, 0.77)

static func create_panel() -> PanelContainer:
	var stats: Dictionary = GameData.current_run_stats
	var upgrades: Array = stats.get("upgrades", [])
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.045, 0.075, 0.98)
	panel_style.border_color = Color(0.3, 0.34, 0.48, 0.9)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_right = 12.0
	panel_style.content_margin_top = 11.0
	panel_style.content_margin_bottom = 11.0
	panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var heading := Label.new()
	heading.text = "TỔNG KẾT LƯỢT CHƠI"
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", Color(1.0, 0.82, 0.36))
	content.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "Dấu ấn của bạn trong trận chiến này"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", TEXT_MUTED)
	content.add_child(subtitle)

	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 2.0
	divider.color = Color(0.7, 0.52, 0.2, 0.8)
	content.add_child(divider)

	var total_seconds := maxi(0, int(float(stats.get("time_seconds", 0.0))))
	var stat_items: Array[Dictionary] = [
		{"label": "THỜI GIAN", "value": "%02d:%02d" % [floori(total_seconds / 60.0), total_seconds % 60], "color": Color(0.47, 0.76, 1.0)},
		{"label": "HẠ QUÁI", "value": _format_number(int(stats.get("kills", 0))), "color": Color(0.44, 0.91, 0.65)},
		{"label": "SÁT THƯƠNG GÂY", "value": _format_number(int(stats.get("damage_dealt", 0))), "color": Color(1.0, 0.69, 0.34)},
		{"label": "SÁT THƯƠNG NHẬN", "value": _format_number(int(stats.get("damage_received", 0))), "color": Color(1.0, 0.43, 0.43)},
		{"label": "VÀNG NHẶT", "value": _format_number(int(stats.get("gold_collected", 0))), "color": Color(1.0, 0.84, 0.36)},
		{"label": "NÂNG CẤP", "value": str(upgrades.size()), "color": Color(0.78, 0.63, 1.0)}
	]
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	content.add_child(grid)

	for item in stat_items:
		grid.add_child(_create_stat_card(item["label"], item["value"], item["color"]))

	var upgrades_header := HBoxContainer.new()
	upgrades_header.add_theme_constant_override("separation", 8)
	content.add_child(upgrades_header)

	var upgrades_heading := _create_label("NÂNG CẤP ĐÃ CHỌN", TEXT_PRIMARY, 11)
	upgrades_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_header.add_child(upgrades_heading)

	var count_label := _create_label("%d lựa chọn" % upgrades.size(), TEXT_MUTED, 10)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	upgrades_header.add_child(count_label)

	var upgrades_scroll := ScrollContainer.new()
	upgrades_scroll.custom_minimum_size = Vector2(0, 48)
	upgrades_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(upgrades_scroll)

	var upgrades_list := VBoxContainer.new()
	upgrades_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_list.add_theme_constant_override("separation", 3)
	upgrades_scroll.add_child(upgrades_list)
	if upgrades.is_empty():
		upgrades_list.add_child(_create_label("Chưa chọn nâng cấp trong lượt này", TEXT_MUTED, 11))
	else:
		for upgrade in upgrades:
			var upgrade_label := _create_label("•  %s" % str(upgrade), TEXT_MUTED, 11)
			upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			upgrade_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			upgrades_list.add_child(upgrade_label)

	return panel

static func _create_stat_card(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(132, 57)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.09)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	card.add_theme_stylebox_override("panel", style)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 2)
	card.add_child(stack)

	var name_label := _create_label(label_text, TEXT_MUTED, 9)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(name_label)

	var value_label := _create_label(value_text, accent, 19)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(value_label)
	return card

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
