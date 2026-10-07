extends PanelContainer
class_name QuestTracker

var kill_count: int = 0
var total_kill_count: int = 0
var kill_goal: int = 10
var gold_collected: int = 0
var gold_goal: int = 30
var boss_killed: bool = false
var reward_claimed: bool = false
var stage_is_complete: bool = false

signal stage_completed
signal continue_requested(should_continue: bool)

var label_stage: Label
var label_kills: Label
var label_gold: Label
var label_boss: Label
var banner_label: Label
var stage_completion_overlay: Control
var stage_completion_message: Label

func _ready() -> void:
	add_to_group("quest_manager")

	if GameData.selected_difficulty_id == "easy":
		gold_goal = 20
	elif GameData.selected_difficulty_id == "super_hard":
		gold_goal = 45
	elif GameData.selected_difficulty_id == "hard":
		gold_goal = 30

	_setup_ui()
	_update_labels()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(240, 95)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 0.8)
	style.border_color = Color(0.9, 0.75, 0.3, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "NHIỆM VỤ HÀNH TRÌNH"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	vbox.add_child(title)

	label_stage = Label.new()
	label_stage.add_theme_font_size_override("font_size", 11)
	vbox.add_child(label_stage)
	
	label_kills = Label.new()
	label_kills.add_theme_font_size_override("font_size", 11)
	vbox.add_child(label_kills)
	
	label_gold = Label.new()
	label_gold.add_theme_font_size_override("font_size", 11)
	vbox.add_child(label_gold)
	
	label_boss = Label.new()
	label_boss.add_theme_font_size_override("font_size", 11)
	vbox.add_child(label_boss)
	
	banner_label = Label.new()
	banner_label.text = "🎉 HOÀN THÀNH TẤT CẢ! (+100 VÀNG)"
	banner_label.add_theme_font_size_override("font_size", 11)
	banner_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	banner_label.visible = false
	vbox.add_child(banner_label)

	_create_stage_completion_overlay()

func _create_stage_completion_overlay() -> void:
	stage_completion_overlay = Control.new()
	stage_completion_overlay.name = "StageCompletionOverlay"
	stage_completion_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	stage_completion_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stage_completion_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_completion_overlay.visible = false
	var overlay_parent := get_parent()
	overlay_parent.add_child(stage_completion_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_completion_overlay.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 190)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_top = -95
	panel.offset_right = 220
	panel.offset_bottom = 95
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.065, 0.085, 0.98)
	panel_style.border_color = Color(1.0, 0.78, 0.24)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_right = 20
	panel_style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	stage_completion_overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title := Label.new()
	title.text = "NHIỆM VỤ HOÀN THÀNH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38))
	content.add_child(title)

	stage_completion_message = Label.new()
	stage_completion_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_completion_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_completion_message.add_theme_font_size_override("font_size", 16)
	content.add_child(stage_completion_message)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	content.add_child(buttons)

	var continue_button := Button.new()
	continue_button.text = "Có, sang tiếp"
	continue_button.custom_minimum_size = Vector2(150, 42)
	continue_button.pressed.connect(_on_stage_continue_confirmed)
	buttons.add_child(continue_button)

	var quit_button := Button.new()
	quit_button.text = "Không, thoát game"
	quit_button.custom_minimum_size = Vector2(170, 42)
	quit_button.pressed.connect(_on_stage_continue_canceled)
	buttons.add_child(quit_button)

func show_stage_completion(stage_number: int, stage_total: int) -> void:
	var is_final_map := stage_number >= stage_total
	stage_completion_message.text = (
		"Map %d/%d đã hoàn thành. Bạn có muốn sang đánh Boss không?"
		% [stage_number, stage_total]
	) if is_final_map else (
		"Map %d/%d đã hoàn thành. Bạn có muốn sang map tiếp theo không?"
		% [stage_number, stage_total]
	)
	stage_completion_overlay.visible = true

func _on_stage_continue_confirmed() -> void:
	stage_completion_overlay.visible = false
	continue_requested.emit(true)

func _on_stage_continue_canceled() -> void:
	stage_completion_overlay.visible = false
	continue_requested.emit(false)

func begin_map_stage(stage_number: int, stage_total: int, map_id: String, enemy_type: String) -> void:
	kill_count = 0
	kill_goal = 10
	stage_is_complete = false
	var map_data: Dictionary = GameData.MAPS.get(map_id, {})
	var map_name: String = map_data.get("name", map_id)
	var enemy_names := {"basic": "Quái thường", "fast": "Quái nhanh", "ranged": "Quái bắn xa"}
	label_stage.text = "Map %d/%d: %s — %s" % [
		stage_number,
		stage_total,
		map_name,
		enemy_names.get(enemy_type, enemy_type)
	]
	label_stage.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_update_labels()

func begin_boss_stage() -> void:
	label_stage.text = "GIAI ĐOẠN CUỐI: CHỈ CÒN BOSS"
	label_stage.add_theme_color_override("font_color", Color(1.0, 0.55, 0.4))
	_update_labels()

func record_kill() -> void:
	if stage_is_complete:
		return
	kill_count += 1
	total_kill_count += 1
	_update_labels()
	if kill_count >= kill_goal:
		stage_is_complete = true
		stage_completed.emit()
	_check_completion()

func record_gold(amount: int) -> void:
	if gold_collected >= gold_goal or amount <= 0:
		return
	gold_collected = mini(gold_goal, gold_collected + amount)
	_update_labels()
	_check_completion()

func record_boss_killed() -> void:
	boss_killed = true
	_update_labels()
	_check_completion()

func _update_labels() -> void:
	if label_stage and label_stage.text.is_empty():
		label_stage.text = "Đang chuẩn bị hành trình..."
	if label_kills:
		var k_text = "🗡️ Diệt quái: %d / %d" % [kill_count, kill_goal]
		if kill_count >= kill_goal:
			k_text += " [XONG]"
			label_kills.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		else:
			label_kills.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		label_kills.text = k_text
		
	if label_gold:
		var g_text = "🪙 Nhặt vàng: %d / %d" % [gold_collected, gold_goal]
		if gold_collected >= gold_goal:
			g_text += " [XONG]"
			label_gold.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		else:
			label_gold.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		label_gold.text = g_text
		
	if label_boss:
		var b_text = "👑 Trùm Hư Không: " + ("ĐÃ HẠ GỤC!" if boss_killed else "Đang tới...")
		if boss_killed:
			label_boss.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		else:
			label_boss.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
		label_boss.text = b_text

func _check_completion() -> void:
	if not reward_claimed and total_kill_count >= kill_goal * GameData.MAPS.size() and gold_collected >= gold_goal and boss_killed:
		reward_claimed = true
		banner_label.visible = true
		GameData.add_gold(100)
