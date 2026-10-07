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
		# Tiêu diệt toàn bộ quái thường trên màn hình
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and not enemy.get("is_dead") and not (enemy is VoidBoss):
				if enemy.has_method("take_damage"):
					enemy.take_damage(9999)
					
		# Hiệu ứng nổ flash trắng
		var flash = ColorRect.new()
		flash.color = Color(1, 1, 1, 0.7)
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		get_tree().current_scene.add_child(flash)
		var tw = create_tween()
		tw.tween_property(flash, "modulate:a", 0.0, 0.4)
		tw.finished.connect(flash.queue_free)
		
		queue_free()
