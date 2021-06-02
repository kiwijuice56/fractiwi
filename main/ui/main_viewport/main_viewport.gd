extends Viewport
class_name MainViewport
# Functions as final controller for what is displayed on the screen
# Controller of all main UI controllers

export (NodePath) var root
export (NodePath) var transition
export (NodePath) var music_player
export (NodePath) var save_file
export (NodePath) var game
export (NodePath) var interact
export (NodePath) var main
export (NodePath) var terminal
export (NodePath) var vision_effects
export (NodePath) var world_node

signal battle_start

func _ready() -> void:
	root = get_node(root)
	transition = get_node(transition)
	music_player = get_node(music_player)
	save_file = get_node(save_file)
	game = get_node(game)
	interact = get_node(interact)
	main = get_node(main)
	terminal = get_node(terminal)
	vision_effects = get_node(vision_effects)
	world_node = get_node(world_node)
	yield(get_tree().root, "ready")
	game.disable(false)
	terminal.disable(false)
	save_file.disable(false)
	interact.disable(false)
	music_player.play_audio(main.music)

func battle_started(creatures: Array) -> void:
	transition.transition_in()
	yield(transition, "in_finished")
	emit_signal("battle_start", creatures)
	transition.transition_out()
