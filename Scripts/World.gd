extends Node3D

# ============================================
# WORLD.GD - Advanced World Manager
# Fungsi: Mengelola seluruh dunia game, navigasi,
#         kandang, dan sistem utama
# ============================================

# SIGNALS
signal kandang_target_changed(new_target_id: String)
signal navigation_started(target_id: String)
signal navigation_completed(target_id: String)
signal game_state_changed(state: GameState)

enum GameState {
	EXPLORING,      # Player bebas jalan
	NAVIGATING,     # Sedang mengikuti navigasi
	VIEWING_KANDANG,# Sedang lihat info kandang
	IN_MENU,        # Di pause menu/progress
	QUIZ_MODE       # Sedang mengerjakan kuis
}

# REFERENCES - Systems
@onready var nav := $Systems/NavigationManager
@onready var navigator := get_node_or_null("Navigator")
@onready var path_line := get_node_or_null("PathLine")
@onready var pause_menu := $Ui/PauseMenu
@onready var progress_ui := $Ui/ProgressUI

# REFERENCES - Kandang Management
@onready var kandang_container := $KandangContainer  # Node yang berisi semua kandang
var kandang_nodes: Dictionary = {}      # id_hewan -> Node3D kandang
var kandang_triggers: Dictionary = {}   # id_hewan -> KandangTrigger

# STATE VARIABLES
var current_state: GameState = GameState.EXPLORING
var current_target_kandang: String = ""  # ID kandang yang sedang dituju
var visited_kandang_order: Array = []    # Urutan kunjungan untuk tracking
var total_kandang: int = 0

# DEBUG & PERFORMANCE
var debug_mode: bool = false
@onready var debug_label := $Ui/DebugOverlay/Label if has_node("Ui/DebugOverlay") else null

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	print("🌍 World: Initializing...")
	
	# Tunggu frame pertama untuk pastikan semua node ready
	await get_tree().process_frame
	await get_tree().process_frame  # Double frame untuk safety
	
	# Setup input
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Inisialisasi sistem
	_initialize_kandang_system()
	_initialize_navigation()
	_connect_signals()
	_setup_ui()
	
	# Update state awal
	total_kandang = AnimalData.get_total_kandang()
	print("✅ World: Ready with ", total_kandang, " kandang")

func _initialize_kandang_system():
	"""Scan dan registrasi semua kandang di scene"""
	
	# Cari container kandang
	if kandang_container == null:
		# Kalau tidak ada container, cari manual
		kandang_container = Node3D.new()
		kandang_container.name = "KandangContainer"
		add_child(kandang_container)
		push_warning("KandangContainer dibuat otomatis")
	
	# Scan semua child kandang
	for child in kandang_container.get_children():
		if child.name.begins_with("Kandang"):
			var trigger = child.get_node_or_null("KandangTrigger")
			if trigger:
				var id = trigger.id_hewan
				kandang_nodes[id] = child
				kandang_triggers[id] = trigger
				
				# Connect ke trigger
				trigger.body_entered.connect(_on_player_near_kandang.bind(id))
				
				print("📍 Registered kandang: ", id, " at ", child.global_position)
	
	print("📊 Total kandang registered: ", kandang_nodes.size())

func _initialize_navigation():
	"""Setup sistem navigasi"""
	
	if navigator == null:
		push_error("❌ Navigator tidak ditemukan!")
		return
	
	if nav == null:
		push_error("❌ NavigationManager tidak ditemukan!")
		return
	
	if path_line == null:
		push_warning("⚠️ PathLine tidak ditemukan - visualisasi path tidak aktif")
	
	# Set default navigator behavior
	navigator.path_completed.connect(_on_navigation_completed)
	navigator.waypoint_reached.connect(_on_waypoint_reached)

func _connect_signals():
	"""Connect ke AnimalData signals"""
	AnimalData.hewan_dikunjungi.connect(_on_hewan_dikunjungi)
	AnimalData.data_updated.connect(_on_data_updated)

func _setup_ui():
	"""Setup UI initial state"""
	if pause_menu:
		pause_menu.hide()
	
	_update_progress_display()

# ============================================
# NAVIGATION SYSTEM - ADVANCED
# ============================================

func start_navigation_to_kandang(kandang_id: String = ""):
	"""
	Memulai navigasi ke kandang tertentu.
	Kalau kandang_id kosong, cari kandang terdekat yang belum dikunjungi.
	"""
	
	# Tentukan target
	var target_id = kandang_id
	if target_id.is_empty():
		target_id = _find_optimal_target()
	
	if target_id.is_empty():
		push_warning("⚠️ Tidak ada kandang yang bisa dituju!")
		return false
	
	current_target_kandang = target_id
	var target_node = kandang_nodes.get(target_id)
	
	if target_node == null:
		push_error("❌ Kandang node tidak ditemukan: ", target_id)
		return false
	
	# Dapatkan posisi target
	var target_pos = target_node.global_position
	
	# Cari path menggunakan NavigationManager
	var start_pos = navigator.global_position if navigator else $Player.global_position
	var path = nav.find_path_to_point(start_pos, target_pos, 1.0)
	
	if path.is_empty():
		push_warning("⚠️ Path tidak ditemukan ke: ", target_id)
		return false
	
	# Set path ke navigator
	navigator.set_path(path)
	
	# Visualisasi path
	if path_line and path_line.has_method("draw_path"):
		path_line.draw_path(path)
	
	# Update state
	_change_state(GameState.NAVIGATING)
	emit_signal("navigation_started", target_id)
	emit_signal("kandang_target_changed", target_id)
	
	print("🧭 Navigasi dimulai ke: ", target_id, " (", AnimalData.get_hewan(target_id).nama, ")")
	return true

func start_navigation_to_nearest():
	"""Shortcut: Navigasi ke kandang terdekat"""
	return start_navigation_to_kandang("")

func start_navigation_to_unvisited():
	"""Shortcut: Navigasi ke kandang belum dikunjungi terdekat"""
	var target = _find_nearest_unvisited()
	return start_navigation_to_kandang(target)

func stop_navigation():
	"""Menghentikan navigasi saat ini"""
	if navigator and navigator.has_method("stop"):
		navigator.stop()
	
	if path_line and path_line.has_method("clear"):
		path_line.clear()
	
	current_target_kandang = ""
	_change_state(GameState.EXPLORING)
	
	print("🛑 Navigasi dihentikan")

func _find_optimal_target() -> String:
	"""
	Algoritma mencari kandang optimal:
	1. Cari yang belum dikunjungi terdekat
	2. Kalau semua sudah, cari yang terdekat saja
	"""
	var unvisited = _find_nearest_unvisited()
	if not unvisited.is_empty():
		return unvisited
	
	# Fallback: cari yang terdekat
	return _find_nearest_kandang()

func _find_nearest_unvisited() -> String:
	"""Cari kandang belum dikunjungi yang terdekat"""
	var player_pos = $Player.global_position
	var nearest_id = ""
	var nearest_dist = INF
	
	for id in kandang_nodes:
		if not AnimalData.is_dikunjungi(id):
			var dist = player_pos.distance_to(kandang_nodes[id].global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_id = id
	
	return nearest_id

func _find_nearest_kandang() -> String:
	"""Cari kandang terdekat (termasuk yang sudah dikunjungi)"""
	var player_pos = $Player.global_position
	var nearest_id = ""
	var nearest_dist = INF
	
	for id in kandang_nodes:
		var dist = player_pos.distance_to(kandang_nodes[id].global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_id = id
	
	return nearest_id

# ============================================
# EVENT HANDLERS
# ============================================

func _on_navigation_completed():
	"""Dipanggil saat navigator sampai tujuan"""
	print("✅ Sampai di kandang: ", current_target_kandang)
	emit_signal("navigation_completed", current_target_kandang)
	
	# Auto-stop dan switch ke exploring
	stop_navigation()
	
	# Trigger kandang otomatis (opsional)
	# _auto_trigger_kandang(current_target_kandang)

func _on_waypoint_reached(index: int):
	"""Dipanggil saat mencapai waypoint"""
	if debug_mode:
		print("📍 Waypoint ", index, " reached")

func _on_player_near_kandang(body: Node3D, kandang_id: String):
	"""Dipanggil saat player masuk area trigger kandang"""
	if body.name != "Player":
		return
	
	print("👤 Player mendekati kandang: ", kandang_id)
	
	# Kalau sedang navigasi ke kandang ini, stop navigasi
	if current_target_kandang == kandang_id:
		stop_navigation()

func _on_hewan_dikunjungi(id: String):
	"""Dipanggil saat hewan baru dikunjungi"""
	visited_kandang_order.append(id)
	_update_progress_display()
	
	# Check apakah semua sudah dikunjungi
	var progress = AnimalData.get_progress()
	if progress.dikunjungi == progress.total:
		_on_all_kandang_visited()

func _on_data_updated():
	"""Dipanggil saat data berubah"""
	_update_progress_display()

func _on_all_kandang_visited():
	"""Dipanggil saat semua kandang sudah dikunjungi"""
	print("🎉 SELAMAT! Semua kandang sudah dikunjungi!")
	
	# Bisa trigger ending, achievement, dll
	_show_completion_message()

# ============================================
# UI & STATE MANAGEMENT
# ============================================

func _change_state(new_state: GameState):
	"""Mengubah state game dengan proper handling"""
	var old_state = current_state
	current_state = new_state
	
	# Handle state transitions
	match new_state:
		GameState.EXPLORING:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
		
		GameState.NAVIGATING:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		GameState.VIEWING_KANDANG, GameState.IN_MENU, GameState.QUIZ_MODE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	emit_signal("game_state_changed", new_state)
	print("🎮 State: ", _state_to_string(old_state), " → ", _state_to_string(new_state))

func _state_to_string(state: GameState) -> String:
	var names = ["EXPLORING", "NAVIGATING", "VIEWING_KANDANG", "IN_MENU", "QUIZ_MODE"]
	return names[state]

func _update_progress_display():
	"""Update UI progress"""
	if progress_ui and progress_ui.has_method("update_display"):
		progress_ui.update_display()

func _show_completion_message():
	"""Tampilkan pesan selesai"""
	# Bisa buat popup, atau pindah scene
	print("🏆 Game Complete!")

# ============================================
# PUBLIC API - Dipanggil dari UI/Trigger
# ============================================

func open_kandang_ui(kandang_id: String):
	"""Dipanggil oleh KandangTrigger saat player interact"""
	_change_state(GameState.VIEWING_KANDANG)
	# UI akan di-handle oleh KandangTrigger sendiri

func open_pause_menu():
	"""Buka pause menu"""
	_change_state(GameState.IN_MENU)
	if pause_menu:
		pause_menu.show()
		get_tree().paused = true

func close_pause_menu():
	"""Tutup pause menu"""
	if pause_menu:
		pause_menu.hide()
	_change_state(GameState.EXPLORING)

func open_progress():
	"""Buka progress screen"""
	_change_state(GameState.IN_MENU)
	get_tree().change_scene_to_file("res://Scenes/progress.tscn")

# ============================================
# INPUT HANDLING
# ============================================

func _input(event):
	# Debug toggle
	if event.is_action_pressed("debug_mode"):  # Tambahkan di Input Map: F3
		debug_mode = !debug_mode
		print("Debug mode: ", debug_mode)
	
	# Quick navigation keys (untuk testing)
	if debug_mode:
		if event.is_action_pressed("nav_to_nearest"):  # Input Map: N
			start_navigation_to_nearest()
		if event.is_action_pressed("nav_stop"):        # Input Map: M
			stop_navigation()
	
	# Pause
	if event.is_action_pressed("pause"):  # Input Map: Escape
		if current_state == GameState.EXPLORING or current_state == GameState.NAVIGATING:
			open_pause_menu()
		elif current_state == GameState.IN_MENU:
			close_pause_menu()

func _process(delta):
	# Debug overlay
	if debug_mode and debug_label:
		_update_debug_overlay()

func _update_debug_overlay():
	"""Update text debug overlay"""
	if debug_label == null:
		return
	
	var text = "DEBUG MODE\n"
	text += "State: " + _state_to_string(current_state) + "\n"
	text += "Target: " + current_target_kandang + "\n"
	text += "Progress: " + str(AnimalData.get_jumlah_dikunjungi()) + "/" + str(total_kandang) + "\n"
	text += "FPS: " + str(Engine.get_frames_per_second())
	
	debug_label.text = text

# ============================================
# BUTTON HANDLERS (dari scene signals)
# ============================================

func _on_pause_pressed() -> void:
	open_pause_menu()

func _on_progress_button_pressed() -> void:
	open_progress()

func _on_navigate_nearest_pressed() -> void:
	"""Tombol UI: Navigasi ke terdekat"""
	start_navigation_to_nearest()

func _on_navigate_unvisited_pressed() -> void:
	"""Tombol UI: Navigasi ke belum dikunjungi"""
	start_navigation_to_unvisited()
