extends Node2D

@export var target_name := "pot"
@export var cell := Vector2i(6, 4)
@export var stand_cell := Vector2i(5, 4)
@export var face_dir := Vector2i.RIGHT
@export var capacity := 3

var pours := 0


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


func on_golem_action(
	action: String,
	interactions: GolemInteractions,
	_held: Node
) -> Variant:

	if action == "pour":
		pours += 1
		queue_redraw()

		if pours > capacity:
			interactions.raise_disaster(
				"The pot overflowed. Water everywhere."
			)

	return null


func _draw() -> void:
	# pot
	draw_rect(
		Rect2(-24, -18, 48, 40),
		Color(0.65, 0.65, 0.65)
	)

	draw_rect(
		Rect2(-29, -22, 58, 7),
		Color(0.55, 0.55, 0.55)
	)

	# water
	var fill := clampf(
		float(pours) / float(capacity),
		0.0,
		1.0
	)

	draw_rect(
		Rect2(
			-18,
			16 - 30 * fill,
			36,
			30 * fill
		),
		Color(0.75, 0.75, 0.75)
	)

	if pours > capacity:
		draw_rect(
			Rect2(-32, -28, 64, 56),
			Color(0.45, 0.45, 0.45),
			false,
			4.0
		)
