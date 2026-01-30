extends Node3D

@onready var nav := $Systems/NavigationManager
@onready var navigator := get_node_or_null("Navigator")
@onready var path_line := get_node_or_null("PathLine")
@onready var pausemenu = $Ui


func _ready():
	await get_tree().process_frame

	if navigator == null:
		push_error("NODE Navigator TIDAK DITEMUKAN")
		return

	if nav == null:
		push_error("NavigationManager TIDAK DITEMUKAN")
		return
		

	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	start_navigation()

func start_navigation():
	var path = nav.find_path(1, 12, 1.0)

	if path.is_empty():
		push_warning("PATH KOSONG")
		return

	navigator.set_path(path)
	path_line.draw_path(path)


func _on_pause_pressed() -> void:
	pass # Replace with function body.


func _on_progress_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/progress.tscn")
