extends Node2D

@export var auto_run := false

const ORDER_TEXT := "VILLAGER ORDER\n\"Fetch water!\""
const MEANT_TEXT := "Bring ONE bucket of water to the pot, then stop."

@onready var golem: Node2D = $Golem
@onready var movement: GolemMovement = $Golem/Movement
@onready var actions: GolemActions = $Golem/Actions
@onready var interactions: GolemInteractions = $Golem/Interactions
@onready var ui: TestUI = $TestUI


func _ready() -> void:
	movement.rig.ensure_built()

	for n in get_tree().get_nodes_in_group("interactable"):
		if n.has_method("get_cell"):
			var c: Vector2i = n.get_cell()

			if c not in movement.blocked_cells:
				movement.blocked_cells.append(c)

	ui.set_order(ORDER_TEXT)
	ui.set_meant(MEANT_TEXT)
	ui.set_status("READY")

	ui.run_pressed.connect(_run)
	ui.stop_pressed.connect(actions.stop)
	ui.reset_pressed.connect(_reset)

	actions.command_started.connect(
		func(cmd):
			ui.add_log(_describe(cmd))
	)

	movement.blocked.connect(
		func(c):
			ui.add_log("Blocked at %s" % str(c))
	)

	interactions.interacted.connect(
		func(target, action):
			ui.add_log(
				"%s: %s" % [
					action,
					target.name
				]
			)
	)

	actions.program_finished.connect(_on_finished)
	actions.program_failed.connect(_on_failed)

	queue_redraw()

	if auto_run:
		await get_tree().create_timer(0.5).timeout
		_run()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:

			if event.keycode == KEY_R:
				_reset()

			elif event.keycode == KEY_SPACE:
				_run()


func _program() -> Array:
	return [
		{
			"type": "walk_to",
			"target": "bucket"
		},
		{
			"type": "pick_up"
		},
		{
			"type": "walk_to",
			"target": "pot"
		},
		{
			"type": "pour"
		},
		{
			"type": "stop"
		}
	]


func _run() -> void:
	if actions.running:
		return

	ui.clear_log()
	ui.set_status("RUNNING...")
	ui.set_running(true)

	actions.run_program(_program())


func _reset() -> void:
	get_tree().reload_current_scene()


func _on_finished() -> void:
	ui.set_status("FINISHED")
	ui.set_running(false)


func _on_failed(reason: String) -> void:
	ui.set_status("DISASTER")
	ui.add_log(reason)
	ui.set_running(false)


func _describe(cmd: Dictionary) -> String:
	match cmd.get("type", ""):

		"walk_to":
			return "walk to %s" % str(cmd.get("target"))

		"pick_up":
			return "pick up"

		"pour":
			return "pour"

		"wait":
			return "wait"

		"repeat_until":
			return "repeat until %s" % str(
				cmd.get("condition")
			)

		"stop":
			return "stop"

	return "?"


func _draw() -> void:
	var c := movement.cell_size
	var g := movement.grid_size

	# floor
	for x in g.x:
		for y in g.y:

			var rect := Rect2(
				Vector2(x, y) * c,
				Vector2(c, c)
			)

			var col := Color(
				0.18,
				0.18,
				0.18
			)

			if (x + y) % 2 == 1:
				col = Color(
					0.21,
					0.21,
					0.21
				)

			draw_rect(rect, col)

			draw_line(
				Vector2(x, y) * c,
				Vector2(x + 1, y) * c,
				Color(0.3, 0.3, 0.3),
				1.0
			)

			draw_line(
				Vector2(x, y) * c,
				Vector2(x, y + 1) * c,
				Color(0.3, 0.3, 0.3),
				1.0
			)

	# border
	draw_rect(
		Rect2(
			Vector2.ZERO,
			Vector2(g) * c
		),
		Color(0.4, 0.4, 0.4),
		false,
		3.0
	)
