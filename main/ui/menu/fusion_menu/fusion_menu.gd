extends UIController
class_name FusionMenu

export (NodePath) var level_label
export (NodePath) var prompt_label
export (NodePath) var creature_fusion

var ingredient1: Creature
var ingredient2: Creature
var party: Array
var results: Array

signal creature_chosen(creature)

func _ready() -> void:
	level_label = get_node(level_label)
	prompt_label = get_node(prompt_label)
	creature_fusion = get_node(creature_fusion)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel", false) and not disabled:
		if state == "selecting" and ingredient1:
			ingredient1 = null
			ingredient2 = null
			emit_signal("creature_chosen", null)
			set_up("fuse")
			return
		main_viewport.transition.transition_in()
		._input(event)
		disable(true)
		yield(main_viewport.transition, "in_finished")
		disable(false)
		back.enable(true)
		main_viewport.transition.transition_out()
	if event.is_action_pressed("ui_accept", false) and not disabled and state == "selecting":
		emit_signal("creature_chosen", input["IngredientPanelContainer"].creatures[get_focus_owner().get_index()])
		get_focus_owner().selected = true
		get_focus_owner().focus_entered()

func update_ingredients() -> void:
	party = main_viewport.party.get_node("Active").get_children() + main_viewport.party.get_node("Inactive").get_children()
	party.remove(party.find(main_viewport.party.get_node("Active/Yun")))
	input["IngredientPanelContainer"].creatures = party
	input["IngredientPanelContainer"].add_items()

func update_results() -> void:
	if ingredient1:
		results = []
		for member in party:
			results.append(creature_fusion.fuse(member, ingredient1))
		input["ResultPanelContainer"].creatures = results
		input["ResultPanelContainer"].add_items()
	else:
		input["ResultPanelContainer"].creatures = []
		input["ResultPanelContainer"].add_items()

func set_up(event: String) -> void:
	ingredient1 = null
	ingredient2 = null
	update_ingredients()
	update_results()
	level_label.text = "lvl " + str(main_viewport.party.get_node("Active/Yun").level)
	match event:
		"fuse":
			input["IngredientPanelContainer"].grab_focus_at(0)
			prompt_label.text = "Select the first ingredient .."
			input["HotKeyContainer"].hotkeys = {"Confirm Ingredient": "ui_accept","Select Creature": "up_down"}
			input["HotKeyContainer"].add_items()
			ingredient1 = yield(select_creature(), "completed")
			if ingredient1 == null:
				return
			update_results()
			while not (ingredient2):
				prompt_label.text = "Select the second ingredient .."
				input["HotKeyContainer"].hotkeys = {"Confirm Ingredient": "ui_accept","Select Creature": "up_down", "Reset Ingredient": "ui_cancel"}
				input["HotKeyContainer"].add_items()
				ingredient2 = yield(select_creature(), "completed")
				if ingredient2 == null:
					return
				if ingredient1 == ingredient2:
					ingredient2 = null
			print("woohoo!")
		"banish":
			prompt_label.text = "Select a creature to banish .."

func select_creature() -> Creature:
	set_process_input(true)
	state = "selecting"
	var creature = yield(self, "creature_chosen")
	return creature