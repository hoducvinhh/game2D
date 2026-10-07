extends Area2D

var player: Node2D = null

func _ready() -> void:
	add_to_group("pickups")
	player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < GameData.get_pickup_radius(100.0):
			global_position += (player.global_position - global_position).normalized() * 260.0 * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameData.add_gold(60)
		GameData.record_gold_collected(60)
		var quest_mgr = get_tree().get_first_node_in_group("quest_manager")
		if quest_mgr and quest_mgr.has_method("record_gold"):
			quest_mgr.record_gold(60)
		if "health" in body and "max_health" in body:
			body.health = body.max_health
			if body.has_method("update_health_ui"):
				body.update_health_ui()
		
		# Thông báo phần thưởng
		var label = Label.new()
		label.text = "🎁 MỞ RƯƠNG BÁU: +60 VÀNG & HỒI ĐẦY MÁU!"
		label.top_level = true
		label.global_position = global_position + Vector2(-120, -30)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		get_tree().current_scene.add_child(label)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(label, "position:y", label.position.y - 40.0, 1.2)
		tw.tween_property(label, "modulate:a", 0.0, 1.2)
		tw.chain().tween_callback(label.queue_free)
		
		queue_free()
