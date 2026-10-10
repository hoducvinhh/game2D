extends CharacterBody2D
class_name BaseEnemy

const ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/enemies/enemy_bullet.tscn")

@export var speed: float = 120.0
@export var damage: int = 10
@export var projectile_texture: Texture2D = preload("res://assets/sprites/enemies/dan_cauthu.png")
@export var projectile_cooldown: float = 3.0
@export var projectile_damage: int = 6
@export var projectile_speed: float = 280.0
@export var projectile_scale: float = 0.1

# --- THÔNG SỐ MÁU ---
@export var max_health: int = 40
var health: int = 40

# --- TRẠNG THÁI HOẢNG SỢ (HIỆU ỨNG TỪ ĐIỆN THOẠI) ---
var is_fearing: bool = false
var fear_timer: float = 0.0
var fear_source_pos: Vector2 = Vector2.ZERO

# Quái rơi EXP khi chết
var exp_gem_scene: PackedScene = preload("res://scenes/objects/exp_gem.tscn")
var gold_coin_scene: PackedScene = preload("res://scenes/objects/gold_coin.tscn")
@export_range(0.0, 1.0) var gold_drop_chance: float = 0.4
@export var gold_drop_min: int = 5
@export var gold_drop_max: int = 10
@export_range(1, 8) var animation_frame_count: int = 1
@export var animation_frame_step: float = 169.0
@export var animation_fps: float = 6.0

var player: Node2D = null
var is_dead: bool = false
var original_scale: Vector2 = Vector2.ONE
var walk_anim_timer: float = 0.0
var animation_timer: float = 0.0
var animation_frame: int = 0
var animation_base_rect: Rect2
var projectile_timer: float = 1.5

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	if sprite:
		original_scale = sprite.scale
		animation_base_rect = sprite.region_rect

func _process(delta: float) -> void:
	if sprite and animation_frame_count > 1:
		animation_timer += delta
		if animation_timer >= 1.0 / animation_fps:
			animation_timer = 0.0
			animation_frame = (animation_frame + 1) % animation_frame_count
			sprite.region_rect = Rect2(
				animation_base_rect.position.x + animation_frame_step * animation_frame,
				animation_base_rect.position.y,
				animation_base_rect.size.x,
				animation_base_rect.size.y
			)

	if is_dead or is_fearing or not is_instance_valid(player) or not projectile_texture:
		return
	projectile_timer -= delta
	if projectile_timer <= 0.0:
		_fire_projectile()
		projectile_timer = projectile_cooldown

func _fire_projectile() -> void:
	if not is_instance_valid(player):
		return
	var direction := global_position.direction_to(player.global_position)
	var projectile := ENEMY_BULLET_SCENE.instantiate() as Area2D
	projectile.set("direction", direction)
	projectile.set("damage", projectile_damage)
	projectile.set("speed", projectile_speed)
	projectile.set("projectile_texture", projectile_texture)
	projectile.set("projectile_scale", projectile_scale)
	projectile.global_position = global_position + direction * 20.0
	get_tree().current_scene.add_child(projectile)

# --- HÀM KÍCH HOẠT TRẠNG THÁI HOẢNG SỢ ---
func apply_fear(duration: float, source_pos: Vector2) -> void:
	if is_dead:
		return
		
	is_fearing = true
	fear_timer = duration
	fear_source_pos = source_pos
	modulate = Color(0.6, 0.8, 1.2)
	
	if player:
		var flee_direction = (global_position - player.global_position).normalized()
		velocity = flee_direction * (speed * 1.3)
		if flee_direction.x != 0 and sprite:
			sprite.flip_h = flee_direction.x < 0

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Đếm ngược thời gian hoảng sợ
	if is_fearing:
		fear_timer -= delta
		if fear_timer <= 0.0:
			is_fearing = false
			modulate = Color.WHITE

	# Xử lý di chuyển và AI bầy đàn (Flocking Separation)
	if is_instance_valid(player):
		var direction: Vector2 = Vector2.ZERO
		
		if is_fearing:
			direction = (global_position - player.global_position).normalized()
			velocity = direction * (speed * 1.3)
		else:
			var to_player = (player.global_position - global_position).normalized()
			
			# Thuật toán tránh chồng lấn quái (Separation Force)
			var separation = Vector2.ZERO
			var enemies = get_tree().get_nodes_in_group("enemies")
			var count = 0
			for other in enemies:
				if other != self and is_instance_valid(other) and not other.get("is_dead"):
					var dist = global_position.distance_to(other.global_position)
					if dist > 0 and dist < 36.0:
						separation += (global_position - other.global_position).normalized() * ((36.0 - dist) / 36.0)
						count += 1
						if count >= 4:
							break
							
			direction = (to_player * 0.8 + separation * 0.5).normalized()
			velocity = direction * speed
			
		move_and_slide()
		
		# Hoạt ảnh nhún chân bước đi (Squash & stretch wobble)
		walk_anim_timer += delta * 10.0
		if sprite:
			sprite.scale.y = original_scale.y * (1.0 + sin(walk_anim_timer) * 0.08)
			if direction.x != 0:
				sprite.flip_h = direction.x < 0

	# Gây sát thương khi va chạm
	if not is_fearing:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("player"):
				if collider.has_method("take_damage"):
					collider.take_damage(damage)

# --- NHẬN SÁT THƯƠNG ---
func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	health -= amount
	health = clamp(health, 0, max_health)
	
	_spawn_damage_number(amount)
	
	modulate = Color(2.5, 0.4, 0.4)
	var flash_tween = create_tween()
	var return_color = Color(0.6, 0.8, 1.2) if is_fearing else Color.WHITE
	flash_tween.tween_property(self, "modulate", return_color, 0.08)
	
	if health <= 0:
		is_dead = true
		remove_from_group("enemies")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		die()

func _spawn_damage_number(amount: int) -> void:
	var label = Label.new()
	label.text = str(amount)
	label.top_level = true
	label.global_position = global_position + Vector2(randf_range(-10, 10), -24)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.z_index = 50
	get_tree().current_scene.add_child(label)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 28.0, 0.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(label.queue_free)

func die() -> void:
	GameData.record_enemy_kill()
	var run_progression = get_tree().get_first_node_in_group("run_progression")
	if run_progression and run_progression.has_method("record_normal_enemy_kill"):
		run_progression.record_normal_enemy_kill()

	# Tích nộ cho TouchControls
	var touch = get_tree().get_first_node_in_group("touch_controls")
	if touch and touch.has_method("add_rage"):
		touch.add_rage(2.5)

	# Tỉ lệ rơi vật phẩm sàn đặc biệt (Máu, Nam châm, Bom)
	var drop_roll = randf()
	if drop_roll < 0.04 and ResourceLoader.exists("res://scenes/objects/meat_heal.tscn"):
		var meat_res = load("res://scenes/objects/meat_heal.tscn")
		if meat_res:
			var meat = meat_res.instantiate()
			meat.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", meat)
	elif drop_roll < 0.065 and ResourceLoader.exists("res://scenes/objects/magnet.tscn"):
		var mag_res = load("res://scenes/objects/magnet.tscn")
		if mag_res:
			var magnet = mag_res.instantiate()
			magnet.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", magnet)
	elif drop_roll < 0.09 and ResourceLoader.exists("res://scenes/objects/bomb_nuke.tscn"):
		var bomb_res = load("res://scenes/objects/bomb_nuke.tscn")
		if bomb_res:
			var bomb = bomb_res.instantiate()
			bomb.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", bomb)
	elif gold_coin_scene and randf() < GameData.get_gold_drop_chance(gold_drop_chance):
		var gold_coin = gold_coin_scene.instantiate()
		gold_coin.gold_amount = randi_range(gold_drop_min, gold_drop_max)
		gold_coin.global_position = global_position + Vector2(12, 0)
		get_tree().current_scene.call_deferred("add_child", gold_coin)
	elif exp_gem_scene:
		var exp_gem = exp_gem_scene.instantiate()
		exp_gem.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", exp_gem)
	
	queue_free()
