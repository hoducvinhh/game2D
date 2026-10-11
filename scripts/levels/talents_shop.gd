extends Control

const MAIN_MENU_PATH := "res://scenes/levels/main_menu.tscn"
const TALENT_ICON_PATHS := {
	"max_hp": "res://assets/sprites/ui/icon_talent_damage.png",
	"speed": "res://assets/sprites/ui/icon_talent_max_hp.png",
	"damage": "res://assets/sprites/ui/icon_talent_pickup_range.png",
	"pickup_range": "res://assets/sprites/ui/icon_talent_speed.png",
	"greed": "res://assets/sprites/ui/icon_talent_greed.png",
}
const TALENT_ICON_LABELS := {
	"max_hp": "HP",
	"speed": "TĐ",
	"damage": "ST",
}
const TALENT_ICON_COLORS := {
	"max_hp": Color(0.62, 0.2, 0.22),
	"speed": Color(0.2, 0.42, 0.7),
	"damage": Color(0.68, 0.35, 0.16),
}

@onready var gold_label: Label = $MarginContainer/VBoxContainer/Header/GoldLabel
@onready var items_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var btn_back: Button = $MarginContainer/VBoxContainer/Header/BtnBack
@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/Title

var pets_container: VBoxContainer
var talents_tab_button: Button
var pets_tab_button: Button
var showing_pets_tab: bool = false

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	_style_shop_action_button(btn_back, Vector2(110.0, 40.0))
	GameData.gold_changed.connect(_on_gold_changed)
	_create_shop_tabs()
	_update_gold_label()
	_build_talent_items()
	_build_pet_items()

func _create_shop_tabs() -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	$MarginContainer/VBoxContainer.add_child(tabs)
	$MarginContainer/VBoxContainer.move_child(tabs, scroll_container.get_index())

	talents_tab_button = Button.new()
	talents_tab_button.text = "NÂNG CẤP"
	talents_tab_button.pressed.connect(_show_talents_tab)
	tabs.add_child(talents_tab_button)

	pets_tab_button = Button.new()
	pets_tab_button.text = "THÚ CƯNG"
	pets_tab_button.pressed.connect(_show_pets_tab)
	tabs.add_child(pets_tab_button)
	_refresh_shop_tabs()

	pets_container = VBoxContainer.new()
	pets_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pets_container.add_theme_constant_override("separation", 12)
	scroll_container.add_child(pets_container)
	pets_container.hide()

func _show_talents_tab() -> void:
	showing_pets_tab = false
	items_container.show()
	pets_container.hide()
	title_label.text = "CỬA HÀNG NÂNG CẤP VĨNH VIỄN"
	_refresh_shop_tabs()

func _show_pets_tab() -> void:
	showing_pets_tab = true
	items_container.hide()
	pets_container.show()
	title_label.text = "CỬA HÀNG PET"
	_refresh_shop_tabs()

func _refresh_shop_tabs() -> void:
	if is_instance_valid(talents_tab_button):
		_style_shop_tab(talents_tab_button, not showing_pets_tab)
	if is_instance_valid(pets_tab_button):
		_style_shop_tab(pets_tab_button, showing_pets_tab)

func _style_shop_tab(button: Button, is_active: bool) -> void:
	button.custom_minimum_size = Vector2(156.0, 46.0)
	_style_shop_button(button, is_active)

func _style_shop_action_button(button: Button, minimum_size: Vector2) -> void:
	button.custom_minimum_size = minimum_size
	_style_shop_button(button, false)

func _style_shop_button(button: Button, is_active: bool) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.82, 0.79, 0.7))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.98, 0.9))
	button.add_theme_color_override("font_disabled_color", Color(0.57, 0.55, 0.49))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.075, 0.105, 0.12, 0.98) if not is_active else Color(0.34, 0.23, 0.09, 1.0)
	normal.border_color = Color(0.25, 0.38, 0.39, 1.0) if not is_active else Color(1.0, 0.75, 0.25, 1.0)
	normal.set_border_width_all(2 if is_active else 1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	normal.shadow_size = 4
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.15, 0.22, 0.22, 1.0) if not is_active else Color(0.48, 0.33, 0.11, 1.0)
	hover.border_color = Color(0.52, 0.72, 0.65, 1.0) if not is_active else Color(1.0, 0.88, 0.48, 1.0)
	hover.shadow_size = 6
	button.add_theme_stylebox_override("hover", hover)

	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.045, 0.075, 0.08, 1.0) if not is_active else Color(0.24, 0.16, 0.055, 1.0)
	pressed.shadow_size = 2
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.055, 0.06, 0.065, 0.9)
	disabled.border_color = Color(0.25, 0.25, 0.24, 0.8)
	disabled.shadow_size = 0
	button.add_theme_stylebox_override("disabled", disabled)

func _update_gold_label() -> void:
	gold_label.text = "🪙 Vàng: %d" % GameData.gold

func _on_gold_changed(_total_gold: int) -> void:
	_update_gold_label()
	_build_talent_items()
	_build_pet_items()

func _build_pet_items() -> void:
	if not is_instance_valid(pets_container):
		return
	for child in pets_container.get_children():
		pets_container.remove_child(child)
		child.queue_free()

	for pet_id in GameData.PETS:
		var info: Dictionary = GameData.PETS[pet_id]
		var panel := PanelContainer.new()
		panel.custom_minimum_size.y = 150.0
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.06, 0.07, 0.09, 0.9)
		panel_style.border_color = Color(0.8, 0.65, 0.3, 0.6)
		panel_style.set_border_width_all(1)
		panel_style.set_corner_radius_all(8)
		panel_style.content_margin_left = 14
		panel_style.content_margin_top = 10
		panel_style.content_margin_right = 14
		panel_style.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", panel_style)
		pets_container.add_child(panel)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		panel.add_child(row)
		row.add_child(_create_pet_preview(info))

		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation", 6)
		row.add_child(details)

		var name_label := Label.new()
		name_label.text = info.get("name", pet_id)
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		details.add_child(name_label)

		var description := Label.new()
		description.text = info.get("description", "")
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		description.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		details.add_child(description)

		var action_button := Button.new()
		_style_shop_action_button(action_button, Vector2(170.0, 44.0))
		row.add_child(action_button)

		if GameData.is_pet_unlocked(pet_id):
			if GameData.selected_pet_id == pet_id:
				action_button.text = "Đang dùng"
				action_button.disabled = true
			else:
				action_button.text = "Dùng pet này"
				action_button.pressed.connect(_select_pet.bind(pet_id))
		else:
			var price: int = info.get("price", 0)
			action_button.text = "Mua (%d vàng)" % price
			action_button.disabled = GameData.gold < price
			action_button.pressed.connect(_purchase_pet.bind(pet_id))

func _create_pet_preview(info: Dictionary) -> TextureRect:
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(132.0, 112.0)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var preview_path: String = info.get("preview_path", "")
	if ResourceLoader.exists(preview_path):
		preview.texture = load(preview_path) as Texture2D
		if preview_path.ends_with("/pet.png") and preview.texture:
			var atlas := AtlasTexture.new()
			atlas.atlas = preview.texture
			atlas.region = Rect2(35.0, 128.0, 128.0, 116.0)
			preview.texture = atlas
	return preview

func _purchase_pet(pet_id: String) -> void:
	GameData.purchase_pet(pet_id)
	_build_pet_items()

func _select_pet(pet_id: String) -> void:
	GameData.select_pet(pet_id)
	_build_pet_items()

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
		
		row.add_child(_create_talent_icon(talent_id))
		
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
		_style_shop_action_button(buy_btn, Vector2(150, 42))
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

func _create_talent_icon(talent_id: String) -> Control:
	var icon_path: String = TALENT_ICON_PATHS.get(talent_id, "")
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon_texture: Texture2D = load(icon_path)
		if icon_texture:
			var icon_rect := TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(40, 40)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture = icon_texture
			return icon_rect

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(40, 40)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = TALENT_ICON_COLORS.get(talent_id, Color(0.25, 0.28, 0.32))
	badge_style.set_corner_radius_all(8)
	badge.add_theme_stylebox_override("panel", badge_style)

	var label := Label.new()
	label.text = TALENT_ICON_LABELS.get(talent_id, "?")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	badge.add_child(label)
	return badge

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
