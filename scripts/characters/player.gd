extends BaseCharacter

@export var speed: float = 200.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapons: Node2D = $Weapons

var idle_time_counter: float = 0.0
const IDLE_TIMEOUT: float = 0.5 
var attack_animation_timer: float = 0.0
var jump_animation_timer: float = 0.0
var jump_key_down: bool = false
var last_facing_dir: Vector2 = Vector2.RIGHT

# --- DASH & SKILL MECHANICS ---
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_duration: float = 0.25
var dash_distance: float = 180.0
var dash_origin: Vector2 = Vector2.ZERO
var dash_cooldown: float = 2.0
var dash_cooldown_timer: float = 0.0
var ghost_trail_timer: float = 0.0

var attack_cooldown_timer: float = 0.0
var ultimate_buff_timer: float = 0.0
var touch_controls: TouchControls = null

signal exp_changed(current_exp: int, max_exp: int)
signal player_leveled_up(current_level: int)
signal weapons_changed

var current_exp: int = 0
var max_exp: int = 50
var level: int = 1

func _ready() -> void:
	var char_data: Dictionary = GameData.CHARACTERS.get(GameData.selected_character_id, {})
	max_health += int(char_data.get("bonus_hp", 0)) + GameData.get_talent_level("max_hp") * 15
	speed = (speed + float(char_data.get("bonus_speed", 0.0))) * (1.0 + GameData.get_talent_level("speed") * 0.05)
	health = max_health

	super._ready() # Khởi tạo máu và bộ đếm i-frame từ BaseCharacter
	add_to_group("player")
	_apply_selected_character_texture()
	if animated_sprite:
		animated_sprite.play("default")
	weapons_changed.emit()
	
	# Kết nối với TouchControls (nếu có trên CanvasLayer)
	await get_tree().process_frame
	touch_controls = get_tree().get_first_node_in_group("touch_controls") as TouchControls
	if not touch_controls:
		var touch_node = get_tree().current_scene.find_child("TouchControls", true, false)
		if touch_node is TouchControls:
			touch_controls = touch_node
			
	if touch_controls:
		touch_controls.attack_pressed.connect(perform_active_attack)
		touch_controls.dash_pressed.connect(perform_dash)
		touch_controls.ultimate_pressed.connect(perform_ultimate)

func _apply_selected_character_texture() -> void:
	if not animated_sprite:
		return
	var character: Dictionary = GameData.CHARACTERS.get(GameData.selected_character_id, {})
	if character.is_empty():
		return
	var normal_path: String = character.get("normal_path", character.get("sprite_path", ""))
	var animation_paths := {
		"default": normal_path,
		"run": character.get("run_path", normal_path),
		"lobby": normal_path,
		"attack": character.get("attack_path", ""),
		"jump": character.get("jump_path", "")
	}
	var run_frame_paths: Array = character.get("run_frames", [])
	var frames := animated_sprite.sprite_frames.duplicate() as SpriteFrames
	for animation_name in animation_paths:
		var texture_path: String = animation_paths[animation_name]
		if not frames.has_animation(animation_name):
			frames.add_animation(animation_name)
		frames.clear(animation_name)
		if animation_name == "run" and not run_frame_paths.is_empty():
			for frame_index in range(run_frame_paths.size()):
				var frame_path: String = run_frame_paths[frame_index]
				if not ResourceLoader.exists(frame_path):
					push_error("Missing run animation frame: %s" % frame_path)
					continue
				var frame_texture := load(frame_path) as Texture2D
				if not frame_texture:
					push_error("Cannot load run animation frame: %s" % frame_path)
					continue
				var frame_duration := 0.75 if frame_index == 2 else 1.0
				frames.add_frame(animation_name, frame_texture, frame_duration)
		else:
			if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
				continue
			var texture := load(texture_path) as Texture2D
			if not texture:
				continue
			frames.add_frame(animation_name, texture)
		frames.set_animation_speed(animation_name, 10.0 if animation_name == "run" and not run_frame_paths.is_empty() else 8.0)
		frames.set_animation_loop(animation_name, not ["attack", "jump"].has(animation_name))
	animated_sprite.stop()
	animated_sprite.sprite_frames = frames
	animated_sprite.animation = "default"
	animated_sprite.frame = 0
	animated_sprite.play("default")

func play_attack_animation() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames.has_animation("attack"):
		return
	attack_animation_timer = 0.25
	jump_animation_timer = 0.0
	idle_time_counter = IDLE_TIMEOUT
	animated_sprite.play("attack")

func play_jump_animation() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames.has_animation("jump"):
		return
	jump_animation_timer = 0.4
	attack_animation_timer = 0.0
	idle_time_counter = IDLE_TIMEOUT
	animated_sprite.play("jump")

# --- KỸ NĂNG LƯỚT NÉ CHIÊU (DASH) ---
func perform_dash() -> void:
	if is_dashing or dash_cooldown_timer > 0.0:
		return
	is_dashing = true
	dash_timer = dash_duration
	dash_origin = global_position
	dash_cooldown_timer = dash_cooldown
	if touch_controls:
		touch_controls.notify_dash_used()
	start_iframes(dash_duration)
	play_jump_animation()
	_spawn_ghost_trail()

# --- TẤN CÔNG CHỦ ĐỘNG (ACTIVE MELEE ATTACK) ---
func perform_active_attack() -> void:
	var sugarcane := weapons.get_node_or_null("Sugarcane")
	if sugarcane and sugarcane.has_method("manual_attack"):
		sugarcane.call("manual_attack")

	if attack_cooldown_timer > 0.0:
		return
	var cd = 0.25 if ultimate_buff_timer > 0.0 else 0.45
	attack_cooldown_timer = cd
	play_attack_animation()
	
	# Quét kẻ địch phía trước trong góc 80 độ, cự ly 90px
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			var to_enemy: Vector2 = enemy.global_position - global_position
			var in_range: bool = to_enemy.length() <= 90.0
			var in_arc: bool = to_enemy.is_zero_approx() or last_facing_dir.dot(to_enemy.normalized()) >= cos(deg_to_rad(40.0))
			if in_range and in_arc:
				var damage_amount = 35
				if ultimate_buff_timer > 0.0:
					damage_amount = 60
				damage_amount = roundi(damage_amount * GameData.get_damage_multiplier())
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage_amount)
					hit_count += 1
					# Đẩy lùi nhẹ
					if "velocity" in enemy:
						enemy.velocity += last_facing_dir * 260.0
						
	if hit_count > 0 and touch_controls:
		touch_controls.add_rage(hit_count * 3.0)

# --- CHIÊU NỘ TỐI THƯỢNG (ULTIMATE NOVA) ---
func perform_ultimate() -> void:
	if not touch_controls or not touch_controls.consume_rage():
		return
	ultimate_buff_timer = 5.0
	shake_screen(14.0, 0.35)
	# Nổ sóng sát thương quét sạch khu vực 300px
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= 320.0:
				var push_dir = (enemy.global_position - global_position).normalized()
				if enemy.has_method("take_damage"):
					enemy.take_damage(roundi(120 * GameData.get_damage_multiplier()))
				if "velocity" in enemy:
					enemy.velocity += push_dir * 450.0

	# Hiệu ứng lóe sáng toàn thân
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(2.0, 1.8, 0.4), 0.2)
	tw.tween_property(self, "modulate", Color.WHITE, 0.3)

func _spawn_ghost_trail() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	var ghost = Sprite2D.new()
	var current_anim = animated_sprite.animation
	var current_frame = animated_sprite.frame
	if animated_sprite.sprite_frames.has_animation(current_anim):
		ghost.texture = animated_sprite.sprite_frames.get_frame_texture(current_anim, current_frame)
	ghost.global_position = animated_sprite.global_position
	ghost.scale = animated_sprite.scale
	ghost.flip_h = animated_sprite.flip_h
	ghost.modulate = Color(0.3, 0.7, 1.0, 0.6)
	get_tree().current_scene.add_child(ghost)
	
	var tw = create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tw.finished.connect(ghost.queue_free)

func add_exp(amount: int) -> void:
	current_exp += amount
	emit_signal("exp_changed", current_exp, max_exp)
	if current_exp >= max_exp:
		level_up()

func level_up() -> void:
	level += 1
	current_exp -= max_exp
	max_exp = int(max_exp * 1.5)
	emit_signal("exp_changed", current_exp, max_exp)
	player_leveled_up.emit(level)

func apply_upgrade(data: Dictionary) -> void:
	match data["type"]:
		"new_weapon":
			var weapon_scene: PackedScene = data["scene"]
			var new_weapon = weapon_scene.instantiate()
			new_weapon.name = data["id"]
			weapons.add_child(new_weapon)
		"upgrade_weapon":
			var weapon_id: String = data["id"]
			var weapon = weapons.get_node_or_null(weapon_id)
			if weapon:
				if weapon.has_method("upgrade"):
					weapon.upgrade()
				elif weapon.has_method("level_up"):
					weapon.level_up()
		"stat":
			if data["id"] == "heal":
				health = clamp(health + 30, 0, max_health)
				if has_method("update_health_ui"):
					update_health_ui()
			elif data["id"] == "speed":
				speed *= 1.15
		"passive":
			if not passive_items.has(data["id"]):
				passive_items.append(data["id"])
				match data["id"]:
					"max_hp":
						max_health += 20
						health = mini(max_health, health + 20)
						update_health_ui()
					"speed":
						speed *= 1.1
		"evolve_weapon":
			var evolved_weapon := weapons.get_node_or_null(data["id"])
			if evolved_weapon and evolved_weapon.has_method("evolve") and evolved_weapon.evolve():
				GameData.record_weapon_evolved(data["id"])
	weapons_changed.emit()

var passive_items: Array[String] = []

func get_damage_multiplier() -> float:
	return GameData.get_damage_multiplier()

func get_attack_speed_multiplier() -> float:
	return 1.5 if ultimate_buff_timer > 0.0 else 1.0

func apply_map_slow(multiplier: float, duration: float) -> void:
	_map_slow_multiplier = minf(_map_slow_multiplier, clampf(multiplier, 0.1, 1.0))
	_map_slow_timer = maxf(_map_slow_timer, duration)

var _map_slow_multiplier: float = 1.0
var _map_slow_timer: float = 0.0

func take_damage(amount: int) -> void:
	var final_damage: float = float(amount)
	
	var shield_node = weapons.get_node_or_null("Shield")
	if shield_node and shield_node.has_method("get_damage_reduction"):
		var reduction: float = shield_node.get_damage_reduction()
		final_damage -= final_damage * reduction

	var actual_damage: int = max(1, int(round(final_damage)))
	super.take_damage(actual_damage)

func _physics_process(delta: float) -> void:
	super._physics_process(delta) # Giữ bộ đếm thời gian i-frame của BaseCharacter chạy
	
	# Cập nhật bộ đếm thời gian kỹ năng
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	attack_cooldown_timer = maxf(0.0, attack_cooldown_timer - delta)
	ultimate_buff_timer = maxf(0.0, ultimate_buff_timer - delta)
	_map_slow_timer = maxf(0.0, _map_slow_timer - delta)
	if _map_slow_timer <= 0.0:
		_map_slow_multiplier = 1.0
	
	# Kiểm tra phím tắt trên PC
	# Xử lý trạng thái Lướt Dash
	if is_dashing:
		dash_timer -= delta
		ghost_trail_timer += delta
		if ghost_trail_timer >= 0.05:
			ghost_trail_timer = 0.0
			_spawn_ghost_trail()
		
		var remaining_distance := maxf(0.0, dash_distance - global_position.distance_to(dash_origin))
		var frame_distance := minf(dash_distance / dash_duration * delta, remaining_distance)
		velocity = last_facing_dir * (frame_distance / maxf(delta, 0.001))
		move_and_slide()
		if dash_timer <= 0.0 or global_position.distance_to(dash_origin) >= dash_distance:
			is_dashing = false
		return
	
	attack_animation_timer = maxf(0.0, attack_animation_timer - delta)
	jump_animation_timer = maxf(0.0, jump_animation_timer - delta)
	
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1
		
	# Lấy thêm input từ Virtual Joystick nếu có
	if touch_controls:
		var joy_vec = touch_controls.get_joystick_vector()
		if joy_vec.length() > 0.15:
			direction = joy_vec
			
	direction = direction.normalized()
	
	if direction != Vector2.ZERO:
		last_facing_dir = direction
	
	var effective_speed = speed
	if ultimate_buff_timer > 0.0:
		effective_speed *= 1.4
	effective_speed *= _map_slow_multiplier

	# Tốc độ di chuyển độc lập với đòn đánh để di chuyển luôn mượt mà
	if direction != Vector2.ZERO:
		velocity = direction * effective_speed
		if direction.x != 0 and animated_sprite:
			animated_sprite.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO
		
	# Quản lý hoạt ảnh diễn hoạt (Animation)
	if jump_animation_timer > 0.0:
		if animated_sprite and animated_sprite.animation != "jump" and animated_sprite.sprite_frames.has_animation("jump"):
			animated_sprite.play("jump")
	elif attack_animation_timer > 0.0:
		if animated_sprite and animated_sprite.animation != "attack" and animated_sprite.sprite_frames.has_animation("attack"):
			animated_sprite.play("attack")
	elif direction != Vector2.ZERO:
		idle_time_counter = 0.0
		if animated_sprite and animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		idle_time_counter += delta
		if idle_time_counter >= IDLE_TIMEOUT and animated_sprite and animated_sprite.animation != "default":
			animated_sprite.play("default")
		
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_SHIFT:
			perform_dash()
		elif event.keycode == KEY_J or event.keycode == KEY_K:
			perform_active_attack()
		elif event.keycode == KEY_F or event.keycode == KEY_E:
			if touch_controls:
				touch_controls._on_ultimate_pressed()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var viewport_size := get_viewport_rect().size
		var on_joystick_area: bool = event.position.x < 350.0 and event.position.y > viewport_size.y - 350.0
		var on_action_area: bool = event.position.x > viewport_size.x - 300.0 and event.position.y > viewport_size.y - 260.0
		if not on_joystick_area and not on_action_area:
			perform_active_attack()
