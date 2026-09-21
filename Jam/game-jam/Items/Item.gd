class_name Item
extends Resource


@export var id: StringName = &""
@export var name: String = ""
@export var icon: Texture2D
@export var value: int = 0
@export var item_type: ItemType = ItemType.MISC
@export var is_quest_item: bool = false

enum ItemType {
	ORE,
	INGOT,
	MISC
}
