extends Node2D
class_name Tree

## Drop this on any Tree node in your scene. It plugs straight into
## GolemInteractions: the golem faces the tree and calls
## interactions.interact("chop") (or just "interact" if you don't
## want a dedicated action string), and this script handles the rest.

signal hit(tree: Tree, hits_remaining: int)
signal chopped_down(tree: Tree, wood_amount: int)

@export var cell: Vector2i
@export var max_hits := 3
@export var wood_drop_amount := 3
## Leave empty to allow chopping with bare hands / any held item.
## Set to e.g. "axe" to require a specific tool.
@export var required_tool := ""
@export var stump_scene: PackedScene # optional: swap in a stump when felled

var hits_taken := 0
var is_chopped := false


func _ready() -> void:
	add_to_group("interactable")


func get_cell() -> Vector2i:
	return cell


# Called by GolemInteractions.interact() -> target.on_golem_action(...)
func on_golem_action(action: String, golem: Node, held_item: Variant) -> Dictionary:
	# Accept either a dedicated "chop" action, or the generic "interact"
	# action if you'd rather not add a second key/verb for it.
	if action != "chop" and action != "interact":
		return {"success": false, "reason": "wrong_action"}

	if is_chopped:
		return {"success": false, "reason": "already_chopped"}

	if required_tool != "" and not _item_matches(held_item, required_tool):
		return {"success": false, "reason": "needs_tool", "tool": required_tool}

	hits_taken += 1

	if hits_taken >= max_hits:
		return _fell()

	hit.emit(self, max_hits - hits_taken)
	return {
		"success": true,
		"chopped_down": false,
		"hits_remaining": max_hits - hits_taken
	}


func _item_matches(item: Variant, tool_name: String) -> bool:
	if item == null:
		return false
	if item.has_method("get_item_name"):
		return item.get_item_name() == tool_name
	if "item_name" in item:
		return item.item_name == tool_name
	return false


func _fell() -> Dictionary:
	is_chopped = true
	chopped_down.emit(self, wood_drop_amount)

	if stump_scene != null:
		var stump := stump_scene.instantiate()
		stump.position = position
		get_parent().add_child(stump)

	queue_free()

	return {
		"success": true,
		"chopped_down": true,
		"wood": wood_drop_amount
	}
