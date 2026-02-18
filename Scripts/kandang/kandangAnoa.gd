extends Control

@export var hewan_id: String = "anoa"

# Referensi node - UI UTAMA
@onready var background = $Background if has_node("Background") else null
@onready var btn_close = $CloseButton if has_node("CloseButton") else null
@onready var panel = $Panel if has_node("Panel") else null
@onready var judul = $Panel/JudulLabel if has_node("Panel/JudulLabel") else null
@onready var foto = $Panel/FotoHewan if has_node("Panel/FotoHewan") else null

# Referensi node - INFO CONTAINER (BARU)
@onready var info_container = $Panel/InfoContainer if has_node("Panel/InfoContainer") else null
@onready var latin_label = $Panel/InfoContainer/LatinLabel if has_node("Panel/InfoContainer/LatinLabel") else null
@onready var deskripsi_singkat = $Panel/InfoContainer/DeskripsiSingkat if has_node("Panel/InfoContainer/DeskripsiSingkat") else null
@onready var value_habitat = $Panel/InfoContainer/GridContainer/ValueHabitat if has_node("Panel/InfoContainer/GridContainer/ValueHabitat") else null
@onready var value_makanan = $Panel/InfoContainer/GridContainer/ValueMakanan if has_node("Panel/InfoContainer/GridContainer/ValueMakanan") else null
@onready var value_status = $Panel/InfoContainer/GridContainer/ValueStatus if has_node("Panel/InfoContainer/GridContainer/ValueStatus") else null
@onready var fakta_menarik = $Panel/InfoContainer/Faktamem if has_node("Panel/InfoContainer/Faktamem") else null

@onready var btn_audio = $Panel/ButtonAudio if has_node("Panel/ButtonAudio") else null
@onready var btn_kuis = $Panel/ButtonKuis if has_node("Panel/ButtonKuis") else null
@onready var btn_kembali = $ButtonKembali if has_node("ButtonKembali") else null
@onready var audio_player = $AudioNarasi if has_node("AudioNarasi") else null

# Node untuk narasi (TYPEWRITER - TETAP)
@onready var narasi_panel = $NarasiPanel if has_node("NarasiPanel") else null
@onready var narasi_text = $NarasiPanel/NarasiTeks if has_node("NarasiPanel/NarasiTeks") else null

# Referensi 3D
@onready var viewport_container = $SubViewportContainer if has_node("SubViewportContainer") else null
@onready var sub_viewport = $SubViewportContainer/SubViewport if has_node("SubViewportContainer/SubViewport") else null
@onready var camera_3d = $SubViewportContainer/SubViewport/Camera3D if has_node("SubViewportContainer/SubViewport/Camera3D") else null
@onready var hewan_3d = $SubViewportContainer/SubViewport/anoa if has_node("SubViewportContainer/SubViewport/anoa") else null

# Data
var hewan_data = {}
var narasi_data = {}
var narasi_list = []
var narasi_index = 0

# TYPEWRITER VARIABLES (TETAP)
var full_narasi_teks: String = ""
var current_char_index: int = 0
var typewriter_timer: Timer
var typing_speed: float = 0.05
var is_typing: bool = false
var auto_next_timer: Timer

func _ready():
	# Debug untuk cek node
	print("🔍 Cek node info:")
	print("   latin_label: ", latin_label)
	print("   value_habitat: ", value_habitat)
	print("   value_makanan: ", value_makanan)
	print("   value_status: ", value_status)
	print("   fakta_menarik: ", fakta_menarik)
	print("   narasi_panel: ", narasi_panel)
	
	# Setup typewriter timer
	setup_typewriter_timer()
	
	# Ambil data hewan
	if has_node("/root/AnimalData"):
		hewan_data = AnimalData.get_hewan(hewan_id)
		if not hewan_data.is_empty():
			AnimalData.kunjungi_hewan(hewan_id)
	else:
		hewan_data = get_fallback_data()
	
	# Ambil data narasi
	if has_node("/root/NarasiData"):
		narasi_data = NarasiData.get_narasi(hewan_id)
		prepare_narasi()
	else:
		print("⚠️ NarasiData tidak ditemukan")
		create_default_narasi()
	
	setup_viewport()
	setup_ui()  # Ini yang mengisi info container
	setup_audio()
	connect_signals()
	
	# Mulai narasi otomatis dengan TYPEWRITER
	start_typewriter_narasi()

func setup_typewriter_timer():
	typewriter_timer = Timer.new()
	typewriter_timer.name = "TypewriterTimer"
	typewriter_timer.one_shot = false
	typewriter_timer.timeout.connect(_on_typewriter_timeout)
	add_child(typewriter_timer)
	
	auto_next_timer = Timer.new()
	auto_next_timer.name = "AutoNextTimer"
	auto_next_timer.one_shot = true
	auto_next_timer.timeout.connect(_on_auto_next_timeout)
	add_child(auto_next_timer)

func prepare_narasi():
	narasi_list = []
	if narasi_data:
		var keys = narasi_data.keys()
		keys.sort()
		for key in keys:
			narasi_list.append(narasi_data[key])
	print("📋 Narasi siap: ", narasi_list.size(), " bagian")

func create_default_narasi():
	narasi_list = [
		"Halo! Aku adalah " + hewan_data.get("nama", "hewan") + ".",
		"Aku tinggal di " + hewan_data.get("habitat", "hutan") + ".",
		"Aku makan " + hewan_data.get("makanan", "tumbuhan") + ".",
		"Status konservasiku: " + hewan_data.get("status", "Terancam Punah") + ".",
		"Jaga alam dan satwa Indonesia!"
	]

func start_typewriter_narasi():
	if not narasi_panel or not narasi_text:
		print("❌ Narasi panel atau text tidak ditemukan!")
		return
	
	if narasi_list.size() == 0:
		print("⚠️ Daftar narasi kosong!")
		return
	
	narasi_panel.visible = true
	narasi_index = 0
	start_typing_current_narasi()

func start_typing_current_narasi():
	if narasi_list.size() == 0 or not narasi_text:
		return
	
	full_narasi_teks = narasi_list[narasi_index]
	current_char_index = 0
	is_typing = true
	
	narasi_text.text = ""
	
	if typewriter_timer:
		typewriter_timer.wait_time = typing_speed
		typewriter_timer.start()
	
	play_narasi_audio()
	print("▶️ Mengetik narasi ", narasi_index + 1, ": ", full_narasi_teks.substr(0, 30), "...")

func _on_typewriter_timeout():
	if not is_typing or not narasi_text:
		return
	
	if current_char_index < full_narasi_teks.length():
		current_char_index += 1
		var displayed = full_narasi_teks.substr(0, current_char_index)
		
		if narasi_text is RichTextLabel:
			narasi_text.text = "[center]" + displayed + "[/center]"
		else:
			narasi_text.text = displayed
	else:
		stop_typing()
		if auto_next_timer:
			auto_next_timer.wait_time = 2.0
			auto_next_timer.start()

func stop_typing():
	is_typing = false
	if typewriter_timer:
		typewriter_timer.stop()

func skip_typing():
	stop_typing()
	if narasi_text and full_narasi_teks:
		if narasi_text is RichTextLabel:
			narasi_text.text = "[center]" + full_narasi_teks + "[/center]"
		else:
			narasi_text.text = full_narasi_teks

func _on_auto_next_timeout():
	next_narasi()

func next_narasi():
	narasi_index += 1
	
	if narasi_index >= narasi_list.size():
		narasi_index = 0
	
	start_typing_current_narasi()

func play_narasi_audio():
	if not audio_player:
		return
	
	var audio_path = "res://Assets/audio/" + hewan_id + "_narasi_" + str(narasi_index + 1) + ".ogg"
	
	if not ResourceLoader.exists(audio_path):
		audio_path = "res://Assets/audio/" + hewan_id + ".ogg"
	
	if ResourceLoader.exists(audio_path):
		audio_player.stream = load(audio_path)
		audio_player.play()
	else:
		print("🔇 Audio tidak ditemukan: ", audio_path)

func setup_viewport():
	if not viewport_container or not sub_viewport or not camera_3d:
		return
	
	viewport_container.stretch = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.disable_3d = false
	sub_viewport.transparent_bg = false
	camera_3d.current = true

func connect_signals():
	if btn_audio: btn_audio.pressed.connect(_on_audio_pressed)
	if btn_kuis: btn_kuis.pressed.connect(_on_kuis_pressed)
	if btn_kembali: btn_kembali.pressed.connect(_on_kembali_pressed)
	if btn_close: btn_close.pressed.connect(_on_kembali_pressed)

func setup_ui():
	"""Mengisi InfoContainer dengan data hewan"""
	if hewan_data.is_empty():
		return
	
	# Judul
	if judul:
		judul.text = hewan_data.get("nama", "HEWAN").to_upper()
	
	# Nama Latin
	if latin_label:
		latin_label.text = "[b]" + hewan_data.get("nama_latin", "") + "[/b]"
	
	# Deskripsi singkat (gunakan fakta_menarik dari JSON)
	if deskripsi_singkat:
		deskripsi_singkat.text = hewan_data.get("fakta_menarik", "")
	
	# Value habitat, makanan, status
	if value_habitat:
		value_habitat.text = hewan_data.get("habitat", "-")
	if value_makanan:
		value_makanan.text = hewan_data.get("makanan", "-")
	if value_status:
		value_status.text = hewan_data.get("status", "-")
	
	# Fakta menarik (tambahan)
	if fakta_menarik:
		fakta_menarik.text = hewan_data.get("fakta_menarik", "")
	
	# Foto
	if foto:
		var foto_path = "res://Assets/gambar/" + hewan_id + ".jpg"
		if ResourceLoader.exists(foto_path):
			foto.texture = load(foto_path)
		else:
			foto.texture = null

func setup_audio():
	pass

func _on_audio_pressed():
	if not audio_player:
		return
	
	if audio_player.playing:
		audio_player.stop()
		stop_typing()
		skip_typing()
	else:
		start_typing_current_narasi()

func _on_audio_finished():
	pass

func _on_kuis_pressed():
	var kuis = hewan_data.get("kuis", {})
	if kuis.size() > 0:
		stop_typing()
		if has_node("/root/SceneSwitcher"):
			SceneSwitcher.goto_scene("res://Scenes/ui/kuisUI.tscn", {
				"hewan_id": hewan_id,
				"hewan_nama": hewan_data.get("nama", "")
			})
		else:
			get_tree().change_scene_to_file("res://Scenes/ui/kuisUI.tscn")
	else:
		var popup = AcceptDialog.new()
		popup.dialog_text = "Kuis untuk " + hewan_data.get("nama", "hewan ini") + " sedang dalam pengembangan!"
		popup.title = "Info"
		add_child(popup)
		popup.popup_centered()

func _on_kembali_pressed():
	stop_typing()
	if auto_next_timer:
		auto_next_timer.stop()
	if typewriter_timer:
		typewriter_timer.stop()
	
	if has_node("/root/SceneSwitcher"):
		SceneSwitcher.goto_scene("res://Scenes/world.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/world.tscn")

func get_fallback_data() -> Dictionary:
	return {
		"nama": "ANOA",
		"nama_latin": "Bubalus depressicornis",
		"fakta_menarik": "Anoa adalah kerbau terkecil di dunia.",
		"habitat": "Hutan Sulawesi",
		"makanan": "Rumput, daun, buah",
		"status": "Terancam Punah"
	}
