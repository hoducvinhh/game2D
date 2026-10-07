extends Control

const MAIN_MENU_PATH := "res://scenes/levels/main_menu.tscn"

@onready var gold_label: Label = $MarginContainer/VBoxContainer/Header/GoldLabel
@onready var items_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer
@onready var btn_back: Button = $MarginContainer/VBoxContainer/Header/BtnBack

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	GameData.gold_changed.connect(_on_gold_changed)
	_update_gold_label()
	_build_talent_items()

func _update_gold_label() -> void:
	gold_label.text = "🪙 Vàng: %d" % GameData.gold

func _on_gold_changed(_total_gold: int) -> void:
	_update_gold_label()
	_build_talent_items()

func _build_talent_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

	for talent_id in GameData.TALENTS:
		var info: Dictionary = GameData.TALENTS[talent_id]
		var current_lvl: int = GameData.get_talent_level(talent_id)
		var max_lvl: int = info.get("max_level", 5)
		var cost: int = GameData.get_talent_cost(talent_id)
		var is_max: bool = current_lvl >= max_lvl
		
		var panel = PanelContainer.new()
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.06, 0.07, 0.09, 0.85)
		p_style.border_color = Color(0.8, 0.65, 0.3, 0.6)
		p_style.set_border_width_all(1)
		p_style.set_corner_radius_all(8)
		p_style.content_margin_left = 16
		p_style.content_margin_top = 10
		p_style.content_margin_right = 16
		p_style.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", p_style)
		items_container.add_child(panel)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		panel.add_child(row)
		
		var icon_path := "res://assets/sprites/ui/icon_talent_%s.png" % talent_id
		if ResourceLoader.exists(icon_path):
			var icon_rect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(40, 40)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture = load(icon_path)
			row.add_child(icon_rect)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = "%s (Cấp %d/%d)" % [info["name"], current_lvl, max_lvl]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		text_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = info["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		text_vbox.add_child(desc_lbl)
		
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(130, 42)
		if is_max:
			buy_btn.text = "Tối Đa"
			buy_btn.disabled = true
		else:
			buy_btn.text = "Nâng (%d vàng)" % cost
			buy_btn.disabled = GameData.gold < cost
		
		buy_btn.pressed.connect(func():
			if GameData.upgrade_talent(talent_id):
				_build_talent_items()
		)
		row.add_child(buy_btn)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
