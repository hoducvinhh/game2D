extends BaseEnemy
class_name VoidBoss

var bullet_scene: PackedScene = preload("res://scenes/enemies/enemy_bullet.tscn")

var is_enraged: bool = false
var skill_timer: float = 3.0
var is_charging: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var charge_duration_timer: float = 0.0

var boss_hud_layer: CanvasLayer
var boss_hud_panel: PanelContainer
var boss_health_bar: ProgressBar
var boss_health_text: Label
var boss_title_label: Label
var boss_fill_style: StyleBoxFlat
var boss_health_color_band: int = -1

func _ready() -> void:
	speed = 90.0
	max_health = 750
	damage = 25
	gold_drop_chance = 1.0
	gold_drop_min = 40
	gold_drop_max = 80
	projectile_texture = null
	
	super._ready()
	modulate = Color(1.1, 0.4, 1.3) # Tím Hư Không oai vệ
	_build_boss_hud()

func _build_boss_hud() -> void:
	var scene := get_tree().current_scene
	if not scene:
		push_error("Cannot build the boss HUD without an active scene")
		return

	boss_hud_layer = CanvasLayer.new()
	boss_hud_layer.name = "BossHudCanvasLayer"
	boss_hud_layer.layer = 20
	scene.add_child(boss_hud_layer)

	boss_hud_panel = PanelContainer.new()
	boss_hud_panel.custom_minimum_size = Vector2(230, 56)
	boss_hud_panel.size = boss_hud_panel.custom_minimum_size
	boss_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hud_layer.add_child(boss_hud_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.025, 0.09, 0.92)
	panel_style.border_color = Color(0.55, 0.25, 0.85, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(9)
	panel_style.content_margin_left = 10.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	boss_hud_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	boss_hud_panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	boss_title_label = Label.new()
	boss_title_label.text = "CHÚA TỂ HƯ KHÔNG"
	boss_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_title_label.add_theme_font_size_override("font_size", 12)
	boss_title_label.add_theme_color_override("font_color", Color(0.88, 0.75, 1.0))
	header.add_child(boss_title_label)

	boss_health_text = Label.new()
	boss_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	boss_health_text.add_theme_font_size_override("font_size", 11)
	boss_health_text.add_theme_color_override("font_color", Color(1.0, 0.94, 1.0))
	header.add_child(boss_health_text)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.max_value = max_health
	boss_health_bar.value = health
	boss_health_bar.custom_minimum_size.y = 14
	boss_health_bar.show_percentage = false
	boss_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.12, 0.09, 0.17)
	background_style.set_corner_radius_all(5)
	boss_health_bar.add_theme_stylebox_override("background", background_style)

	boss_fill_style = StyleBoxFlat.new()
	boss_fill_style.bg_color = Color(0.2, 0.9, 0.42)
	boss_fill_style.set_corner_radius_all(5)
	boss_health_bar.add_theme_stylebox_override("fill", boss_fill_style)
	vbox.add_child(boss_health_bar)
	_update_boss_hud()

func _update_boss_hud() -> void:
	if not is_instance_valid(boss_hud_panel):
		return

	boss_health_bar.value = health
	boss_health_text.text = "%d / %d" % [health, max_health]

	var health_ratio := float(health) / max_health
	var color_band := 2 if health_ratio <= 0.3 else (1 if health_ratio <= 0.6 else 0)
	if color_band != boss_health_color_band:
		boss_health_color_band = color_band
		var fill_color := Color(0.2, 0.9, 0.42)
		if color_band == 1:
			fill_color = Color(1.0, 0.68, 0.16)
		elif color_band == 2:
			fill_color = Color(1.0, 0.2, 0.24)
		boss_fill_style.bg_color = fill_color

	var screen_position := get_global_transform_with_canvas().origin
	var viewport_size := get_viewport_rect().size
	var panel_size := boss_hud_panel.size
	var is_near_view := (
		screen_position.x >= -120.0
		and screen_position.x <= viewport_size.x + 120.0
		and screen_position.y >= -220.0
		and screen_position.y <= viewport_size.y + 120.0
	)
	boss_hud_panel.visible = is_near_view
	if is_near_view:
		var max_x := maxf(8.0, viewport_size.x - panel_size.x - 8.0)
		var max_y := maxf(8.0, viewport_size.y - panel_size.y - 8.0)
		boss_hud_panel.position = Vector2(
			clampf(screen_position.x - panel_size.x * 0.5, 8.0, max_x),
			clampf(screen_position.y - 218.0, 8.0, max_y)
		)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	_update_boss_hud()
		
	# Kiểm tra chuyển Pha 2 (Cuồng Nộ)
	if not is_enraged and health <= max_health * 0.5:
		_enter_enraged_phase()

	# Xử lý chiêu lướt húc Dash
	if is_charging:
		charge_duration_timer -= delta
		velocity = charge_direction * (speed * 3.5)
		move_and_slide()
		if charge_duration_timer <= 0.0:
			is_charging = false
		return

	# Logic hành vi thường
	skill_timer -= delta
	if skill_timer <= 0.0:
		if is_enraged:
			skill_timer = 3.5
			_telegraph_charge()
		else:
			skill_timer = 6.0
			_fire_spread_bullets()

	if is_instance_valid(player) and not is_fearing:
		var offset_to_player: Vector2 = player.global_position - global_position
		var distance_to_player := offset_to_player.length()
		var toward_player := offset_to_player.normalized()
		if distance_to_player > 850.0:
			velocity = toward_player * speed
		elif distance_to_player < 620.0:
			velocity = -toward_player * speed
		else:
			var orbit_direction := Vector2(-toward_player.y, toward_player.x)
			velocity = (orbit_direction * 0.65 + toward_player * 0.1) * speed
		move_and_slide()
		if velocity.x != 0 and sprite:
			sprite.flip_h = velocity.x < 0
	else:
		super._physics_process(delta)

func _enter_enraged_phase() -> void:
	is_enraged = true
	speed = 135.0
	modulate = Color(2.5, 0.3, 0.3)
	if boss_title_label:
		boss_title_label.text = "CUỒNG NỘ: HƯ KHÔNG"
		boss_title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))

func _fire_spread_bullets() -> void:
	if not is_instance_valid(player) or not bullet_scene:
		return
	var base_dir = (player.global_position - global_position).normalized()
	var angles = [-0.28, 0.0, 0.28]
	for a in angles:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = base_dir.rotated(a)
		bullet.damage = 12
		get_tree().current_scene.add_child(bullet)

func _telegraph_charge() -> void:
	if not is_instance_valid(player):
		return
	charge_direction = (player.global_position - global_position).normalized()
	velocity = Vector2.ZERO
	
	# Cảnh báo nhấp nháy 0.5 giây trước khi húc
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(3.0, 3.0, 0.5), 0.25)
	tw.tween_property(self, "modulate", Color(2.5, 0.3, 0.3), 0.25)
	tw.finished.connect(func():
		is_charging = true
		charge_duration_timer = 0.55
	)

func die() -> void:
	if is_instance_valid(boss_hud_layer):
		boss_hud_layer.queue_free()
		
	# Báo nhiệm vụ diệt boss
	var quest_mgr = get_tree().get_first_node_in_group("quest_manager")
	if quest_mgr and quest_mgr.has_method("record_boss_killed"):
		quest_mgr.record_boss_killed()
	GameData.record_boss_defeated()
		
	# Rơi rương kho báu
	if ResourceLoader.exists("res://scenes/objects/treasure_chest.tscn"):
		var chest_res = load("res://scenes/objects/treasure_chest.tscn")
		if chest_res:
			var chest = chest_res.instantiate()
			chest.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", chest)
		
	super.die()
	var survival_manager = get_tree().current_scene.get_node_or_null("SurvivalManager")
	if survival_manager and survival_manager.has_method("trigger_win"):
		survival_manager.trigger_win()
