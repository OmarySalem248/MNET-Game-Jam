extends CanvasLayer

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
