class_name HitEffect
extends Node2D

@onready var splash_particles: CPUParticles2D = $SplashParticles
@onready var spark_particles: CPUParticles2D = $SparkParticles

var flash_radius: float = 0.0
var flash_alpha: float = 0.95
var flash_color: Color = Color.WHITE

func _ready() -> void:
	z_index = 25
	# Pick random vivid highlight color for the shockwave ring
	var highlight_colors = [
		Color(1.0, 0.25, 0.35), # Crimson / Pink
		Color(0.2, 0.9, 1.0),   # Neon Cyan
		Color(1.0, 0.9, 0.1),   # Gold
		Color(0.3, 1.0, 0.4),   # Bright Lime
		Color(1.0, 0.3, 0.9)    # Hot Magenta
	]
	flash_color = highlight_colors.pick_random()
	
	if splash_particles:
		splash_particles.emitting = true
	if spark_particles:
		spark_particles.emitting = true
	
	# Animate impact ring
	var tw = create_tween()
	tw.tween_property(self, "flash_radius", 28.0, 0.12).from(4.0)
	tw.parallel().tween_property(self, "flash_alpha", 0.0, 0.12)
	
	# Clean up after particles finish
	var tree := get_tree()
	if tree:
		tree.create_timer(0.42).timeout.connect(_on_timeout)

func _process(_delta: float) -> void:
	if flash_alpha > 0.0:
		queue_redraw()

func _draw() -> void:
	if flash_alpha > 0.01:
		var ring_color = flash_color
		ring_color.a = flash_alpha
		draw_arc(Vector2.ZERO, flash_radius, 0.0, TAU, 24, ring_color, 2.5)
		
		# Center bright spark dot
		var center_c = Color(1.0, 1.0, 1.0, flash_alpha * 0.9)
		draw_circle(Vector2.ZERO, maxf(1.0, 6.0 - flash_radius * 0.18), center_c)

func _on_timeout() -> void:
	if is_instance_valid(self):
		queue_free()
