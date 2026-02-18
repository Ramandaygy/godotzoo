extends Node3D

@export var player: CharacterBody3D
@export var move_speed: float = 4.0
@export var turn_speed: float = 8.0
@export var reach_distance: float = 0.5

var waypoints: Dictionary = {}
var current_path: Array[Vector3] = []
var current_index: int = 0
var is_moving: bool = false
var _initialized: bool = false

func _ready():
	print("🧭 SimpleNavigator: _ready start")
	
	# Delay sedikit untuk pastikan scene siap
	await get_tree().create_timer(0.1).timeout
	
	# Cari player
	if player == null:
		player = get_node_or_null("../Player")
	
	if player == null:
		player = get_node_or_null("../../Player")
	
	if player:
		print("✅ Player found: ", player.name)
	else:
		push_error("❌ Player not found!")
		return
	
	# Scan kandang
	_scan_kandang_positions()
	
	_initialized = true
	print("🧭 SimpleNavigator: _ready complete")

func _scan_kandang_positions():
	print("🔍 Scanning kandang...")
	var world = get_parent()
	
	# Cari container Kandang-Kandang
	var container = world.get_node_or_null("Kandang-Kandang")
	
	if container == null:
		push_error("❌ Kandang-Kandang container not found!")
		return
	
	print("✅ Found container: ", container.name)
	print("   Children: ", container.get_child_count())
	
	# Scan semua kandang di container
	for kandang in container.get_children():
		print("   Checking: ", kandang.name)
		
		# Cari KandangTrigger di dalam kandang
		var trigger = kandang.get_node_or_null("Kandang/KandangTrigger")
		
		# Atau kalau struktur berbeda, coba cara lain:
		if trigger == null:
			trigger = kandang.get_node_or_null("KandangTrigger")
		
		if trigger == null:
			# Cari recursive
			trigger = _find_trigger_recursive(kandang)
		
		if trigger:
			print("   ✅ Found trigger")
			var id = trigger.id_hewan
			var pos = kandang.global_position  # Posisi kandang, bukan trigger
			pos.z += 3.0  # 3 meter di depan
			waypoints[id] = pos
			print("   📍 Added: ", id, " at ", pos)
		else:
			print("   ❌ KandangTrigger not found in ", kandang.name)
	
	print("📊 Total waypoints: ", waypoints.size())

func _find_trigger_recursive(node: Node) -> Node:
	"""Cari KandangTrigger di semua children"""
	if node.name == "KandangTrigger":
		return node
	
	for child in node.get_children():
		var found = _find_trigger_recursive(child)
		if found:
			return found
	
	return null
	
func navigate_to_nearest_unvisited() -> bool:
	if not _initialized:
		push_error("Not initialized yet!")
		return false
	
	if waypoints.is_empty():
		push_error("No waypoints!")
		return false
	
	if player == null:
		push_error("No player!")
		return false
	
	# Cari yang belum dikunjungi
	var nearest_id = ""
	var nearest_dist = INF
	
	for id in waypoints.keys():
		if AnimalData.is_dikunjungi(id):
			continue
		
		var dist = player.global_position.distance_to(waypoints[id])
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_id = id
	
	if nearest_id.is_empty():
		print("✅ All visited!")
		return false
	
	return navigate_to(nearest_id)

func navigate_to(kandang_id: String) -> bool:
	if not waypoints.has(kandang_id):
		push_error("Waypoint not found: " + kandang_id)
		return false
	
	var start = player.global_position
	var end = waypoints[kandang_id]
	
	# Simple path
	current_path.clear()
	current_path.append(start)
	current_path.append((start + end) / 2)
	current_path.append(end)
	
	current_index = 0
	is_moving = true
	
	print("🛤️ Navigating to: ", kandang_id)
	return true

func stop():
	is_moving = false
	current_path.clear()
	print("🛑 Stopped")

func _physics_process(delta):
	if not _initialized:
		return
	
	if not is_moving:
		return
	
	if player == null:
		is_moving = false
		return
	
	# Cek selesai
	if current_index >= current_path.size():
		is_moving = false
		print("✅ Arrived!")
		return
	
	# Validasi path
	if current_path.is_empty():
		is_moving = false
		return
	
	# Dapatkan target
	var target = current_path[current_index]
	
	# Pastikan target valid
	if target == null:
		current_index += 1
		return
	
	target.y = player.global_position.y
	
	# Hitung jarak
	var dist = player.global_position.distance_to(target)
	
	# Sampai?
	if dist < reach_distance:
		current_index += 1
		return
	
	# ============================================
	# ROTASI YANG BENAR
	# ============================================
	
	# Hitung arah ke target
	var direction = (target - player.global_position).normalized()
	
	# Pastikan direction valid
	if direction.length() < 0.001:
		current_index += 1
		return
	
	# ============================================
	# CARA 1: look_at (Paling Sederhana)
	# ============================================
	player.look_at(target, Vector3.UP)
	
	# ============================================
	# CARA 2: Smooth rotation (Kalau mau halus)
	# ============================================
	# var target_rotation = atan2(direction.x, direction.z)
	# player.rotation.y = lerp_angle(player.rotation.y, target_rotation, turn_speed * delta)
	
	# ============================================
	# CARA 3: Jika model player menghadap -Z (belakang)
	# ============================================
	# player.rotation.y += PI  # Tambah 180 derajat
	
	# Gerak
	player.velocity = direction * move_speed
	player.move_and_slide()
