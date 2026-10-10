extends BaseEnemy
class_name VoidBoss

var bullet_scene: PackedScene = preload("res://scenes/enemies/enemy_bullet.tscn")

var is_enraged: bool = false
var skill_timer: float = 3.0
var is_charging: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var charge_duration_timer: float = 0.0

var boss_hud_panel: PanelContainer
var boss_health_bar: ProgressBar
var boss_title_label: Label

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
	var canvas = get_tree().current_scene.find_child("CanvasLayer", true, false)
	if not canvas:
		return
		
	boss_hud_panel = PanelContainer.new()
	boss_hud_panel.custom_minimum_size = Vector2(480, 52)
	boss_hud_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_hud_panel.offset_left = 80.0
	boss_hud_panel.offset_right = -80.0
	boss_hud_panel.offset_top = 36.0
	canvas.add_child(boss_hud_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	boss_hud_panel.add_child(vbox)
	
	boss_title_label = Label.new()
	boss_title_label.text = "👑 CHÚA TỂ HƯ KHÔNG (VOID OVERLORD)"
	boss_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_title_label.add_theme_font_size_override("font_size", 14)
	boss_title_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	vbox.add_child(boss_title_label)
	
	boss_health_bar = ProgressBar.new()
	boss_health_bar.max_value = max_health
	boss_health_bar.value = health
	boss_health_bar.custom_minimum_size.y = 16
	boss_health_bar.show_percentage = false
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.9, 0.15, 0.15)
	bar_style.set_corner_radius_all(4)
	boss_health_bar.add_theme_stylebox_override("fill", bar_style)
	vbox.add_child(boss_health_bar)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if boss_health_bar:
		boss_health_bar.value = health
		
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
		boss_title_label.text = "⚡ CUỒNG NỘ: CHÚA TỂ HƯ KHÔNG"
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
	if is_instance_valid(boss_hud_panel):
		boss_hud_panel.queue_free()
		
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
