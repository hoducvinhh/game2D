extends Area2D

@export var speed: float = 220.0
@export var damage: int = 8
var direction: Vector2 = Vector2.RIGHT
var projectile_texture: Texture2D
var projectile_scale: float = 0.35

func _ready() -> void:
	add_to_group("enemy_bullets")
	collision_layer = 0
	collision_mask = 1 # layer 1 is player
	body_entered.connect(_on_body_entered)
	
	var texture := projectile_texture
	if not texture:
		var tex_path := "res://assets/sprites/enemies/enemy_bullet.png"
		if ResourceLoader.exists(tex_path):
			texture = load(tex_path)
	if texture:
		var color_rect = get_node_or_null("ColorRect")
		if color_rect:
			color_rect.hide()
		var sp := Sprite2D.new()
		sp.texture = texture
		sp.scale = Vector2.ONE * projectile_scale
		add_child(sp)
	
	rotation = direction.angle()
	
	# Tự hủy sau 3.5 giây nếu bay ra ngoài
	var timer = get_tree().create_timer(3.5)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
