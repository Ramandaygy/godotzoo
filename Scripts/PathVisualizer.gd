extends Node3D

@export var point_size := 0.25
@export var point_color := Color.RED

@onready var nav_manager = get_parent().get_node("NavigationManager")

func _ready():
	var path = nav_manager.find_path(1, 5)

	if path.is_empty():
		print("❌ Path kosong")
		return

	print("🟢 Visualizing path with", path.size(), "points")

	for p in path:
		_draw_point(p)

func _draw_point(position: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()

	sphere.radius = point_size
	mesh_instance.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = point_color
	mat.emission_enabled = true
	mat.emission = point_color

	mesh_instance.material_override = mat
	mesh_instance.global_position = position

	add_child(mesh_instance)
