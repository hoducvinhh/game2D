extends BaseEnemy
class_name RangedEnemy

func _ready() -> void:
	speed = 85.0
	max_health = 30
	super._ready()
	modulate = Color(0.85, 0.45, 1.2) # Màu tím phép thuật

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
	else:
		super._physics_process(delta)
