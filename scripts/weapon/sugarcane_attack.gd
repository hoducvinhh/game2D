extends Area2D

const HIT_EFFECT_SCENE: PackedScene = preload("res://scenes/weapon/hit_effect.tscn")

@export var speed: float = 500.0
var damage: int = 20
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	if not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		_spawn_hit_effect()
		if body.has_method("take_damage"):
			body.take_damage(damage)
			AudioManager.play_player_hit_sound()
		queue_free()

func _spawn_hit_effect() -> void:
	if not HIT_EFFECT_SCENE:
		return
	var effect = HIT_EFFECT_SCENE.instantiate()
	if effect:
		effect.global_position = global_position
		var current_scene := get_tree().current_scene
		if current_scene:
			current_scene.add_child(effect)
		elif get_parent():
			get_parent().add_child(effect)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
