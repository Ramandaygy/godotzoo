extends Node3D

@onready var navigator: Node3D = $SimpleNavigator
@onready var player: CharacterBody3D = $Player
@onready var ui: CanvasLayer = $Ui

var is_navigating: bool = false

func _ready():
	print("🌍 World: _ready start")
	
	# Delay initialization
	await get_tree().create_timer(0.5).timeout
	
	if navigator == null:
		push_error("❌ SimpleNavigator not found!")
	else:
		print("✅ Navigator found")
	
	# Mouse mode di-comment dulu (bisa menyebabkan freeze)
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	print("🌍 World: _ready complete")

func _input(event):
	if event.is_action_pressed("navigate_nearest"):
		print("🎮 N pressed")
		_start_navigation()
	
	if event.is_action_pressed("navigate_stop"):
		print("🎮 M pressed")
		_stop_navigation()
	
	if event.is_action_pressed("pause"):
		print("🎮 ESC pressed")
		_toggle_pause()

func _start_navigation():
	if navigator and navigator.has_method("navigate_to_nearest_unvisited"):
		var success = navigator.navigate_to_nearest_unvisited()
		if success:
			is_navigating = true
			print("🧭 Navigation started")

func _stop_navigation():
	if navigator and navigator.has_method("stop"):
		navigator.stop()
		is_navigating = false
		print("🛑 Navigation stopped")

func _toggle_pause():
	var new_pause = not get_tree().paused
	get_tree().paused = new_pause
	print("⏸️ Pause: ", new_pause)
	
	# Mouse mode di-comment dulu
	# if new_pause:
	#     Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# else:
	#     Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_pause_pressed():
	_toggle_pause()

func _on_progress_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/progress.tscn")
