extends Button 

# ============================================
# ANIMAL_CARD.GD - Panel Informasi Hewan
# ============================================

var id_hewan: String = ""
var data_hewan: Dictionary = {}

# Referensi node (sesuaikan dengan scene-mu!)
@onready var nama_label = $Panel/NamaLabel
@onready var latin_label = $Panel/LatinLabel
@onready var habitat_label = $Panel/HabitatLabel
@onready var makanan_label = $Panel/MakananLabel
@onready var status_label = $Panel/StatusLabel
@onready var fakta_label = $Panel/FaktaLabel
@onready var texture_rect = $Panel/TextureRect
@onready var btn_kuis = $Panel/BtnKuis
@onready var btn_tutup = $Panel/BtnTutup

func _ready():
	# PENTING: Agar UI tetap responsif saat game pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect tombol
	if btn_kuis:
		btn_kuis.pressed.connect(_on_kuis_pressed)
	if btn_tutup:
		btn_tutup.pressed.connect(_on_tutup_pressed)
	
	print("🖼️ AnimalCard ready")

# ============================================
# SETUP: Dipanggil oleh KandangTrigger
# ============================================

func setup(id: String, data: Dictionary):
	id_hewan = id
	data_hewan = data
	
	# Isi data ke UI
	nama_label.text = data.get("nama", "Unknown")
	latin_label.text = data.get("nama_latin", "")
	habitat_label.text = "Habitat: " + data.get("habitat", "-")
	makanan_label.text = "Makanan: " + data.get("makanan", "-")
	status_label.text = "Status: " + data.get("status", "-")
	fakta_label.text = "💡 " + data.get("fakta_menarik", "-")
	
	# Load gambar
	var image_path = "res://assets/hewan/" + id + ".png"
	if ResourceLoader.exists(image_path):
		texture_rect.texture = load(image_path)
		print("🖼️ Image loaded: ", image_path)
	else:
		texture_rect.modulate = Color.GRAY
		print("⚠️ Image not found: ", image_path)
	
	# Update tombol kuis
	if btn_kuis:
		btn_kuis.disabled = not data.has("kuis")

# ============================================
# BUTTON HANDLERS
# ============================================

func _on_kuis_pressed():
	print("🎯 Opening quiz for: ", id_hewan)
	
	# Load dan buat scene kuis
	var kuis_scene = load("res://Scenes/ui/kuis_ui.tscn")
	if not kuis_scene:
		push_error("❌ Cannot load kuis_ui.tscn")
		return
	
	var kuis = kuis_scene.instantiate()
	kuis.setup(id_hewan, data_hewan.get("kuis", {}))
	add_child(kuis)

func _on_tutup_pressed():
	print("❌ Closing animal card")
	
	# Hentikan TTS
	AudioControl.stop_narasi()
	
	# Hapus diri sendiri
	queue_free()
	
	# Unpause game
	get_tree().paused = false
	print("▶️ Game unpaused")
