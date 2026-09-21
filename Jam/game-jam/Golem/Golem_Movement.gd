extends Node
class_name GolemMovement

signal step_started(from_cell: Vector2i, to_cell: Vector2i)
signal footfall(cell: Vector2i)
signal step_finished(cell: Vector2i)
signal turned(new_facing: Vector2i)
signal blocked(cell: Vector2i)

@export var step_time := 0.4
@export var hold_time := 0.1
@export var turn_time := 0.1

@export var cell_size := 64.0
@export var grid_size := Vector2i(10, 8)
@export var start_cell := Vector2i(4, 4)

@export var manual_control := true
@export var sprite_faces_right := true
@export var thud_sound: AudioStreamPlayer

const SWING_END := 0.75
const STRIDE_DEG := 30.0
const ARM_RATIO := 0.33
const ARM_LAG := 0.05
const BOB_FRAC := 0.03
const IDLE_BOB_FRAC := 0.012
const SQUASH := 0.05
const CARRY_STRIDE := 0.6
const CARRY_SLOWDOWN := 1.25

var cell := Vector2i.ZERO
var facing := Vector2i.RIGHT
var is_moving := false
var carrying := false
var arms_busy := false
var blocked_cells: Array[Vector2i] = []

var rig: GolemRig

var _lead_left := true
var _idle_t := 0.0
var _since_move := 0.0
var _stride_scale := 1.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _root_scale_x := 1.0
var _manual_requested := false


func _ready() -> void:
	_setup_rig()

	if rig == null:
		push_error("GolemMovement: Rig could not be found.")
		return

	reset(start_cell)


func _setup_rig() -> void:
	rig = get_tree().current_scene.find_child(
		"Rig",
		true,
		false
	) as GolemRig

	if rig == null:
		push_error("GolemMovement: Rig node not found.")
		return

	rig.ensure_built()
	rig.visible = true

	_root_scale_x = absf(rig.scale.x)


func cell_to_world(c: Vector2i) -> Vector2:
	return Vector2(c.x, c.y) * cell_size


func is_cell_blocked(c: Vector2i) -> bool:
	return (
		c.x < 0
		or c.y < 0
		or c.x >= grid_size.x
		or c.y >= grid_size.y
		or c in blocked_cells
	)


func reset(to_cell: Vector2i = start_cell) -> void:
	if rig == null:
		return

	cell = to_cell
	facing = Vector2i.RIGHT

	rig.position = cell_to_world(cell)

	rig.visible = true
	rig.scale = Vector2.ONE

	is_moving = false
	carrying = false
	arms_busy = false

	_lead_left = true
	_since_move = 0.0
	_manual_requested = false

	_set_visual_facing(1)

	_set_limb(rig.leg_l, 0.0)
	_set_limb(rig.leg_r, 0.0)
	_set_limb(rig.arm_l, 0.0)
	_set_limb(rig.arm_r, 0.0)

	_set_footfall_pose(0.0)
	_set_upper_offset(0.0)


func turn_to(dir: Vector2i) -> void:
	if dir == Vector2i.ZERO or dir == facing:
		return

	facing = dir
	is_moving = true

	if dir.x != 0:
		_set_visual_facing(dir.x)

	var t := create_tween()

	t.tween_method(
		_turn_squash,
		0.0,
		1.0,
		turn_time
	)

	await t.finished

	is_moving = false
	turned.emit(facing)


func step(dir: Vector2i) -> bool:
	await turn_to(dir)

	var target := cell + dir

	if is_cell_blocked(target):
		is_moving = true
		blocked.emit(target)

		await _bump()

		is_moving = false
		return false

	is_moving = true
	_stride_scale = CARRY_STRIDE if carrying else 1.0

	_from = cell_to_world(cell)
	_to = cell_to_world(target)

	step_started.emit(cell, target)

	var duration := step_time

	if carrying:
		duration *= CARRY_SLOWDOWN

	var t := create_tween()

	t.tween_method(
		_stride_update,
		0.0,
		1.0,
		duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await t.finished

	cell = target
	footfall.emit(cell)

	if thud_sound:
		thud_sound.play()

	var recover := create_tween()

	recover.tween_method(
		_recover,
		1.0,
		0.0,
		hold_time
	)

	await recover.finished

	_lead_left = not _lead_left
	is_moving = false

	step_finished.emit(cell)

	return true


func walk_to(target: Vector2i) -> bool:
	while cell.x != target.x:
		var dir_x := signi(target.x - cell.x)

		if not await step(Vector2i(dir_x, 0)):
			return false

	while cell.y != target.y:
		var dir_y := signi(target.y - cell.y)

		if not await step(Vector2i(0, dir_y)):
			return false

	return true


func _process(delta: float) -> void:
	if rig == null:
		return

	if manual_control:
		_try_manual_move()

	if is_moving:
		_since_move = 0.0
		return

	_since_move += delta
	_idle_t += delta

	if _since_move > 0.12:
		var k := clampf(delta * 12.0, 0.0, 1.0)

		for limb in [rig.leg_l, rig.leg_r]:
			limb.rotation = lerpf(
				limb.rotation,
				0.0,
				k
			)

		if not carrying and not arms_busy:
			for limb in [rig.arm_l, rig.arm_r]:
				limb.rotation = lerpf(
					limb.rotation,
					0.0,
					k
				)

		_set_upper_offset(
			sin(_idle_t * 1.6)
			* IDLE_BOB_FRAC
			* rig.height
		)


func _try_manual_move() -> void:
	if is_moving or _manual_requested:
		return

	var actions: GolemActions = null

	for node in get_tree().current_scene.find_children(
		"*",
		"GolemActions",
		true,
		false
	):
		if node is GolemActions:
			actions = node as GolemActions
			break

	if actions != null and actions.running:
		return

	var dir := Vector2i.ZERO

	if Input.is_key_pressed(KEY_W):
		dir = Vector2i.UP
	elif Input.is_key_pressed(KEY_S):
		dir = Vector2i.DOWN
	elif Input.is_key_pressed(KEY_A):
		dir = Vector2i.LEFT
	elif Input.is_key_pressed(KEY_D):
		dir = Vector2i.RIGHT

	if dir == Vector2i.ZERO:
		return

	_manual_requested = true
	_manual_move(dir)


func _manual_move(dir: Vector2i) -> void:
	await step(dir)
	_manual_requested = false


func _stride_update(p: float) -> void:
	rig.position = _from.lerp(_to, p)

	var swing := clampf(
		p / SWING_END,
		0.0,
		1.0
	)

	var amp := STRIDE_DEG * _stride_scale
	var lead := lerpf(-amp, amp, swing)

	_set_limb(
		rig.leg_l,
		lead if _lead_left else -lead
	)

	_set_limb(
		rig.leg_r,
		-lead if _lead_left else lead
	)

	if not carrying and not arms_busy:
		var lag := clampf(
			(p - ARM_LAG) / SWING_END,
			0.0,
			1.0
		)

		var arm_lead := lerpf(
			-amp * ARM_RATIO,
			amp * ARM_RATIO,
			lag
		)

		_set_limb(
			rig.arm_l,
			-arm_lead if _lead_left else arm_lead
		)

		_set_limb(
			rig.arm_r,
			arm_lead if _lead_left else -arm_lead
		)

	_set_upper_offset(
		-sin(swing * PI)
		* BOB_FRAC
		* rig.height
	)

	var f := clampf(
		(p - SWING_END) / (1.0 - SWING_END),
		0.0,
		1.0
	)

	_set_footfall_pose(f)


func _recover(f: float) -> void:
	_set_footfall_pose(f)
	_set_upper_offset(0.0)


func _bump() -> void:
	var start := rig.position

	var lean := Vector2(
		facing.x,
		facing.y
	) * cell_size * 0.12

	var t := create_tween().set_parallel(true)

	t.tween_method(
		_march_in_place,
		0.0,
		1.0,
		0.3
	)

	t.tween_property(
		rig,
		"position",
		start + lean,
		0.3
	)

	await t.finished

	var t2 := create_tween().set_parallel(true)

	t2.tween_property(
		rig,
		"position",
		start,
		0.2
	)

	t2.tween_method(
		_slump,
		0.0,
		1.0,
		0.2
	)

	await t2.finished

	_set_footfall_pose(0.0)


func _march_in_place(p: float) -> void:
	var s := sin(p * TAU * 2.0) * 20.0

	_set_limb(rig.leg_l, s)
	_set_limb(rig.leg_r, -s)


func _slump(p: float) -> void:
	_set_footfall_pose(
		sin(p * PI) * 2.0
	)


func _turn_squash(p: float) -> void:
	rig.upper.scale = Vector2(
		lerpf(0.85, 1.0, p),
		1.0
	)


func _set_limb(limb: Node2D, forward_deg: float) -> void:
	limb.rotation = deg_to_rad(-forward_deg)


func _set_upper_offset(y: float) -> void:
	rig.upper.position.y = rig.hip_y + y


func _set_footfall_pose(f: float) -> void:
	var a := SQUASH * f

	rig.upper.scale = Vector2(
		1.0 + a,
		1.0 - a
	)

	rig.head.rotation = deg_to_rad(5.0 * f)


func _set_visual_facing(x: int) -> void:
	var flip := (
		x > 0
	) != sprite_faces_right

	rig.scale.x = (
		_root_scale_x
		* (-1.0 if flip else 1.0)
	)
