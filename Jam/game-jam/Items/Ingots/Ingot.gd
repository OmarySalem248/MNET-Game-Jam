extends Item
class_name Ingot

@export var ingot_type: IngotType = IngotType.Misc

enum IngotType { Misc, IRON, GOLD }


func _init() -> void:
	item_type = ItemType.INGOT
