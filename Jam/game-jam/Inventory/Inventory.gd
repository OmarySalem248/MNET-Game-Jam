extends Resource
class_name Inventory

signal item_added(slot_index: int)
signal item_removed(slot_index: int)
signal item_changed(slot_index: int)
signal inventory_full
signal weight_changed(new_weight: float)

@export var slots: Array[Inventory] = []
@export var max_slots: int = 20
@export var max_weight: float = 100.0

var current_weight: float = 0.0

func _init() -> void:
	_initialize_slots()

func _initialize_slots() -> void:
	slots.clear()
	for i in max_slots:
		slots.append(Inventory.new())

## Attempts to add an item. Returns the number of items that could NOT be added.
func add_item(item: Item, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return amount

	var remaining = amount

	# Check weight limit
	var total_weight_to_add = item.weight * amount
	if current_weight + total_weight_to_add > max_weight:
		# Calculate how many we can actually carry
		var weight_available = max_weight - current_weight
		var can_carry = floori(weight_available / item.weight) if item.weight > 0 else amount
		if can_carry <= 0:
			inventory_full.emit()
			return remaining
		remaining = amount - can_carry
		amount = can_carry

	var to_add = amount

	# First pass: stack with existing items
	if item.max_stack_size > 1:
		for i in slots.size():
			if to_add <= 0:
				break
			if slots[i].item != null and slots[i].item.id == item.id:
				var space = slots[i].available_stack_space()
				if space > 0:
					var add_amount = mini(to_add, space)
					slots[i].quantity += add_amount
					to_add -= add_amount
					item_changed.emit(i)

	# Second pass: fill empty slots
	for i in slots.size():
		if to_add <= 0:
			break
		if slots[i].is_empty():
			var add_amount = mini(to_add, item.max_stack_size)
			slots[i].item = item
			slots[i].quantity = add_amount
			to_add -= add_amount
			item_added.emit(i)

	# Update weight
	var actually_added = amount - to_add
	current_weight += item.weight * actually_added
	weight_changed.emit(current_weight)

	remaining += to_add

	if remaining > 0:
		inventory_full.emit()

	return remaining

## Remove a specific quantity from a slot. Returns true if successful.
func remove_item_at(slot_index: int, amount: int = 1) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false

	var slot = slots[slot_index]
	if slot.is_empty() or amount <= 0 or amount > slot.quantity:
		return false

	var item_weight = slot.item.weight
	slot.quantity -= amount

	if slot.quantity <= 0:
		slot.clear()
		item_removed.emit(slot_index)
	else:
		item_changed.emit(slot_index)

	current_weight -= item_weight * amount
	weight_changed.emit(current_weight)

	return true

## Remove items by ID from anywhere in the inventory. Returns amount actually removed.
func remove_item_by_id(item_id: StringName, amount: int = 1) -> int:
	var removed = 0

	for i in slots.size():
		if removed >= amount:
			break
		if slots[i].item != null and slots[i].item.id == item_id:
			var to_remove = mini(amount - removed, slots[i].quantity)
			remove_item_at(i, to_remove)
			removed += to_remove

	return removed

## Count total quantity of an item across all slots.
func count_item(item_id: StringName) -> int:
	var total = 0
	for slot in slots:
		if slot.item != null and slot.item.id == item_id:
			total += slot.quantity
	return total

## Check if the inventory contains at least `amount` of an item.
func has_item(item_id: StringName, amount: int = 1) -> bool:
	return count_item(item_id) >= amount

## Swap two slots.
func swap_slots(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	if from_index < 0 or from_index >= slots.size():
		return
	if to_index < 0 or to_index >= slots.size():
		return

	var temp_item = slots[to_index].item
	var temp_qty = slots[to_index].quantity

	slots[to_index].item = slots[from_index].item
	slots[to_index].quantity = slots[from_index].quantity

	slots[from_index].item = temp_item
	slots[from_index].quantity = temp_qty

	item_changed.emit(from_index)
	item_changed.emit(to_index)

## Try to merge (stack) from one slot into another. Returns leftover amount.
func merge_slots(from_index: int, to_index: int) -> int:
	if from_index == to_index:
		return slots[from_index].quantity

	var from_slot = slots[from_index]
	var to_slot = slots[to_index]

	if from_slot.is_empty():
		return 0

	# If target is empty, just move
	if to_slot.is_empty():
		swap_slots(from_index, to_index)
		return 0

	# If different items, swap
	if from_slot.item.id != to_slot.item.id:
		swap_slots(from_index, to_index)
		return 0

	# Same item: merge stacks
	var space = to_slot.available_stack_space()
	var transfer = mini(from_slot.quantity, space)

	to_slot.quantity += transfer
	from_slot.quantity -= transfer

	if from_slot.quantity <= 0:
		from_slot.clear()
		item_removed.emit(from_index)
	else:
		item_changed.emit(from_index)

	item_changed.emit(to_index)

	return from_slot.quantity  # Leftover

## Split a stack. Move half to an empty slot.
func split_stack(slot_index: int) -> int:
	var slot = slots[slot_index]
	if slot.is_empty() or slot.quantity <= 1:
		return -1

	# Find an empty slot
	var empty_index = -1
	for i in slots.size():
		if slots[i].is_empty():
			empty_index = i
			break

	if empty_index == -1:
		return -1  # No empty slot

	var split_amount = slot.quantity / 2
	slot.quantity -= split_amount

	slots[empty_index].item = slot.item
	slots[empty_index].quantity = split_amount

	item_changed.emit(slot_index)
	item_added.emit(empty_index)

	return empty_index



func is_full() -> bool:
	for slot in slots:
		if slot.is_empty():
			return false
	return true
