extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var setting: Panel = $Setting


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_buttons.visible = true
	setting.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/opening.tscn")


func _on_setting_pressed() -> void:
	print("Setting pressed")
	main_buttons.visible = false
	setting.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_close_pressed() -> void:
	_ready()
