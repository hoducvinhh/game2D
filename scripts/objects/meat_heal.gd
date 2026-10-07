extends Area2D

@export var heal_amount: int = 35
var player: Node2D = null

func _ready() -> void:
	add_to_group("pickups")
	player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < GameData.get_pickup_radius(120.0):
			global_position += (player.global_position - global_position).normalized() * 300.0 * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if "health" in body and "max_health" in body:
			body.health = mini(body.max_health, body.health + heal_amount)
			if body.has_method("update_health_ui"):
				body.update_health_ui()
		queue_free()
