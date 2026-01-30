extends Node3D

@export var speed := 3.0
var path: PackedVector3Array
var index := 0

@onready var nav_manager = $"../NavigationManager"


func _ready():
	if nav_manager == null:
		push_error("❌ NavigationManager TIDAK ditemukan")
		return
		
	path = nav_manager.find_path(1, 5)
	
	print("=== PATH RESULT ===")
	for p in path:
		print(p)
	
		var sphere = MeshInstance3D.new()
		sphere.mesh = SphereMesh.new()
		sphere.scale = Vector3(0.4, 0.4, 0.4)
		sphere.global_position = p
		get_parent().add_child(sphere)
		
func _process(delta):
	if path.is_empty():
		return

	var target := path[index]
	global_position = global_position.move_toward(target, speed * delta)

	if global_position.distance_to(target) < 0.3:
		index += 1
		if index >= path.size():
			path.clear()
