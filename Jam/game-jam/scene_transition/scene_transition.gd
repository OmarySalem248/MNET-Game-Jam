extends CanvasLayer

@onready var animator : AnimationPlayer = get_node("ColorRect/AnimationPlayer")
@onready var rect : ColorRect = get_node("ColorRect")
var targ = "res://scenes/world.tscn"

func change_to_scene(target : String):
	visible = true
	animator.play("Grow")
	Engine.time_scale = 0.001
	animator.speed_scale = 1000
	if target != "":
		targ = target
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Grow":
		get_tree().change_scene_to_file(targ)
		animator.play("Ebb")
		animator.speed_scale=1
		Engine.time_scale = 1
	elif anim_name == "Ebb":
		visible = false
	pass # Replace with function body.
