extends Node
# Smooth transition for scene loading/changing

signal in_finished
signal out_finished

func transition_in() -> void:
	$AnimationPlayer.current_animation = "in"
	yield($AnimationPlayer, "animation_finished")
	emit_signal("in_finished")

func transition_out() -> void:
	$AnimationPlayer.current_animation = "out"
	yield($AnimationPlayer, "animation_finished")
	emit_signal("out_finished")
