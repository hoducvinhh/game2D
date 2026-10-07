extends Area2D

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
		# Hút toàn bộ Exp Gem và Vàng trên toàn bản đồ
		var gems = get_tree().get_nodes_in_group("exp_gems")
		for gem in gems:
			if is_instance_valid(gem):
				gem.is_magnetized = true
				if "magnet_speed" in gem:
					gem.magnet_speed = 700.0
					
		var coins = get_tree().get_nodes_in_group("gold_coins")
		for coin in coins:
			if is_instance_valid(coin) and "is_magnetized" in coin:
				coin.is_magnetized = true
				if "magnet_speed" in coin:
					coin.magnet_speed = 700.0
					
		queue_free()
