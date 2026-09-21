extends Node2D
class_name GolemRig

var upper: Node2D
var head: Node2D
var arm_l: Node2D
var arm_r: Node2D
var leg_l: Node2D
var leg_r: Node2D
var carry: Sprite2D

var height := 150.0
var hip_y := 45.0

var _built := false


func ensure_built() -> void:
	if _built:
		return

	_build_body()
	_built = true


func _ready() -> void:
	ensure_built()


func _build_body() -> void:
	# Main body
	upper = Node2D.new()
	upper.name = "Upper"
	add_child(upper)

	var body := Polygon2D.new()
	body.name = "Body"
	body.polygon = PackedVector2Array([
		Vector2(-24, -45),
		Vector2(24, -45),
		Vector2(28, 42),
		Vector2(-28, 42)
	])
	body.color = Color(0.65, 0.65, 0.65)
	upper.add_child(body)

	# Head
	head = Node2D.new()
	head.name = "Head"
	head.position = Vector2(0, -68)
	upper.add_child(head)

	var head_shape := Polygon2D.new()
	head_shape.name = "HeadShape"
	head_shape.polygon = _circle_points(22.0, 16)
	head_shape.color = Color(0.65, 0.65, 0.65)
	head.add_child(head_shape)

	# Left arm
	arm_l = _make_limb(
		"ArmL",
		Vector2(-27, -35),
		12.0,
		55.0
	)
	upper.add_child(arm_l)

	# Right arm
	arm_r = _make_limb(
		"ArmR",
		Vector2(27, -35),
		12.0,
		55.0
	)
	upper.add_child(arm_r)

	# Left leg
	leg_l = _make_limb(
		"LegL",
		Vector2(-13, 42),
		15.0,
		65.0
	)
	upper.add_child(leg_l)

	# Right leg
	leg_r = _make_limb(
		"LegR",
		Vector2(13, 42),
		15.0,
		65.0
	)
	upper.add_child(leg_r)

	# Carry placeholder
	carry = Sprite2D.new()
	carry.name = "Carry"
	carry.visible = false
	upper.add_child(carry)


func _make_limb(
	node_name: String,
	start: Vector2,
	width: float,
	length: float
) -> Node2D:

	var limb := Node2D.new()
	limb.name = node_name
	limb.position = start

	var shape := Polygon2D.new()
	shape.name = "Shape"

	shape.polygon = PackedVector2Array([
		Vector2(-width / 2.0, 0),
		Vector2(width / 2.0, 0),
		Vector2(width / 2.0, length),
		Vector2(-width / 2.0, length)
	])

	shape.color = Color(0.65, 0.65, 0.65)

	limb.add_child(shape)

	return limb


func _circle_points(radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()

	for i in sides:
		var angle := TAU * float(i) / float(sides)
		points.append(
			Vector2(cos(angle), sin(angle)) * radius
		)

	return points
