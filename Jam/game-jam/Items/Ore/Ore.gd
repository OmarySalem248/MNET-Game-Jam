extends Item
class_name Ore

@export var ore_type: OreType = OreType.Misc



enum OreType { Misc, IRON, GOLD }


func _init() -> void:
	item_type = ItemType.ORE
	
func _smelt() -> Ingot:
	var ingot = GenericIngot
	return ingot
	
