extends Node3D

# ============================================
# KANDANGTRIGGER.GD - Trigger dengan Node3D + Area3D Child
# ============================================

# EXPORT: Variabel yang muncul di Inspector
@export var id_hewan: String = "anoa"           # ID untuk data JSON
@export var nama_kandang: String = "Kandang Anoa"  # Nama tampilan

# REFERENSI: Ke Area3D child
@onready var detection_area: Area3D = $DetectionArea

# VARIABEL
var player_di_dalam: bool = false               # Flag: player di area?

# _ready: Saat scene dimuat
func _ready():
	# Validasi: pastikan DetectionArea ada
	if detection_area == null:
		push_error("❌ DetectionArea tidak ditemukan! Pastikan ada Area3D child dengan nama 'DetectionArea'")
		return
	
	# Connect signal dari Area3D child
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	print("✅ KandangTrigger ready: ", nama_kandang, " (", id_hewan, ")")

# ============================================
# SIGNAL HANDLERS
# ============================================

func _on_body_entered(body: Node3D):
	# Cek apakah yang masuk adalah Player (berdasarkan nama node)
	if body.name == "Player":
		player_di_dalam = true
		print("👤 Player entered: ", nama_kandang)
		tampilkan_prompt()

func _on_body_exited(body: Node3D):
	if body.name == "Player":
		player_di_dalam = false
		print("👤 Player exited: ", nama_kandang)
		sembunyikan_prompt()

# ============================================
# INPUT HANDLING
# ============================================

func _input(event: InputEvent):
	# Cek: player di area + tombol interact ditekan
	if player_di_dalam and event.is_action_pressed("interact"):
		print("🎮 Interact pressed at: ", nama_kandang)
		buka_info_hewan()

# ============================================
# UI FUNCTIONS
# ============================================

func tampilkan_prompt():
	# Cari HUD dan tampilkan prompt
	var ui = get_node_or_null("/root/World/Ui")
	if ui:
		var hud = ui.get_node_or_null("HUD")
		if hud and hud.has_method("show_prompt"):
			hud.show_prompt("Tekan E untuk melihat " + nama_kandang)

func sembunyikan_prompt():
	var ui = get_node_or_null("/root/World/Ui")
	if ui:
		var hud = ui.get_node_or_null("HUD")
		if hud and hud.has_method("hide_prompt"):
			hud.hide_prompt()

# ============================================
# MAIN FUNCTION: BUKA INFO HEWAN
# ============================================

func buka_info_hewan():
	# 1. PAUSE game world
	get_tree().paused = true
	print("⏸️ Game paused")
	
	# 2. Ambil data dari AnimalData (Autoload)
	var data = AnimalData.get_hewan(id_hewan)
	
	if data.is_empty():
		push_error("❌ Data hewan tidak ditemukan: " + id_hewan)
		get_tree().paused = false
		return
	
	# 3. Buat instance animal_card UI
	var animal_card_scene = load("res://Scenes/ui/animal_card.tscn")
	if not animal_card_scene:
		push_error("❌ Cannot load animal_card.tscn")
		get_tree().paused = false
		return
	
	var animal_card = animal_card_scene.instantiate()
	
	# 4. Setup UI dengan data
	if animal_card.has_method("setup"):
		animal_card.setup(id_hewan, data)
	else:
		push_warning("animal_card tidak punya method setup()")
	
	# 5. Tambahkan ke root (di atas semua)
	get_tree().root.add_child(animal_card)
	print("🖼️ UI opened for: ", data.nama)
	
	# 6. Mainkan narasi TTS
	if data.has("narasi"):
		AudioControl.play_narasi(data.narasi)
	
	# 7. Update progress (tandai sudah dikunjungi)
	AnimalData.kunjungi_hewan(id_hewan)
