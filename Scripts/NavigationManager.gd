extends Node

var astar := AStar3D.new()

@onready var start_node = $"../Navigation/Start_Gerbang"
@onready var goal_node  = $"../Navigation/Goal_Kandang"

func _ready():
	_build_graph()
	_debug_path()

func _build_graph():
	astar.add_point(1, Vector3(0, 0, 0))
	astar.add_point(2, Vector3(10, 0, 5))
	astar.add_point(3, Vector3(20, 0, 10))
	astar.add_point(4, Vector3(12, 0, -8))
	astar.add_point(5, Vector3(25, 0, -15))

	astar.connect_points(1, 2)
	astar.connect_points(2, 3)
	astar.connect_points(2, 4)
	astar.connect_points(4, 5)

func _debug_path():
	if start_node == null or goal_node == null:
		push_error("START atau GOAL node tidak ditemukan!")
		return

	var start_id = astar.get_closest_point(start_node.global_position)
	var goal_id  = astar.get_closest_point(goal_node.global_position)

	if start_id == -1 or goal_id == -1:
		push_error("Start / Goal tidak terhubung ke graph A*")
		return

	var path = astar.get_point_path(start_id, goal_id)

	print("=== PATH RESULT ===")
	for p in path:
		print(p)

		var marker := CSGSphere3D.new()
		marker.radius = 0.4
		marker.global_position = p
		get_parent().add_child(marker)

		
func find_path(from_id:int, to_id:int)->PackedVector3Array:
	if not astar.has_point(from_id) or not astar.has_point(to_id):
		return PackedVector3Array()
	return astar.get_point_path(from_id, to_id)
