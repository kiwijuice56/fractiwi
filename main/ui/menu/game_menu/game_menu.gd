extends UIController
class_name GameMenu
# Main controller for combat/game UI 

export(NodePath) var pop_out_party
export(NodePath) var party
export(NodePath) var enemy_party
export(NodePath) var effect_handler
export(NodePath) var action_selection
export(NodePath) var effect_selection
export(NodePath) var press_turn_container
export(NodePath) var selector
export(NodePath) var label_container
export(NodePath) var text_label
export(NodePath) var skill_description_label
export(NodePath) var item_selection
export(NodePath) var item_description_label
export(NodePath) var cash_label
export(NodePath) var effect_progress
export(NodePath) var stock_label

var open := false
var can_open := false
var in_battle := false
var creature: Creature

signal battle_action_chosen
signal selection_complete
signal battle_ready

func _ready():
	party = get_node(party)
	enemy_party = get_node(enemy_party)
	pop_out_party = get_node(pop_out_party)
	effect_handler = get_node(effect_handler)
	action_selection = get_node(action_selection)
	effect_selection = get_node(effect_selection)
	press_turn_container = get_node(press_turn_container)
	selector = get_node(selector)
	label_container = get_node(label_container)
	text_label = get_node(text_label)
	skill_description_label = get_node(skill_description_label)
	item_selection = get_node(item_selection)
	item_description_label = get_node(item_description_label)
	cash_label = get_node(cash_label)
	effect_progress = get_node(effect_progress)
	stock_label = get_node(stock_label)
	main_viewport.connect("battle_start", self, "battle_started")
	main_viewport.connect("battle_end", self, "battle_ended")
	connect("battle_action_chosen", self, "battle_action_chosen")
	yield(get_tree().root, "ready")
	close_menu()

func _input(event: InputEvent) -> void:
	if disabled: return
	if event.is_action_pressed("open_menu", false) and can_open and not in_battle:
		if open:
			close_menu()
			main_viewport.world_node.unpause()
			main_viewport.world_node.player.can_move = true
			main_viewport.menu_sound_player.play_sound("Back")
		else:
			open_menu(true)
			main_viewport.world_node.pause()
			main_viewport.world_node.player.can_move = false
			main_viewport.menu_sound_player.play_sound("Next")
	if not open:
		return
	if event.is_action_pressed("ui_cancel", false) and open: 
		input_pressed("Back")
		

func input_pressed(key_name: String) -> void:
	if disabled or not open: return
	match(key_name):
		"Effect":
			main_viewport.menu_sound_player.play_sound("Next")
			show_effects()
		"Set Effect":
			update_effect(get_focus_owner().name)
		"Party":
			match state:
				"default": 
					main_viewport.menu_sound_player.play_sound("Next")
					show_party(true)
		"Back":
			match state:
				"party":
					hide_party()
					input["MainButtonContainer"].enable_input()
					disable_nonplayer_action()
					if not in_battle:
						input["MainButtonContainer"].grab_focus_at(3)
					else:
						input["MainButtonContainer"].grab_focus_at(2)
				"items":
					hide_items()
					input["MainButtonContainer"].enable_input()
					disable_nonplayer_action()
					if not in_battle:
						input["MainButtonContainer"].grab_focus_at(2)
					else:
						input["MainButtonContainer"].grab_focus_at(1)
				"skills":
					hide_skills()
					input["MainButtonContainer"].enable_input()
					disable_nonplayer_action()
					if not in_battle:
						input["MainButtonContainer"].grab_focus_at(1)
					else:
						input["MainButtonContainer"].grab_focus_at(0)
				"effects":
					hide_effects()
					input["MainButtonContainer"].enable_input()
					disable_nonplayer_action()
					input["MainButtonContainer"].grab_focus_at(0)
				"return_member":
					show_party(false)
				"default":
					if in_battle: return
					close_menu()
					main_viewport.world_node.unpause()
					main_viewport.world_node.player.can_move = true
				"select_active_member":
					emit_signal("selection_complete", [])
					for active in input["ActivePartyContainer"].get_children():
						if "focused_style" in active:
							active.focus_style_lock = false
							active.focus_exited()
					input["PartySelectHotKeyContainer"].disable_input()
					input["PartySelectHotKeyContainer"].visible = false
				"select_self_only":
					emit_signal("selection_complete", [])
					for active in input["ActivePartyContainer"].get_children():
						
						if "focused_style" in active:
							active.focus_style_lock = false
							active.focus_exited()
					input["PartySelectHotKeyContainer"].disable_input()
					input["PartySelectHotKeyContainer"].visible = false
		"Item":
			match state:
				"default":
					main_viewport.menu_sound_player.play_sound("Next")
					show_items()
		"Skill":
			match state:
				"default":
					main_viewport.menu_sound_player.play_sound("Next")
					if not in_battle:
						creature = party.get_node("Active").get_child(0)
					show_skills()
		"Summon":
			match state:
				"party":
					summon_member()
		"Check":
			main_viewport.menu_sound_player.play_sound("Next")
			match state:
				"party":
					show_check_screen()
					main_viewport.menu_sound_player.play_sound("Next")
		"Recruit":
			input["MainButtonContainer"].disable_input()
			get_focus_owner().release_focus()
			main_viewport.menu_sound_player.play_sound("Next")
			state = "selection"
			set_process_input(false)
			var targets: Array = yield(selector.select("single", "opposite"), "completed")
			set_process_input(true)
			if len(targets) == 0:
				input["MainButtonContainer"].enable_input()
				input["MainButtonContainer"].grab_focus_at(5)
				state = "default"
				return
			emit_signal("battle_action_chosen", ["Recruit", null, targets])
		"Pass":
			main_viewport.menu_sound_player.play_sound("Next")
			emit_signal("battle_action_chosen", ["Pass", null, []])
		"Run":
			main_viewport.menu_sound_player.play_sound("Next")
			emit_signal("battle_action_chosen", ["Run", null, []])
		"Confirm":
			main_viewport.menu_sound_player.play_sound("Next")
			if state == "select_active_member":
				emit_signal("selection_complete", [get_focus_owner().creature])
				for active in input["ActivePartyContainer"].get_children():
					if "focus_style" in active:
						active.focus_style_lock = false
						active.focus_exited()
				input["PartySelectHotKeyContainer"].disable_input()
				input["PartySelectHotKeyContainer"].visible = false
			elif state == "select_self_only":
				emit_signal("selection_complete", [creature])
				for active in input["ActivePartyContainer"].get_children():
					if "focus_style" in active:
						active.focus_style_lock = false
						active.focus_exited()
				input["PartySelectHotKeyContainer"].disable_input()
				input["PartySelectHotKeyContainer"].visible = false
		"Use":
			if state == "skills":
				if not get_focus_owner():
					main_viewport.menu_sound_player.play_sound("Can't")
					return
				var skill: Skill = get_focus_owner().skill
				if get_focus_owner().disabled:
					return
				if skill.cost_type == "mp":
					if skill.cost > creature.get(skill.cost_type):
						main_viewport.menu_sound_player.play_sound("Can't")
						return
				elif skill.cost_type == "hp":
					if skill.cost >= creature.get(skill.cost_type): #can't kill self
						main_viewport.menu_sound_player.play_sound("Can't")
						return
				main_viewport.menu_sound_player.play_sound("Next")
				hide_skills()
				state = "selection"
				set_process_input(false)
				var targets: Array = yield(selector.select(skill.target_type, skill.side), "completed")
				set_process_input(true)
				if len(targets) == 0:
					show_skills()
					return
				emit_signal("battle_action_chosen", ["Skill", skill, targets])
				if not in_battle:
					skill.use(creature, targets, true)
				yield(skill, "use_complete")
				if not in_battle:
					enable(true)
					show_skills()
			if state == "items":
				if not get_focus_owner():
					main_viewport.menu_sound_player.play_sound("Can't")
					return
				var skill: Skill = get_focus_owner().skill
				if get_focus_owner().disabled:
					return
				add_child(skill)
				main_viewport.menu_sound_player.play_sound("Next")
				hide_items()
				state = "selection"
				set_process_input(false)
				var targets: Array = yield(selector.select(skill.target_type, skill.side), "completed")
				set_process_input(true)
				if len(targets) == 0:
					show_items()
					remove_child(skill)
					return
				main_viewport.items.remove_consumable(skill.name)
				emit_signal("battle_action_chosen", ["Skill", skill, targets])
				if not in_battle:
					skill.use(main_viewport.party.get_node("Active").get_child(0), targets, true)
				yield(skill, "use_complete")
				if not in_battle:
					enable(true)
					show_items()
				remove_child(skill)
				skill.queue_free()

func battle_started(_creatures: Array) -> void:
	yield(get_viewport().transition, "in_finished")
	in_battle = true
	input["PartySkillContainer"].tabs_visible = false
	press_turn_container.visible = true
	input["MainButtonContainer"].button_names = ["Skill", "Item", "Party", "Pass", "Run", "Recruit"]
	input["MainButtonContainer"].add_items()
	disable(true)
	open_menu(true)
	emit_signal("battle_ready")

func battle_ended(_did_run: bool) -> void:
	yield(main_viewport.transition, "in_finished")
	in_battle = false
	creature = null
	input["PartySkillContainer"].tabs_visible = true
	press_turn_container.visible = false
	input["MainButtonContainer"].button_names = ["Effect", "Skill", "Item", "Party"]
	input["MainButtonContainer"].add_items()
	disable(false)
	close_menu()
	enable(false)
	visible = false

func battle_input(current_creature: Creature):
	creature = current_creature
	text_label.text = "What will %s do?" % creature.creature_name
	input["MainButtonContainer"].enable_input()
	input["MainButtonContainer"].grab_focus_at(0)
	disable_nonplayer_action()
	open_menu(false)

func disable_nonplayer_action() -> void:
	for button in input["MainButtonContainer"].get_children():
		# always enabled
		if button.text == "Skill" or button.text == "Pass" or button.text == "Run":
			button.disabled = false
			continue
		# player has all actions
		elif (not in_battle) or creature.name == "Yun":
			button.disabled = false
			continue
		#item know-how
		if button.text == "Item" and creature.item_use:
			button.disabled = false
			continue
		button.disabled = true

func battle_action_chosen(_ui_info: Array) -> void:
	text_label.text = ""
	disable(true)

func open_menu(anim: bool) -> void:
	state = "default"
	enable(true)
	main_viewport.interact.disable(false)
	if anim:
		effect_handler.fade(self, "visible", effect_handler.default_fade_time)
	if not in_battle:
		input["MainButtonContainer"].enable_input()
		input["MainButtonContainer"].grab_focus_at(0)
	open = true

func close_menu() -> void:
	hide_party()
	hide_skills()
	hide_effects()
	hide_items()
	effect_handler.fade(self, "hide", effect_handler.default_fade_time)
	input["MainButtonContainer"].disable_input()
	open = false

func show_items() -> void:
	input["MainButtonContainer"].disable_input()
	input["ActionHotkeyContainer"].enable_input()
	input["ItemContainer"].add_items()
	input["ItemContainer"].enable_input()
	cash_label.text = "$" + str(get_viewport().items.money)
	if not in_battle:
		input["ItemContainer"].disable_overworld()
	if len(main_viewport.items.consumables):
		input["ItemContainer"].grab_focus_at(0)
	else:
		if get_focus_owner():
			get_focus_owner().release_focus()
	effect_handler.fade(item_selection, "visible", effect_handler.default_fade_time)
	state = "items"

func hide_items() -> void:
	input["ActionHotkeyContainer"].disable_input()
	input["ItemContainer"].disable_input()
	effect_handler.fade(item_selection, "hide", effect_handler.default_fade_time)
	state = "default"

func show_skills() -> void:
	input["MainButtonContainer"].disable_input()
	input["ActionHotkeyContainer"].enable_input()
	input["PartySkillContainer"].add_items()
	input["PartySkillContainer"].enable_input()
	if not in_battle:
		input[creature.creature_name].enable_input()
		input["PartySkillContainer"].setting_disable(input["PartySkillContainer"].get_node(creature.creature_name))
		input[creature.creature_name].grab_focus_at(0)
	else:
		input["PartySkillContainer"].current_tab = creature.get_index()
		input[creature.creature_name].enable_input()
		input["PartySkillContainer"].setting_disable(input[creature.creature_name])
		input[creature.creature_name].grab_focus_at(0)
	effect_handler.fade(action_selection, "visible", effect_handler.default_fade_time)
	state = "skills"

func hide_skills() -> void:
	input["ActionHotkeyContainer"].disable_input()
	input["PartySkillContainer"].get_child(input["PartySkillContainer"].current_tab).disable_input()
	input["PartySkillContainer"].disable_input()
	effect_handler.fade(action_selection, "hide", effect_handler.default_fade_time)
	state = "default"

func show_effects() -> void:
	input["MainButtonContainer"].disable_input()
	input["EffectHotkeyContainer"].enable_input()
	input["EffectButtonContainer"].enable_input()
	input["EffectButtonContainer"].add_items()
	input["EffectButtonContainer"].grab_focus_at(0)
	effect_progress.max_value = main_viewport.items.get_node("Effects").get_child_count()
	effect_progress.value = len(main_viewport.items.effects)
	effect_handler.fade(effect_selection, "visible", effect_handler.default_fade_time)
	state = "effects"

func hide_effects() -> void:
	input["EffectButtonContainer"].disable_input()
	input["EffectHotkeyContainer"].disable_input()
	effect_handler.fade(effect_selection, "hide", effect_handler.default_fade_time)
	state = "default"

func update_effect(effect: String) -> void:
	close_menu()
	get_viewport().world_node.player.set_effect(effect, true)

func summon_member() -> void:
	var creature_button := get_focus_owner()
	if party.in_active_party(creature_button.creature):
		return_member()
		return
	var scroll = input["FullPartyContainer"].get_parent().get_h_scroll()
	var index := creature_button.get_index()
	var success: bool = party.summon_member(creature_button.creature)
	if success:
		update_party()
		main_viewport.menu_sound_player.play_sound("Summon")
		input["FullPartyContainer"].grab_focus_at(index)
		input["FullPartyContainer"].get_parent().set_h_scroll(scroll)
		if in_battle:
			hide_party()
			yield(effect_handler, "complete")
			emit_signal("battle_action_chosen", ["Summon", null, []])
	else:
		main_viewport.menu_sound_player.play_sound("Can't")

func return_member():
	var creature_button := get_focus_owner()
	var scroll = input["FullPartyContainer"].get_parent().get_h_scroll()
	var index := creature_button.get_index()
	var success: bool = party.return_member(creature_button.creature)
	if success:
		main_viewport.menu_sound_player.play_sound("Summon")
		update_party()
		input["FullPartyContainer"].grab_focus_at(index)
		input["FullPartyContainer"].get_parent().set_h_scroll(scroll)
		if in_battle:
			hide_party()
			yield(effect_handler, "complete")
			emit_signal("battle_action_chosen", ["Return", null, []])
	else:
		main_viewport.menu_sound_player.play_sound("Can't")

func select_active_member() -> void:
	input["PartyHotKeyContainer"].disable_input()
	input["PartyHotKeyContainer"].visible = false
	input["ActivePartyContainer"].grab_focus_at(0)
	input["PartySelectHotKeyContainer"].enable_input()
	input["PartySelectHotKeyContainer"].visible = true
	state = "select_active_member"

func select_self_only() -> void:
	input["PartyHotKeyContainer"].disable_input()
	input["PartyHotKeyContainer"].visible = false
	get_focus_owner().release_focus()
	input["ActivePartyContainer"].get_child(creature.get_index()).focus_entered()
	input["PartySelectHotKeyContainer"].enable_input()
	input["PartySelectHotKeyContainer"].visible = true
	state = "select_self_only"

func select_all_active() -> void:
	select_active_member()
	for active in input["ActivePartyContainer"].get_children():
		if "focused_style" in active:
			active.focus_entered()
			active.focus_style_lock = true

func show_party(anim: bool) -> void:
	if anim:
		effect_handler.slide(self, "y", 0, effect_handler.default_slide_time)
	update_party()
	input["MainButtonContainer"].disable_input()
	input["PartyHotKeyContainer"].enable_input()
	input["PartyHotKeyContainer"].visible = true
	input["PartySelectHotKeyContainer"].disable_input()
	input["PartySelectHotKeyContainer"].visible = false
	input["FullPartyContainer"].grab_focus_at(0)
	stock_label.text = str(main_viewport.party.get_node("Active").get_child_count() + main_viewport.party.get_node("Inactive").get_child_count()) + "/12"
	state = "party"

func hide_party() -> void:
	effect_handler.slide(self, "y", pop_out_party.rect_size.y, effect_handler.default_slide_time)
	input["PartyHotKeyContainer"].disable_input()
	state = "default"

func show_check_screen() -> void:
	var focus = get_focus_owner()
	disable(true)
	main_viewport.transition.transition_in()
	yield(main_viewport.transition, "in_finished")
	main_viewport.creature_check.enable(true)
	main_viewport.creature_check.index = focus.get_index()
	main_viewport.creature_check.open()
	main_viewport.creature_check.show_creature(focus.creature)
	main_viewport.creature_check.back = self
	disable(false)
	main_viewport.transition.transition_out()
	state = "check_screen"

func update_party() -> void:
	input["FullPartyContainer"].add_items()
	input["ActivePartyContainer"].add_items()

func enable(show: bool) -> void:
	.enable(show)
	self.can_open = true

func disable(show: bool) -> void:
	.disable(show)
	input["MainButtonContainer"].disable_input()
	self.can_open = false
