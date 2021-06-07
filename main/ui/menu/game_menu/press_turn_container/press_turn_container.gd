extends Control
class_name PressTurnContainer
# Sets UI for press turns

export var p_color: Color
export var e_color: Color

func set_side(is_player: bool) -> void:
	if is_player:
		$HBoxContainer.modulate = p_color
	else:
		$HBoxContainer.modulate = e_color

func set_turns(full: int, half: int) -> void:
	for child in $HBoxContainer.get_children():
		var i: int = child.get_index()
		if i == 8:
			return
		if i < full+half:
			child.set_visible(true)
			if i >= full:
				child.set_half(true)
			else:
				child.set_half(false)
		else:
			child.set_visible(false)
			child.set_half(false)
