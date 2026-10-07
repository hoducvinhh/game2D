extends CanvasLayer
class_name TouchControls

signal attack_pressed
signal dash_pressed
signal ultimate_pressed

@export var max_joystick_radius: float = 65.0
@export var is_dynamic_joystick: bool = false

var joystick_center: Vector2 = Vector2.ZERO
var joystick_vector: Vector2 = Vector2.ZERO
var touch_pointer_id: int = -1

# Cooldowns and Rage
var dash_cooldown: float = 2.0
var dash_timer: float = 0.0
var rage_percent: float = 0.0 # 0.0 to 100.0
const ULTIMATE_ICON_PATH := "res://assets/sprites/ui/btn_utilmate.png"

@onready var root_control: Control = $Control
@onready var joystick_base: Control = $Control/Joystick/Base
@onready var joystick_knob: Control = $Control/Joystick/Knob
@onready var btn_attack: Button = $Control/Actions/BtnAttack
@onready var btn_dash: Button = $Control/Actions/BtnDash
@onready var btn_ultimate: Button = $Control/Actions/BtnUltimate

@onready var dash_cooldown_overlay: ColorRect = $Control/Actions/BtnDash/CooldownOverlay
@onready var ult_glow: Panel = $Control/Actions/BtnUltimate/GlowEffect
@onready var ult_label: Label = $Control/Actions/BtnUltimate/Label

func _ready() -> void:
	layer = 10
	add_to_group("touch_controls")
	if btn_attack: btn_attack.focus_mode = Control.FOCUS_NONE
	if btn_dash: btn_dash.focus_mode = Control.FOCUS_NONE
	if btn_ultimate: btn_ultimate.focus_mode = Control.FOCUS_NONE
	
	btn_attack.button_down.connect(_on_attack_down)
	btn_dash.pressed.connect(_on_dash_pressed)
	btn_ultimate.pressed.connect(_on_ultimate_pressed)

	get_viewport().size_changed.connect(_update_layout)
	call_deferred("_update_layout")
	
	_apply_custom_textures()
	set_controls_visible(GameData.touch_controls_enabled)
	_update_dash_ui()
	_update_ultimate_ui()

func _update_layout() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	if root_control:
		root_control.size = vp_size
		var joy = root_control.get_node_or_null("Joystick")
		if joy:
			joy.position = Vector2(40.0, vp_size.y - 180.0)
		var actions = root_control.get_node_or_null("Actions")
		if actions:
			actions.position = Vector2(vp_size.x - 260.0, vp_size.y - 220.0)
	if joystick_base:
		joystick_center = joystick_base.global_position + joystick_base.size * 0.5
		_reset_knob()

func _apply_custom_textures() -> void:
	# Tự động gán ảnh texture tùy chỉnh nếu người dùng thêm vào assets/sprites/ui/
	var joy_base_path := "res://assets/sprites/ui/joystick_base.png"
	if ResourceLoader.exists(joy_base_path):
		var rect = joystick_base.get_node_or_null("TextureRect")
		if not rect:
			rect = TextureRect.new()
			rect.name = "TextureRect"
			rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			joystick_base.add_child(rect)
		rect.texture = load(joy_base_path)

	var joy_knob_path := "res://assets/sprites/ui/joystick_knob.png"
	if ResourceLoader.exists(joy_knob_path):
		var rect = joystick_knob.get_node_or_null("TextureRect")
		if not rect:
			rect = TextureRect.new()
			rect.name = "TextureRect"
			rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			joystick_knob.add_child(rect)
		rect.texture = load(joy_knob_path)

	var btn_attack_path := "res://assets/sprites/ui/btn_attack.png"
	if ResourceLoader.exists(btn_attack_path):
		btn_attack.icon = load(btn_attack_path)
		btn_attack.expand_icon = true
		btn_attack.text = ""

	var btn_dash_path := "res://assets/sprites/ui/btn_dash.png"
	if ResourceLoader.exists(btn_dash_path):
		btn_dash.icon = load(btn_dash_path)
		btn_dash.expand_icon = true
		btn_dash.text = ""

	if ResourceLoader.exists(ULTIMATE_ICON_PATH):
		btn_ultimate.icon = load(ULTIMATE_ICON_PATH)
		btn_ultimate.expand_icon = true
		if ult_label:
			ult_label.position.y = 20 # Dời chữ xuống dưới chân icon


func _process(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		_update_dash_ui()

func _input(event: InputEvent) -> void:
	# Virtual Joystick Touch/Mouse Input
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if touch is on left half of screen
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.5:
				if touch_pointer_id == -1:
					touch_pointer_id = event.index
					if is_dynamic_joystick:
						joystick_base.global_position = event.position - joystick_base.size * 0.5
						joystick_center = event.position
					_update_joystick(event.position)
		else:
			if event.index == touch_pointer_id:
				touch_pointer_id = -1
				_reset_knob()
				
	elif event is InputEventScreenDrag:
		if event.index == touch_pointer_id:
			_update_joystick(event.position)
			
	# Fallback for PC mouse testing on left bottom area
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local_pos = event.position
				if local_pos.x < 350 and local_pos.y > get_viewport().get_visible_rect().size.y - 350:
					touch_pointer_id = 999
					_update_joystick(event.position)
			else:
				if touch_pointer_id == 999:
					touch_pointer_id = -1
					_reset_knob()
	elif event is InputEventMouseMotion and touch_pointer_id == 999:
		_update_joystick(event.position)

func _update_joystick(pos: Vector2) -> void:
	var diff = pos - joystick_center
	var dist = diff.length()
	if dist > max_joystick_radius:
		diff = diff.normalized() * max_joystick_radius
	
	joystick_vector = diff / max_joystick_radius
	joystick_knob.global_position = joystick_center + diff - joystick_knob.size * 0.5

func _reset_knob() -> void:
	joystick_vector = Vector2.ZERO
	if joystick_knob:
		var target_pos = joystick_center - joystick_knob.size * 0.5
		var tween = create_tween()
		tween.tween_property(joystick_knob, "global_position", target_pos, 0.1).set_trans(Tween.TRANS_QUAD)

func get_joystick_vector() -> Vector2:
	return joystick_vector

func _on_attack_down() -> void:
	attack_pressed.emit()
	_animate_button_pop(btn_attack)

func _on_dash_pressed() -> void:
	if dash_timer <= 0.0:
		notify_dash_used()
		dash_pressed.emit()
		_animate_button_pop(btn_dash)

func notify_dash_used() -> void:
	dash_timer = dash_cooldown
	_update_dash_ui()

func _on_ultimate_pressed() -> void:
	if rage_percent >= 100.0:
		ultimate_pressed.emit()
		_animate_button_pop(btn_ultimate)

func consume_rage() -> bool:
	if rage_percent < 100.0:
		return false
	rage_percent = 0.0
	_update_ultimate_ui()
	return true

func _animate_button_pop(btn: Button) -> void:
	var tw = create_tween()
	tw.tween_property(btn, "scale", Vector2(0.88, 0.88), 0.05)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)

func add_rage(amount: float) -> void:
	rage_percent = clampf(rage_percent + amount, 0.0, 100.0)
	_update_ultimate_ui()

func _update_dash_ui() -> void:
	if not dash_cooldown_overlay:
		return
	if dash_timer > 0.0:
		dash_cooldown_overlay.visible = true
		dash_cooldown_overlay.scale.y = dash_timer / dash_cooldown
		btn_dash.modulate = Color(0.7, 0.7, 0.7, 0.9)
	else:
		dash_cooldown_overlay.visible = false
		btn_dash.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _update_ultimate_ui() -> void:
	if not btn_ultimate:
		return
	if ult_label:
		ult_label.text = "ULT\n%d%%" % int(rage_percent)
	if rage_percent >= 100.0:
		btn_ultimate.modulate = Color(1.3, 1.1, 0.5)
		if ult_glow:
			ult_glow.visible = true
	else:
		btn_ultimate.modulate = Color(0.8, 0.8, 0.85, 0.75)
		if ult_glow:
			ult_glow.visible = false

func set_controls_visible(enabled: bool) -> void:
	if root_control:
		root_control.visible = enabled
