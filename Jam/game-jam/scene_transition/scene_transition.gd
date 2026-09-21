extends CanvasLayer

<<<<<<< HEAD
@onready var animator : AnimationPlayer = get_node("ColorRect/AnimationPlayer")
@onready var rect : ColorRect = get_node("ColorRect")
var targ = "res://scenes/levels/1.tscn"

func change_to_scene(target : String):
	visible = true
	animator.play("Grow")
	Engine.time_scale = 0.001
	animator.speed_scale = 1000
	if target != "":
		targ = target
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Grow":
		get_tree().change_scene_to_file(targ)
		animator.play("Ebb")
		animator.speed_scale=1
		Engine.time_scale = 1
	elif anim_name == "Ebb":
		visible = false
	pass # Replace with function body.
=======
@export var transition_time := 0.5

@onready var color_rect: ColorRect = $ColorRect
@onready var material: ShaderMaterial = color_rect.material


func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if material:
		material.set_shader_parameter("t", 1.0)


func fade_out() -> void:
	if material == null:
		return

	var tween := create_tween()

	tween.tween_method(
		_set_transition,
		1.0,
		0.0,
		transition_time
	)

	await tween.finished


func fade_in() -> void:
	if material == null:
		return

	var tween := create_tween()

	tween.tween_method(
		_set_transition,
		0.0,
		1.0,
		transition_time
	)

	await tween.finished


func _set_transition(value: float) -> void:
	material.set_shader_parameter("t", value)
>>>>>>> Ads
