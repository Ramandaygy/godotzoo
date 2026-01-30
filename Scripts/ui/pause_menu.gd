extends Control

@onready var resume_button = $PausePanel/ResumeButton
@onready var restart_button = $PausePanel/RestartButton
@onready var quit_button = $PausePanel/QuitButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Connect buttons
	resume_button.pressed.connect(unpause_game)
	restart_button.pressed.connect(restart_game)
	quit_button.pressed.connect(quit_game)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			unpause_game()
		else:
			pause_game()
			
func pause_game():
	get_tree().paused = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Fokus ke resume button
	resume_button.grab_focus()
	
func unpause_game():
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func quit_game():
	get_tree().quit()
