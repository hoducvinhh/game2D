extends CharacterBody2D
class_name CompanionPet

@export var follow_speed: float = 230.0
@export var pickup_speed: float = 290.0

var player: Node2D = null
var target_pickup: Node2D = null
var search_timer: float = 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	add_to_group("allies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	# Tìm vật phẩm xung quanh mỗi 0.35 giây
	search_timer -= delta
	if search_timer <= 0.0:
		search_timer = 0.35
		_find_nearest_pickup()
		
	if is_instance_valid(target_pickup):
		var to_item = (target_pickup.global_position - global_position).normalized()
		velocity = to_item * pickup_speed
		move_and_slide()
		if to_item.x != 0 and sprite:
			sprite.flip_h = to_item.x < 0
			
		# Nếu đã tới rất gần item thì item sẽ tự va chạm/hút
		if global_position.distance_to(target_pickup.global_position) < 20.0:
			if target_pickup.has_method("_on_body_entered"):
				target_pickup._on_body_entered(player)
			target_pickup = null
	else:
		# Bám theo Player
		var dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player > 70.0:
			var to_player = (player.global_position - global_position).normalized()
			velocity = to_player * follow_speed
			move_and_slide()
			if to_player.x != 0 and sprite:
				sprite.flip_h = to_player.x < 0
		else:
			velocity = Vector2.ZERO

func _find_nearest_pickup() -> void:
	var candidates: Array = []
	candidates.append_array(get_tree().get_nodes_in_group("exp_gems"))
	candidates.append_array(get_tree().get_nodes_in_group("gold_coins"))
	candidates.append_array(get_tree().get_nodes_in_group("pickups"))
	
	var closest_dist: float = 380.0
	var closest_node: Node2D = null
	for item in candidates:
		if is_instance_valid(item) and item is Node2D:
			var d = global_position.distance_to(item.global_position)
			if d < closest_dist:
				closest_dist = d
				closest_node = item
				
	target_pickup = closest_node
