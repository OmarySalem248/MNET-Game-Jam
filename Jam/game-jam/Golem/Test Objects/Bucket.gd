extends Node2D

@export var target_name := "bucket"
@export var cell := Vector2i(2, 2)
@export var stand_cell := Vector2i(1, 2)
@export var face_dir := Vector2i.RIGHT
@export var carry_texture: Texture2D

var full := true


func _ready() -> void:
	add_to_group("interactable")
	position = Vector2(cell) * 64.0
	queue_redraw()


func get_cell() -> Vector2i:
	return cell


func get_stand_cell() -> Vector2i:
	return stand_cell


func get_face_dir() -> Vector2i:
	return face_dir


func is_full() -> bool:
	return full


func get_carry_texture() -> Texture2D:
	return carry_texture


func on_golem_action(
	action: String,
	_interactions: GolemInteractions,
	_held: Node
) -> Variant:

	if action == "pick_up":
		remove_from_group("interactable")
		return self

	return null


func _draw() -> void:
	# bucket
	draw_rect(
		Rect2(-22, -12, 44, 30),
		Color(0.65, 0.65, 0.65)
	)

	draw_rect(
		Rect2(-26, -16, 52, 6),
		Color(0.55, 0.55, 0.55)
	)

	draw_arc(
		Vector2(0, -10),
		24.0,
		PI,
		TAU,
		20,
		Color(0.55, 0.55, 0.55),
		4.0
	)
