extends PanelContainer
class_name QuestTracker

var kill_count: int = 0
var kill_goal: int = 10
var gold_collected: int = 0
var gold_goal: int = 30
var boss_killed: bool = false
var reward_claimed: bool = false

var label_kills: Label
var label_gold: Label
var label_boss: Label
var banner_label: Label

func _ready() -> void:
	add_to_group("quest_manager")
	
	match GameData.selected_map_id:
		"map_1":
			kill_goal = 10
		"map_2":
			kill_goal = 15
		"map_3":
			kill_goal = 20
		_:
			kill_goal = 25

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
	title.text = "NHIỆM VỤ MÀN CHƠI"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	vbox.add_child(title)
	
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

func record_kill() -> void:
	if kill_count >= kill_goal:
		return
	kill_count += 1
	_update_labels()
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
	if not reward_claimed and kill_count >= kill_goal and gold_collected >= gold_goal and boss_killed:
		reward_claimed = true
		banner_label.visible = true
		GameData.add_gold(100)
