extends Node
class_name GolemInteractions

signal interacted(target: Node, action: String)
signal disaster(reason: String)

@export var goal_cell := Vector2i(5, 4)

var movement: GolemMovement
var actions: GolemActions


func _ready() -> void:
	movement = get_tree().current_scene.find_child(
		"Movement",
		true,
		false
	) as GolemMovement

	actions = get_tree().current_scene.find_child(
		"Actions",
		true,
		false
	) as GolemActions

	if movement == null:
		push_error("GolemInteractions: Movement node not found.")

	if actions == null:
		push_error("GolemInteractions: Actions node not found.")


func front_cell() -> Vector2i:
	return movement.cell + movement.facing


func get_object_at(c: Vector2i) -> Node:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.has_method("get_cell"):
			if n.get_cell() == c:
				return n

	return null


func get_front_object() -> Node:
	return get_object_at(front_cell())


func interact(action: String) -> Dictionary:
	var target := get_front_object()

	if target == null:
		return {
			"hit": false,
			"result": null,
			"target": null
		}

	var result: Variant = null

	if target.has_method("on_golem_action"):
		result = target.on_golem_action(
			action,
			self,
			actions.held_item
		)

	interacted.emit(
		target,
		action
	)

	return {
		"hit": true,
		"result": result,
		"target": target
	}


func raise_disaster(reason: String) -> void:
	disaster.emit(reason)


func resolve_target(target: Variant) -> Dictionary:
	if target is Vector2i:
		return {
			"cell": target,
			"face": Vector2i.ZERO
		}

	if target is String:
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.get("target_name") == target:

				var c: Vector2i = (
					n.get_stand_cell()
					if n.has_method("get_stand_cell")
					else n.get_cell()
				)

				var f: Vector2i = (
					n.get_face_dir()
					if n.has_method("get_face_dir")
					else Vector2i.ZERO
				)

				return {
					"cell": c,
					"face": f
				}

	push_warning(
		"Unknown walk target: %s"
		% str(target)
	)

	return {
		"cell": movement.cell,
		"face": Vector2i.ZERO
	}


func check_condition(condition: String) -> bool:
	match condition:

		"facing_object":
			return get_front_object() != null

		"path_blocked":
			return movement.is_cell_blocked(
				front_cell()
			)

		"at_goal":
			return movement.cell == goal_cell

		"holding_item":
			return actions.held_item != null

		"bucket_full":
			var h = actions.held_item

			return (
				h != null
				and h.has_method("is_full")
				and h.is_full()
			)

		_:
			push_warning(
				"Unknown condition: %s"
				% condition
			)
			if interactions.check_condition("facing_object"):
	var result = interactions.interact("chop")
	if result.hit and result.result.get("chopped_down", false):
		var wood: int = result.result.wood
		# hand wood to inventory here

			return false


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_E):
		if movement != null and actions != null:
			if not movement.is_moving and not actions.running:
				interact("interact")
