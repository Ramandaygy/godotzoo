extends Node

# ============================================
# ANIMALDATA.GD - Data Manager Autoload
# Fungsi: Mengelola data hewan dari JSON
#         dan progress kunjungan player
# ============================================

# SIGNAL - Memberitahu scene lain kalau ada perubahan
signal hewan_dikunjungi(id_hewan)    # Dipancar saat hewan baru dikunjungi
signal data_updated                   # Dipancar saat data berubah

# VARIABEL
var data_hewan: Dictionary = {}       # Cache semua data di memory
const DATA_PATH = "res://data/data_hewan.json"    # Lokasi JSON (read-only)
const SAVE_PATH = "user://save_progress.json"     # Lokasi save (writeable)

# _ready: Jalan sekali saat game start
func _ready():
	print("🔄 AnimalData: Loading...")
	load_data()      # Baca JSON
	load_progress()  # Load save file
	print("✅ AnimalData: Ready with ", data_hewan.size(), " hewan")

# ============================================
# FUNGSI: LOAD DATA
# ============================================

func load_data():
	var file = FileAccess.open(DATA_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			data_hewan = json.get_data()
			print("📊 Loaded: ", data_hewan.keys())
		else:
			push_error("JSON Parse Error: " + str(error))
		file.close()
	else:
		push_error("❌ Cannot open: " + DATA_PATH)

# ============================================
# FUNGSI: GET DATA
# ============================================

func get_hewan(id: String) -> Dictionary:
	if data_hewan.has(id):
		return data_hewan[id]
	push_warning("Hewan not found: " + id)
	return {}

func is_dikunjungi(id: String) -> bool:
	if data_hewan.has(id):
		return data_hewan[id].sudah_dikunjungi
	return false

func get_progress() -> Dictionary:
	var total = data_hewan.size()
	var dikunjungi = 0
	for id in data_hewan:
		if data_hewan[id].sudah_dikunjungi:
			dikunjungi += 1
	return {
		"total": total,
		"dikunjungi": dikunjungi,
		"persen": float(dikunjungi) / float(total) * 100 if total > 0 else 0
	}

# ============================================
# FUNGSI: UPDATE & SAVE
# ============================================

func kunjungi_hewan(id: String):
	# Cek valid dan belum dikunjungi
	if not data_hewan.has(id):
		push_warning("Invalid hewan ID: " + id)
		return
	
	if data_hewan[id].sudah_dikunjungi:
		print("ℹ️ Hewan already visited: ", id)
		return
	
	# Update data
	data_hewan[id].sudah_dikunjungi = true
	print("🎯 Hewan visited: ", id)
	
	# Emit signal ke semua listener
	hewan_dikunjungi.emit(id)
	data_updated.emit()
	
	# Save ke file
	save_progress()

func save_progress():
	var save_data = {
		"progress": {},
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Hanya simpan status sudah_dikunjungi
	for id in data_hewan:
		save_data.progress[id] = {
			"sudah_dikunjungi": data_hewan[id].sudah_dikunjungi
		}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))  # Pretty print
		file.close()
		print("💾 Progress saved to: ", SAVE_PATH)
	else:
		push_error("❌ Cannot save to: " + SAVE_PATH)

func load_progress():
	# Cek apakah file save ada
	if not FileAccess.file_exists(SAVE_PATH):
		print("ℹ️ No save file found, using defaults")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("❌ Cannot open save file")
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("JSON Parse Error in save file")
		return
	
	var save_data = json.get_data()
	if not save_data.has("progress"):
		print("⚠️ Invalid save file format")
		return
	
	# Apply saved progress ke data_hewan
	for id in save_data.progress:
		if data_hewan.has(id):
			data_hewan[id].sudah_dikunjungi = save_data.progress[id].sudah_dikunjungi
	
	print("📂 Progress loaded from: ", SAVE_PATH)
