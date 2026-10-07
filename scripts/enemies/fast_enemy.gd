extends BaseEnemy
class_name FastEnemy

var flank_dir: float = 1.0
var flank_switch_timer: float = 0.0

func _ready() -> void:
	speed = 175.0
	max_health = 22
	damage = 7
	super._ready()
	modulate = Color(1.3, 0.65, 0.35)
	flank_dir = 1.0 if randf() > 0.5 else -1.0
	flank_switch_timer = randf_range(1.0, 2.0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	flank_switch_timer -= delta
	if flank_switch_timer <= 0.0:
		flank_switch_timer = randf_range(1.5, 3.0)
		flank_dir *= -1.0
		
	if is_instance_valid(player) and not is_fearing:
		var to_player = (player.global_position - global_position).normalized()
		var tangent = Vector2(-to_player.y, to_player.x) * flank_dir
		
		# Hướng di chuyển bao vây bọc sườn (Flanking vector)
		var direction = (to_player * 0.75 + tangent * 0.5).normalized()
		velocity = direction * speed
		move_and_slide()
		
		if direction.x != 0 and sprite:
			sprite.flip_h = direction.x < 0
	else:
		super._physics_process(delta)
