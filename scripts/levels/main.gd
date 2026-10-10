extends Node2D

@onready var player: CharacterBody2D = $CharacterBody2D/Player # Hoặc $Player tùy cây node của bạn
@onready var level_up_menu: Control = $CanvasLayer/LevelUpMenu
@onready var gold_label: Label = $CanvasLayer/GoldLabel
var weapons_row: HBoxContainer
var weapon_slots: Dictionary = {}
var map_hazard: Node2D

const WEAPON_HUD_ITEMS := [
	{"id": "Sugarcane", "name": "Bã mía", "icon": "res://assets/sprites/weapons/sugarcane/sugarcane.png"},
	{"id": "Shisa", "name": "Shisa", "icon": "res://assets/sprites/weapons/shisa/shisa.png"},
	{"id": "Chay", "name": "Cái chày", "icon": "res://assets/sprites/weapons/bat/bat.png"},
	{"id": "Shield", "name": "Khiên", "icon": "res://assets/sprites/weapons/shield/shield.png"},
	{"id": "Phone", "name": "Điện thoại", "icon": "res://assets/sprites/weapons/phone/phone1.png"}
]

func _ready() -> void:
	_apply_selected_map()
	_update_gold_label(GameData.gold)
	GameData.gold_changed.connect(_update_gold_label)

	# Tìm lại player nếu đường dẫn phía trên bị lệch
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	if player and level_up_menu:
		player.player_leveled_up.connect(_on_player_leveled_up)
		player.weapons_changed.connect(_refresh_weapons_hud)
		level_up_menu.upgrade_selected.connect(_on_upgrade_selected)
	_create_weapons_hud()
	_refresh_weapons_hud()
	_create_enemy_minimap()
	_create_quest_tracker()

func _process(_delta: float) -> void:
	_update_weapon_cooldowns()

func _create_quest_tracker() -> void:
	var tracker = preload("res://scripts/ui/quest_tracker.gd").new()
	tracker.position = Vector2(900, 75)
	$CanvasLayer.add_child(tracker)
	$Node2D/EnemySpawner.call("bind_quest_tracker", tracker)

func _create_enemy_minimap() -> void:
	var minimap = preload("res://scripts/ui/enemy_minimap.gd").new()
	minimap.position = Vector2(14.0, 70.0)
	minimap.player = player
	$CanvasLayer.add_child(minimap)

func _start_map_hazards() -> void:
	if is_instance_valid(map_hazard):
		map_hazard.queue_free()
	var map_id: String = GameData.current_run_map_id if not GameData.current_run_map_id.is_empty() else GameData.selected_map_id
	var map_data: Dictionary = GameData.MAPS.get(map_id, GameData.MAPS["map_1"])
	var hazard := preload("res://scripts/levels/map_hazards.gd").new()
	hazard.name = "MapHazards"
	hazard.hazard_type = map_data.get("hazard", "none")
	hazard.player = player if is_instance_valid(player) else get_tree().get_first_node_in_group("player")
	add_child(hazard)
	map_hazard = hazard

func apply_run_map(map_id: String) -> void:
	if not GameData.MAPS.has(map_id):
		push_error("Cannot apply unknown run map: %s" % map_id)
		return
	GameData.current_run_map_id = map_id
	_apply_selected_map()
	_start_map_hazards()


func _create_weapons_hud() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -124.0
	panel.offset_right = 124.0
	panel.offset_top = -58.0
	panel.offset_bottom = -6.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.035, 0.04, 0.82)
	panel_style.border_color = Color(0.72, 0.62, 0.38, 0.9)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 4
	panel_style.content_margin_top = 3
	panel_style.content_margin_right = 4
	panel_style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", panel_style)
	$CanvasLayer.add_child(panel)

	weapons_row = HBoxContainer.new()
	weapons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	weapons_row.add_theme_constant_override("separation", 4)
	panel.add_child(weapons_row)

func _refresh_weapons_hud() -> void:
	if not weapons_row or not player:
		return
	for item in weapons_row.get_children():
		weapons_row.remove_child(item)
		item.queue_free()
	weapon_slots.clear()

	var player_weapons: Node = player.get_node_or_null("Weapons")
	if not player_weapons:
		return
	for weapon_info in WEAPON_HUD_ITEMS:
		var weapon: Node = player_weapons.get_node_or_null(weapon_info["id"])
		if not weapon:
			continue
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(38, 38)
		slot.tooltip_text = weapon_info["name"]
		weapons_row.add_child(slot)

		var button := Button.new()
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_theme_constant_override("icon_max_width", 26)
		button.icon = load(weapon_info["icon"]) as Texture2D
		button.expand_icon = true
		button.tooltip_text = "%s — chọn, nhấn Đánh/J để dùng; nhấn lại để bỏ chọn" % weapon_info["name"]
		button.pressed.connect(_on_weapon_button_pressed.bind(weapon_info["id"]))
		slot.add_child(button)

		var cooldown_overlay := ColorRect.new()
		cooldown_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cooldown_overlay.color = Color(0.02, 0.02, 0.025, 0.68)
		cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldown_overlay.visible = false
		button.add_child(cooldown_overlay)

		var cooldown_label := Label.new()
		cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cooldown_label.add_theme_font_size_override("font_size", 15)
		cooldown_label.add_theme_color_override("font_color", Color.WHITE)
		cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldown_label.visible = false
		button.add_child(cooldown_label)

		var selected_mark := Label.new()
		selected_mark.anchor_left = 1.0
		selected_mark.anchor_right = 1.0
		selected_mark.offset_left = -13.0
		selected_mark.offset_right = -1.0
		selected_mark.offset_top = 0.0
		selected_mark.offset_bottom = 12.0
		selected_mark.text = "✓"
		selected_mark.add_theme_font_size_override("font_size", 10)
		selected_mark.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
		selected_mark.add_theme_color_override("font_shadow_color", Color.BLACK)
		selected_mark.add_theme_constant_override("shadow_offset_x", 1)
		selected_mark.add_theme_constant_override("shadow_offset_y", 1)
		selected_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(selected_mark)

		var level_label := Label.new()
		level_label.anchor_left = 0.0
		level_label.anchor_right = 1.0
		level_label.anchor_top = 1.0
		level_label.anchor_bottom = 1.0
		level_label.offset_top = -12.0
		level_label.offset_bottom = -1.0
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_font_size_override("font_size", 8)
		level_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.75))
		level_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		level_label.add_theme_constant_override("shadow_offset_x", 1)
		level_label.add_theme_constant_override("shadow_offset_y", 1)
		level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(level_label)

		weapon_slots[weapon_info["id"]] = {
			"weapon": weapon,
			"button": button,
			"overlay": cooldown_overlay,
			"cooldown_label": cooldown_label,
			"level_label": level_label,
			"selected_mark": selected_mark,
			"selected": false
		}
	_set_weapon_selection(str(player.get("selected_weapon_id")))

func _on_weapon_button_pressed(weapon_id: String) -> void:
	var slot: Dictionary = weapon_slots.get(weapon_id, {})
	var weapon: Node = slot.get("weapon")
	if is_instance_valid(weapon) and player.has_method("select_weapon"):
		player.call("select_weapon", weapon_id)
		_set_weapon_selection(weapon_id)

func _set_weapon_selection(selected_weapon_id: String) -> void:
	for id in weapon_slots:
		var slot: Dictionary = weapon_slots[id]
		var selected: bool = str(id) == selected_weapon_id
		slot["selected"] = selected
		slot["selected_mark"].visible = selected
		var button: Button = slot["button"]
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.28, 0.22, 0.08, 0.96) if selected else Color(0.08, 0.08, 0.09, 0.88)
		style.border_color = Color(1.0, 0.82, 0.18, 1.0) if selected else Color(0.62, 0.62, 0.62, 0.8)
		style.set_border_width_all(2 if selected else 1)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
	_update_weapon_cooldowns()

func _update_weapon_cooldowns() -> void:
	for weapon_id in weapon_slots:
		var slot: Dictionary = weapon_slots[weapon_id]
		var weapon: Node = slot["weapon"]
		if not is_instance_valid(weapon):
			continue
		var remaining := float(weapon.get("cooldown_remaining"))
		var button: Button = slot["button"]
		var overlay: ColorRect = slot["overlay"]
		var cooldown_label: Label = slot["cooldown_label"]
		var level_label: Label = slot["level_label"]
		button.disabled = false
		overlay.visible = remaining > 0.0
		cooldown_label.visible = remaining > 0.0
		cooldown_label.text = str(ceili(remaining)) if remaining > 0.0 else ""
		level_label.text = "EVO" if bool(weapon.get("is_evolved")) else "Lv.%d" % int(weapon.get("level"))

func _on_player_leveled_up(current_level: int) -> void:
	level_up_menu.show_options(current_level)

func _on_upgrade_selected(chosen_data: Dictionary) -> void:
	if player:
		player.apply_upgrade(chosen_data)

func _update_gold_label(total_gold: int) -> void:
	gold_label.text = "Vàng: %d" % total_gold

func _apply_selected_map() -> void:
	var map_id: String = GameData.current_run_map_id if not GameData.current_run_map_id.is_empty() else GameData.selected_map_id
	var map_data: Dictionary = GameData.MAPS.get(map_id, GameData.MAPS["map_1"])
	var background_path: String = map_data.get("background_path", "")
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		return

	var source_texture := load(background_path) as Texture2D
	if not source_texture:
		return

	var target_size := Vector2(640.0, 480.0)
	var source_size := source_texture.get_size()
	var crop_size := source_size
	var target_ratio := target_size.x / target_size.y
	if source_size.x / source_size.y > target_ratio:
		crop_size.x = source_size.y * target_ratio
	else:
		crop_size.y = source_size.x / target_ratio

	var atlas := AtlasTexture.new()
	atlas.atlas = source_texture
	atlas.region = Rect2((source_size - crop_size) * 0.5, crop_size)
	var background: Sprite2D = $Parallax2D/Sprite2D
	background.texture = atlas
	background.scale = target_size / crop_size
