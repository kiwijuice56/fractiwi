extends Node
class_name Items

var current_effect := "Normal"
var effects: Array = ["Normal"]
var consumables: Dictionary
var money := 0

func get_off() -> Dictionary:
	return get_node("Effects").get_node(current_effect).off_affinities

func get_def() -> Dictionary:
	return get_node("Effects").get_node(current_effect).def_affinities

func get_effect_skill_node() -> Node:
	return get_node("Effects").get_node(current_effect)

func get_effect_skill_names() -> Dictionary:
	var effect_skill_names := {}
	for effect in $Effects.get_children():
		effect_skill_names[effect.name] = {"Unlearned" : effect.get_skill_names("all"),
											"Skill Levels": effect.skill_levels}
	return effect_skill_names

func set_effect_skills(data: Dictionary) -> void:
	for effect in $Effects.get_children():
		if effect.name in data:
			effect.set_skills(data[effect.name])

func add_consumable(skill: String, count: int) -> void:
	if skill in consumables:
		consumables[skill] += count
	else:
		consumables[skill] = count

func remove_consumable(skill: String) -> void:
	if skill in consumables:
		consumables[skill] -= 1
	if consumables[skill] <= 0:
		consumables.erase(skill)

func save_data() -> Dictionary:
	return {"effects": effects, "effect_skills": get_effect_skill_names(), "current_effect": current_effect,
			"consumables": consumables, "money": money}

func load_data(data: Dictionary) -> void:
	effects = data["effects"]
	consumables = data["consumables"]
	money = data["money"]
	set_effect_skills(data["effect_skills"])
	get_viewport().world_node.player.set_effect(data["current_effect"], false)
