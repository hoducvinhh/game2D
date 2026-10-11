extends CharacterBody2D
class_name CompanionPet

@export var follow_speed: float = 230.0
@export var pickup_speed: float = 290.0
@export var follow_distance: float = 85.0
@export var pickup_search_radius: float = 600.0
@export var animation_frame_step: float = 169.0
@export var animation_fps: float = 7.0
@export var animation_frames: Array[Texture2D] = []
@export var idle_animation_frame: Texture2D

var player: CharacterBody2D = null
var target_pickup: Node2D = null
var search_timer: float = 0.0
var animation_timer: float = 0.0
var animation_frame: int = 0
var animation_base_rect: Rect2

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	add_to_group("allies")
	add_to_group("companion_pet")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if sprite:
		animation_base_rect = sprite.region_rect
		if not animation_frames.is_empty():
			sprite.region_enabled = false
			sprite.texture = idle_animation_frame if idle_animation_frame else animation_frames[0]

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if is_instance_valid(player):
		_update_animation(delta, player.velocity.length_squared() > 1.0)
	else:
		_update_animation(delta, false)
	if not is_instance_valid(player):
		return
		
	# Tìm vật phẩm xung quanh mỗi 0.35 giây
	search_timer -= delta
	if search_timer <= 0.0:
		search_timer = 0.35
		_find_nearest_pickup()
		
	if is_instance_valid(target_pickup) and (
		target_pickup.is_queued_for_deletion()
		or ("is_magnetized" in target_pickup and target_pickup.is_magnetized)
	):
		target_pickup = null

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
		if dist_to_player > follow_distance:
			var to_player = (player.global_position - global_position).normalized()
			velocity = to_player * follow_speed
			move_and_slide()
			if to_player.x != 0 and sprite:
				sprite.flip_h = to_player.x < 0
		else:
			velocity = Vector2.ZERO

func _update_animation(delta: float, is_player_moving: bool) -> void:
	if not sprite:
		return
	if not animation_frames.is_empty():
		if is_player_moving:
			animation_timer += delta
			if animation_timer >= 1.0 / animation_fps:
				animation_timer = 0.0
				animation_frame = (animation_frame + 1) % animation_frames.size()
				sprite.texture = animation_frames[animation_frame]
		else:
			animation_timer = 0.0
			animation_frame = 0
			sprite.texture = idle_animation_frame if idle_animation_frame else animation_frames[0]
		return

	if is_player_moving:
		animation_timer += delta
		if animation_timer >= 1.0 / animation_fps:
			animation_timer = 0.0
			animation_frame = (animation_frame + 1) % 2
			sprite.region_rect = Rect2(
				animation_base_rect.position.x + animation_frame_step * animation_frame,
				animation_base_rect.position.y,
				animation_base_rect.size.x,
				animation_base_rect.size.y
			)
	else:
		animation_timer = 0.0
		animation_frame = 0
		sprite.region_rect = Rect2(
			animation_base_rect.position.x + animation_frame_step * 2,
			animation_base_rect.position.y,
			animation_base_rect.size.x,
			animation_base_rect.size.y
		)

func _find_nearest_pickup() -> void:
	var candidates: Array = []
	candidates.append_array(get_tree().get_nodes_in_group("exp_gems"))
	candidates.append_array(get_tree().get_nodes_in_group("gold_coins"))
	candidates.append_array(get_tree().get_nodes_in_group("pickups"))
	
	var closest_dist := pickup_search_radius
	var closest_node: Node2D = null
	for item in candidates:
		if not is_instance_valid(item) or not (item is Node2D) or item.is_queued_for_deletion():
			continue
		if "is_magnetized" in item and item.is_magnetized:
			continue
		var d := global_position.distance_to(item.global_position)
		if d < closest_dist:
			closest_dist = d
			closest_node = item
				
	target_pickup = closest_node
