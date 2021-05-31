extends UIController
class_name TerminalMenu

func input_pressed(key_name: String) -> void:
	
	match key_name:
		"Save":
			main_viewport.transition.transition_in()
			yield(main_viewport.transition, "in_finished")
			main_viewport.save_file.enable()
			main_viewport.save_file.set_up("Save")
			main_viewport.save_file.back = self
			main_viewport.transition.transition_out()
		"Load":
			main_viewport.transition.transition_in()
			yield(main_viewport.transition, "in_finished")
			main_viewport.save_file.enable()
			main_viewport.save_file.set_up("Load")
			main_viewport.save_file.back = self
			main_viewport.transition.transition_out()
		"Leave":
			main_viewport.transition.transition_in_heavy()
			yield(main_viewport.transition, "in_finished")
			main_viewport.terminal.disable()
			main_viewport.interact.finish_interaction()
			main_viewport.game.enable()
			main_viewport.transition.transition_out_heavy()

func enable() -> void:
	visible = true
	disabled = false
	input["TextButtonContainer"].enable_input()
	input["TextButtonContainer"].grab_focus_at(0)

func disable() -> void:
	visible = false
	disabled = true
	input["TextButtonContainer"].disable_input()
