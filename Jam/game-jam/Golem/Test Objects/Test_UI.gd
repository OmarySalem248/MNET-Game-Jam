extends CanvasLayer
class_name TestUI

signal run_pressed
signal stop_pressed
signal reset_pressed

var order_label: Label
var status_label: Label
var meant_label: Label
var did_label: Label

var run_button: Button
var stop_button: Button
var reset_button: Button

const MAX_LOG_LINES := 12
var _lines: Array[String] = []


func _ready() -> void:
	_build()


func set_order(text: String) -> void:
	if order_label:
		order_label.text = text


func set_meant(text: String) -> void:
	if meant_label:
		meant_label.text = text


func set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func add_log(line: String) -> void:
	_lines.append(line)

	if _lines.size() > MAX_LOG_LINES:
		_lines.pop_front()

	if did_label:
		did_label.text = "\n".join(_lines)


func clear_log() -> void:
	_lines.clear()

	if did_label:
		did_label.text = ""


func set_running(running: bool) -> void:
	if run_button:
		run_button.disabled = running

	if stop_button:
		stop_button.disabled = not running


func _build() -> void:
	var panel := PanelContainer.new()
	add_child(panel)

	panel.position = Vector2(18, 18)
	panel.size = Vector2(360, 300)

	var margin := MarginContainer.new()
	panel.add_child(margin)

	margin.add_theme_constant_override(
		"margin_left",
		16
	)

	margin.add_theme_constant_override(
		"margin_right",
		16
	)

	margin.add_theme_constant_override(
		"margin_top",
		14
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		14
	)

	var col := VBoxContainer.new()
	margin.add_child(col)

	order_label = _label(
		col,
		"",
		22
	)

	status_label = _label(
		col,
		"READY",
		16
	)

	_label(
		col,
		"MEANT",
		13
	)

	meant_label = _label(
		col,
		"",
		15
	)

	_label(
		col,
		"DID",
		13
	)

	did_label = _label(
		col,
		"",
		14
	)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	col.add_child(spacer)

	var controls := HBoxContainer.new()
	col.add_child(controls)

	run_button = _button(
		controls,
		"Run",
		run_pressed
	)

	stop_button = _button(
		controls,
		"Stop",
		stop_pressed
	)

	reset_button = _button(
		controls,
		"Reset",
		reset_pressed
	)

	stop_button.disabled = true

	var help := _label(
		col,
		"WASD  Move    SPACE  Run    R  Reset",
		12
	)

	help.modulate = Color(0.7, 0.7, 0.7)


func _label(
	parent: Node,
	text: String,
	size: int
) -> Label:

	var label := Label.new()

	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.add_theme_font_size_override(
		"font_size",
		size
	)

	parent.add_child(label)

	return label


func _button(
	parent: Node,
	text: String,
	sig: Signal
) -> Button:

	var button := Button.new()

	button.text = text
	button.pressed.connect(sig.emit)

	parent.add_child(button)

	return button
