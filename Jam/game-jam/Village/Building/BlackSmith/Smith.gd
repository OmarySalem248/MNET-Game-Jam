extends Building
class_name Smith


func _init() -> void:
	building_type = BuildingType.SMITH


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func _smeltore(ore) -> Ingot:
	return ore._smelt()
