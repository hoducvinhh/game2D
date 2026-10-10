extends Control

@onready var progress_bar: ProgressBar = $%LoadingBar
@onready var play_button: TextureButton = $%PlayButton
@onready var settings_button: TextureButton = $%SettingsButton
@onready var quit_button: TextureButton = $%QuitButton
@onready var history_button: Button = $CanvasLayer/HistoryButton
@onready var history_canvas: CanvasLayer = $CanvasLayer
var history_overlay: ColorRect
var history_list: VBoxContainer

func _ready() -> void:
	# Kết nối tín hiệu sự kiện nút bấm
	_set_button_click_mask(play_button)
	_set_button_click_mask(settings_button)
	_set_button_click_mask(quit_button)
	_style_menu_button(history_button, Color(0.72, 0.49, 0.15), Color(0.91, 0.68, 0.25))
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	history_button.pressed.connect(_show_history)
	_build_history_ui()
	_create_story_button()
	_create_shop_button()
	
	# Khóa nút Play và chạy thanh Loading giả lập khi khởi động
	play_button.disabled = true
	if progress_bar:
		progress_bar.value = 0
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", 100, 1.5)
		tween.finished.connect(_on_loading_complete)

func _set_button_click_mask(button: TextureButton) -> void:
	var click_mask := BitMap.new()
	click_mask.create_from_image_alpha(button.texture_normal.get_image())
	button.texture_click_mask = click_mask

func _create_story_button() -> void:
	var story_button := Button.new()
	story_button.text = "CỐT TRUYỆN"
	if history_button:
		story_button.position = Vector2(history_button.position.x, history_button.position.y + 54)
	else:
		story_button.position = Vector2(23, 110)
	_style_menu_button(story_button, Color(0.72, 0.49, 0.15), Color(0.91, 0.68, 0.25))
	story_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/levels/story_prologue.tscn"))
	$CanvasLayer.add_child(story_button)

func _create_shop_button() -> void:
	var shop_button := Button.new()
	shop_button.text = "SHOP"
	if history_button:
		shop_button.position = Vector2(history_button.position.x, history_button.position.y + 108)
	else:
		shop_button.position = Vector2(23, 164)
	_style_menu_button(shop_button, Color(0.19, 0.38, 0.35), Color(0.24, 0.52, 0.45))
	shop_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/levels/talents_shop.tscn"))
	$CanvasLayer.add_child(shop_button)

func _style_menu_button(button: Button, base_color: Color, hover_color: Color) -> void:
	button.custom_minimum_size = Vector2(190, 46)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.88, 0.57))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.035, 0.045, 0.9)
	normal.border_color = base_color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.border_color = Color(1.0, 0.87, 0.55)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(9)
	hover.content_margin_left = 18
	hover.content_margin_right = 18
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", normal)


func _on_loading_complete() -> void:
	play_button.disabled = false
	if progress_bar:
		progress_bar.hide() # Ẩn thanh loading sau khi tải xong

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/character_lobby.tscn")

func _on_settings_pressed() -> void:
	GameData.settings_return_scene = "res://scenes/levels/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _build_history_ui() -> void:
	history_overlay = ColorRect.new()
	history_overlay.color = Color(0.015, 0.02, 0.025, 0.82)
	history_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	history_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	history_overlay.hide()
	history_canvas.add_child(history_overlay)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 540)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(760, 540)
	panel.position = Vector2(-380, -270)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.055, 0.07, 0.98)
	panel_style.border_color = Color(0.83, 0.67, 0.32, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.shadow_color = Color(0, 0, 0, 0.45)
	panel_style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	history_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	content.add_child(header)

	var title := Label.new()
	title.text = "NHẬT KÝ HÀNH TRÌNH"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "ĐÓNG"
	close_button.custom_minimum_size = Vector2(96, 40)
	close_button.add_theme_font_size_override("font_size", 15)
	_style_history_button(close_button)
	close_button.pressed.connect(_close_history)
	header.add_child(close_button)

	var subtitle := Label.new()
	subtitle.text = "Những trận đấu đã hoàn thành và thành tựu của bạn"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.72, 0.75))
	content.add_child(subtitle)

	var separator := HSeparator.new()
	content.add_child(separator)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	history_list = VBoxContainer.new()
	history_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_list.add_theme_constant_override("separation", 8)
	scroll.add_child(history_list)

func _style_history_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.14, 0.11)
	normal.border_color = Color(0.78, 0.62, 0.3)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.28, 0.23, 0.14)
	hover.border_color = Color(1.0, 0.84, 0.43)
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(8)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

func _show_history() -> void:
	_refresh_history()
	history_overlay.show()
	history_overlay.move_to_front()
	history_button.hide()

func _close_history() -> void:
	history_overlay.hide()
	history_button.show()

func _refresh_history() -> void:
	for child in history_list.get_children():
		child.queue_free()

	if GameData.completed_runs.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Chưa có trận đấu nào được ghi lại.\nHãy vào trận và tạo nên hành trình đầu tiên!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 17)
		empty_label.add_theme_color_override("font_color", Color(0.78, 0.8, 0.82))
		empty_label.custom_minimum_size = Vector2(0, 72)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_add_history_card(empty_label)
	else:
		for index in GameData.completed_runs.size():
			var run: Dictionary = GameData.completed_runs[index]
			var map_data: Dictionary = GameData.MAPS[run["map_id"]]
			var difficulty_data: Dictionary = GameData.DIFFICULTIES[run["difficulty_id"]]
			var completed_at := Time.get_datetime_string_from_unix_time(int(run.get("completed_at", 0)), true)
			var row := Label.new()
			row.text = "%02d  %s\n       %s  ·  %d giây  ·  %s" % [
				index + 1,
				map_data.get("name", run["map_id"]),
				difficulty_data.get("name", run["difficulty_id"]),
				int(run.get("survival_seconds", 0)),
				completed_at
			]
			row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_theme_font_size_override("font_size", 15)
			row.add_theme_color_override("font_color", Color(0.92, 0.91, 0.86))
			_add_history_card(row)

	var achievements_heading := Label.new()
	achievements_heading.text = "THÀNH TỰU"
	achievements_heading.add_theme_font_size_override("font_size", 20)
	achievements_heading.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))
	history_list.add_child(achievements_heading)
	var unlocked: Array = GameData.achievement_progress.get("unlocked", [])
	var completed_maps: Array = GameData.achievement_progress.get("completed_maps", [])
	for achievement_id in GameData.ACHIEVEMENTS:
		var info: Dictionary = GameData.ACHIEVEMENTS[achievement_id]
		var unlocked_now := unlocked.has(achievement_id)
		var progress := 0
		match achievement_id:
			"first_blood":
				progress = int(GameData.achievement_progress.get("kills", 0))
			"gold_collector":
				progress = int(GameData.achievement_progress.get("gold", 0))
			"map_veteran":
				progress = completed_maps.size()
			"boss_slayer", "evolutionist", "super_hard_clear":
				progress = 1 if unlocked_now else 0
		var achievement_row := VBoxContainer.new()
		achievement_row.add_theme_constant_override("separation", 4)
		var achievement_title := Label.new()
		achievement_title.text = "%s  %s  ·  %d/%d  ·  Thưởng %d vàng" % [
			"ĐÃ MỞ" if unlocked_now else "ĐANG TIẾN HÀNH",
			info["name"],
			min(progress, int(info["target"])),
			int(info["target"]),
			int(info["reward"])
		]
		achievement_title.add_theme_font_size_override("font_size", 15)
		achievement_title.add_theme_color_override("font_color", Color(0.67, 0.93, 0.67) if unlocked_now else Color(0.92, 0.88, 0.76))
		achievement_row.add_child(achievement_title)
		var description := Label.new()
		description.text = info["description"]
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 13)
		description.add_theme_color_override("font_color", Color(0.7, 0.74, 0.77))
		achievement_row.add_child(description)
		_add_history_card(achievement_row)

func _add_history_card(content: Control) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.105, 0.12, 0.95)
	style.border_color = Color(0.34, 0.31, 0.23, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	card.add_child(content)
	history_list.add_child(card)
