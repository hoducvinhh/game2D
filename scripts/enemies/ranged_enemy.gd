extends BaseEnemy
class_name RangedEnemy

var bullet_scene: PackedScene = preload("res://scenes/enemies/enemy_bullet.tscn")
var shoot_timer: float = 0.0
@export var shoot_interval: float = 4.4

func _ready() -> void:
	speed = 85.0
	max_health = 30
	super._ready()
	modulate = Color(0.85, 0.45, 1.2) # Màu tím phép thuật
	shoot_timer = randf_range(1.0, shoot_interval)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if is_instance_valid(player) and not is_fearing:
		var dist = global_position.distance_to(player.global_position)
		var to_player = (player.global_position - global_position).normalized()
		
		# Kiting AI: Giữ cự ly 220px - 320px
		if dist > 320.0:
			velocity = to_player * speed
		elif dist < 220.0:
			velocity = -to_player * (speed * 0.8) # Thối lui khi người chơi áp sát
		else:
			velocity = Vector2.ZERO # Đứng yên ngắm bắn
			
		move_and_slide()
		
		if to_player.x != 0 and sprite:
			sprite.flip_h = to_player.x < 0
			
		# Bắn đạn định kỳ
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = shoot_interval
			_shoot_at_player()
	else:
		super._physics_process(delta)

func _shoot_at_player() -> void:
	if not is_instance_valid(player) or is_dead:
		return
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.direction = (player.global_position - global_position).normalized()
		get_tree().current_scene.add_child(bullet)
		
		# Hiệu ứng lóe sáng khi bắn
		var tw = create_tween()
		tw.tween_property(self, "modulate", Color(2.0, 1.5, 2.5), 0.1)
		tw.tween_property(self, "modulate", Color(0.85, 0.45, 1.2), 0.1)
