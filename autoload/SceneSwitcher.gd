extends Node

var transition_data = {}

func goto_scene(scene_path: String, data: Dictionary = {}):
	transition_data = data
	get_tree().change_scene_to_file(scene_path)

func get_transition_data() -> Dictionary:
	return transition_data

func clear_transition_data():
	transition_data = {}
