extends Node
class_name GolemActions

signal command_started(cmd: Dictionary)
signal command_finished(cmd: Dictionary)
signal program_finished
signal program_failed(reason: String)

const MAX_LOOPS := 200
const STARE_TIME := 0.15
const FREEZE_TIME := 0.5
const REACH_DEG := 50.0
const CARRY_ARM_DEG := 70.0
const POUR_DEG := 105.0

@export var sfx_grab: AudioStreamPlayer
@export var sfx_pour: AudioStreamPlayer

var held_item: Node = null
var running := false
var stop_requested := false
var carry_sprite: Sprite2D

var _failed := false
var _fail_reason := ""

var movement: GolemMovement
var interactions: GolemInteractions


func _ready() -> void:
	# Find Movement
	for node in get_tree().current_scene.find_children("*", "", true, false):
		if node is GolemMovement:
			movement = node as GolemMovement
			break

	# Find Interactions
	for node in get_tree().current_scene.find_children("*", "", true, false):
		if node is GolemInteractions:
			interactions = node as GolemInteractions
			break

	if interactions == null:
		push_error("GolemActions: GolemInteractions script not found.")
		return

	if movement == null:
		push_error("GolemActions: GolemMovement script not found.")
		return

	if movement.rig == null:
		push_error("GolemActions: Rig not found.")
		return

	movement.rig.ensure_built()

	carry_sprite = movement.rig.carry

	if carry_sprite != null:
		carry_sprite.visible = false

	if not interactions.disaster.is_connected(_on_disaster):
		interactions.disaster.connect(_on_disaster)


func _on_disaster(reason: String) -> void:
	if _failed:
		return

	_failed = true
	_fail_reason = reason
	stop_requested = true


func run_program(commands: Array) -> void:
	if running:
		return

	running = true
	stop_requested = false
	_failed = false
	_fail_reason = ""

	await _run_list(commands)

	if _failed:
		await play_failure()

		running = false
		program_failed.emit(_fail_reason)

	else:
		running = false
		program_finished.emit()


func stop() -> void:
	stop_requested = true


func reset_state() -> void:
	held_item = null
	stop_requested = false
	running = false
	_failed = false
	_fail_reason = ""

	if carry_sprite:
		carry_sprite.visible = false

	movement.carrying = false
	movement.arms_busy = false


func play_success() -> void:
	movement.arms_busy = true

	await _tween_arms(150.0, 0.2)

	await get_tree().create_timer(0.4).timeout

	await _tween_arms(
		CARRY_ARM_DEG if held_item else 0.0,
		0.2
	)

	movement.arms_busy = false


func play_failure() -> void:
	movement.arms_busy = true

	var rig := movement.rig
	var base := rig.position

	var t := create_tween()

	for i in 6:
		var offset := (
			4.0
			if i % 2 == 0
			else -4.0
		)

		t.tween_property(
			rig,
			"position",
			base + Vector2(offset, 0.0),
			0.05
		)

	t.tween_property(
		rig,
		"position",
		base,
		0.05
	)

	await t.finished

	await _tween_arms(
		140.0,
		0.15
	)

	movement.arms_busy = false


func _run_list(commands: Array) -> void:
	for cmd in commands:
		if stop_requested or _failed:
			return

		await _run_command(cmd)


func _run_command(cmd: Dictionary) -> void:
	command_started.emit(cmd)

	match cmd.get("type", ""):

		"walk_to":
			await _walk_to(cmd.get("target"))

		"pick_up":
			await pick_up()

		"pour":
			await pour()

		"wait":
			await get_tree().create_timer(
				float(cmd.get("time", 1.0))
			).timeout

		"repeat_until":
			await _repeat_until(cmd)

		"stop":
			stop_requested = true

			await _tween_arms(
				CARRY_ARM_DEG if held_item else 0.0,
				0.2
			)

		_:
			push_warning(
				"Unknown command: %s"
				% str(cmd)
			)

	command_finished.emit(cmd)

	if not stop_requested and not _failed:
		await get_tree().create_timer(
			STARE_TIME
		).timeout


func _walk_to(target: Variant) -> void:
	var dest := interactions.resolve_target(target)

	var arrived: bool = await movement.walk_to(
		dest["cell"]
	)

	if arrived and dest["face"] != Vector2i.ZERO:
		await movement.turn_to(
			dest["face"]
		)


func _repeat_until(cmd: Dictionary) -> void:
	var loops := 0

	while not interactions.check_condition(
		cmd.get("condition", "")
	):

		if stop_requested or _failed:
			return

		if loops >= MAX_LOOPS:
			interactions.raise_disaster(
				"The golem never stopped!"
			)
			return

		await _run_list(
			cmd.get("body", [])
		)

		await get_tree().process_frame

		loops += 1


func pick_up() -> void:
	movement.arms_busy = true

	await _tween_arms(
		REACH_DEG,
		0.25
	)

	if sfx_grab:
		sfx_grab.play()

	var res := interactions.interact(
		"pick_up"
	)

	if res["hit"] and res["result"] is Node:
		_hold(res["result"])

	if _failed:
		await get_tree().create_timer(
			FREEZE_TIME
		).timeout

		movement.arms_busy = false
		return

	await get_tree().create_timer(
		0.1
	).timeout

	await _tween_arms(
		CARRY_ARM_DEG if held_item else 0.0,
		0.25
	)

	movement.arms_busy = false


func pour() -> void:
	movement.arms_busy = true

	await _tween_arms(
		CARRY_ARM_DEG,
		0.15
	)

	await _tween_arms(
		POUR_DEG,
		0.3
	)

	if sfx_pour:
		sfx_pour.play()

	interactions.interact("pour")

	if _failed:
		await get_tree().create_timer(
			FREEZE_TIME
		).timeout

		movement.arms_busy = false
		return

	await get_tree().create_timer(
		0.1
	).timeout

	await _tween_arms(
		CARRY_ARM_DEG if held_item else 0.0,
		0.3
	)

	movement.arms_busy = false


func _hold(item: Node) -> void:
	held_item = item
	movement.carrying = true

	if item is CanvasItem:
		item.visible = false

	if carry_sprite == null:
		return

	carry_sprite.visible = true

	if item.has_method("get_carry_texture"):
		var tex = item.get_carry_texture()

		if tex:
			carry_sprite.texture = tex


func _tween_arms(
	forward_deg: float,
	time: float
) -> void:

	var t := create_tween().set_parallel(true)

	for arm in [
		movement.rig.arm_l,
		movement.rig.arm_r
	]:

		t.tween_property(
			arm,
			"rotation",
			deg_to_rad(-forward_deg),
			time
		).set_trans(
			Tween.TRANS_SINE
		).set_ease(
			Tween.EASE_IN_OUT
		)

	await t.finished
