extends Control

# Data narasi (3 slide sesuai HTML)
var narasi_data = [
	{
		"teks": "Ragunan Zoo didirikan pada tahun 1864 dengan nama 'Planten en Dierentuin' di area Cikini, Jakarta Pusat.",
		"foto": "res://Assets/gambar/sejarah_1.jpeg",  
		"audio": "res://Assets/audio/narasi_1.ogg", 
		"judul": "SEJARAH RAGUNAN ZOO"
	},
	{
		"teks": "Tahun 1966, kebun binatang ini pindah ke lokasi baru di Ragunan, Pasar Minggu, Jakarta Selatan.",
		"foto": "res://Assets/gambar/sejarah_2.png",
		"audio": "res://Assets/audio/narasi_2.ogg",
		"judul": "PERPINDAHAN KE RAGUNAN"
	},
	{
		"teks": "Kini Ragunan menjadi rumah bagi lebih dari 2.000 satwa dan tujuan edukasi konservasi terkemuka di Indonesia.",
		"foto": "res://Assets/gambar/sejarah_3.png",
		"audio": "res://Assets/audio/narasi_3.ogg",
		"judul": "RAGUNAN MODERN"
	}
]

var current_slide = 0
var is_audio_playing = false

# VARIABEL UNTUK TYPEWRITER EFFECT
var full_teks: String = ""          # Teks lengkap yang akan ditampilkan
var current_char_index: int = 0     # Index karakter saat ini
var typewriter_timer: Timer         # Timer untuk efek mengetik
var typing_speed: float = 0.05      # Kecepatan mengetik (detik per karakter)
var is_typing: bool = false         # Status sedang mengetik

# Referensi ke node-node
@onready var background = $Background
@onready var panel = $Panel
@onready var texture_rect = $Panel/TextureRect 
@onready var teks_narasi = $Panel/TeksNarasi  
@onready var audio_player = $Panel/AudioNarasi 
@onready var btn_audio = $Panel/ButtonAudio   
@onready var btn_skip = $Panel/ButtonSkip     
@onready var judul_label = $Panel/JudulLabel   

func _ready():
	setup_nodes()
	setup_typewriter_timer()
	setup_signals()
	load_slide(current_slide)

func setup_typewriter_timer():
	typewriter_timer = Timer.new()
	typewriter_timer.name = "TypewriterTimer"
	typewriter_timer.one_shot = false  # Berulang terus sampai teks habis
	typewriter_timer.timeout.connect(_on_typewriter_timeout)
	add_child(typewriter_timer)

func setup_signals():
	if btn_audio:
		btn_audio.pressed.connect(_on_audio_pressed)
	if btn_skip:
		btn_skip.pressed.connect(_on_skip_pressed)
	if audio_player:
		audio_player.finished.connect(_on_audio_narasi_finished)

func setup_nodes():
	# Cek apakah judul_label sudah ada
	if not has_node("Panel/JudulLabel"):
		var new_label = Label.new()
		new_label.name = "JudulLabel"
		new_label.text = "SEJARAH RAGUNAN ZOO"
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.add_theme_font_size_override("font_size", 36)
		$Panel.add_child(new_label)
		judul_label = new_label
		print("JudulLabel dibuat secara otomatis")
	else:
		judul_label = $Panel/JudulLabel
	
	# Cek apakah ButtonAudio sudah ada
	if not has_node("Panel/ButtonAudio"):
		var new_btn = Button.new()
		new_btn.name = "ButtonAudio"
		new_btn.text = "▶"
		new_btn.custom_minimum_size = Vector2(80, 80)
		$Panel.add_child(new_btn)
		btn_audio = new_btn
		print("ButtonAudio dibuat secara otomatis")
	else:
		btn_audio = $Panel/ButtonAudio
	
	# Cek ButtonSkip
	if has_node("Panel/ButtonSkip"):
		btn_skip = $Panel/ButtonSkip
	
	# Cek TextureRect
	if not texture_rect:
		if has_node("Panel/TextureRect"):
			texture_rect = $Panel/TextureRect
		else:
			print("ERROR: TextureRect tidak ditemukan!")
	
	# Cek TeksNarasi
	if not teks_narasi:
		if has_node("Panel/TeksNarasi"):
			teks_narasi = $Panel/TeksNarasi
		else:
			# Buat baru kalau tidak ada
			var new_label = Label.new()
			new_label.name = "TeksNarasi"
			new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			new_label.custom_minimum_size = Vector2(800, 100)
			new_label.add_theme_font_size_override("font_size", 24)
			$Panel.add_child(new_label)
			teks_narasi = new_label
			print("TeksNarasi dibuat otomatis")

func load_slide(index):
	if index >= narasi_data.size():
		go_to_world()
		return
	
	var data = narasi_data[index]
	
	# Update judul
	if judul_label:
		judul_label.text = data["judul"]
	
	# Simpan teks lengkap dan mulai typewriter effect
	full_teks = data["teks"]
	current_char_index = 0
	
	# Reset teks narasi (kosong dulu)
	if teks_narasi:
		teks_narasi.text = ""
	
	# Load foto
	if texture_rect:
		var foto_path = data["foto"]
		if ResourceLoader.exists(foto_path):
			var image = load(foto_path)
			texture_rect.texture = image
		else:
			create_placeholder_foto(index)
	
	# Load audio
	if audio_player:
		var audio_path = data["audio"]
		if ResourceLoader.exists(audio_path):
			audio_player.stream = load(audio_path)
			if btn_audio:
				btn_audio.text = "▶"
			is_audio_playing = false
		else:
			if btn_audio:
				btn_audio.disabled = true
				btn_audio.text = "🔇"
	
	# Mulai typewriter effect
	start_typing()

func start_typing():
	# Hentikan timer yang sedang berjalan
	stop_typing()
	
	is_typing = true
	current_char_index = 0
	
	# Mulai timer typewriter
	if typewriter_timer:
		typewriter_timer.wait_time = typing_speed
		typewriter_timer.start()
	
	# Mulai audio bersamaan dengan teks
	if audio_player and audio_player.stream:
		audio_player.play()
		if btn_audio:
			btn_audio.text = "⏹"
		is_audio_playing = true

func stop_typing():
	is_typing = false
	if typewriter_timer:
		typewriter_timer.stop()

func _on_typewriter_timeout():
	if not is_typing or not teks_narasi:
		return
	
	# Tambah 1 karakter ke teks yang ditampilkan
	if current_char_index < full_teks.length():
		current_char_index += 1
		var displayed_text = full_teks.substr(0, current_char_index)
		
		# Update label
		if teks_narasi is RichTextLabel:
			teks_narasi.text = "[center]" + displayed_text + "[/center]"
			teks_narasi.bbcode_enabled = true
		else:
			teks_narasi.text = displayed_text
			teks_narasi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		# Teks sudah selesai, hentikan timer
		stop_typing()

func skip_typing():
	# Langsung tampilkan semua teks
	stop_typing()
	if teks_narasi:
		if teks_narasi is RichTextLabel:
			teks_narasi.text = "[center]" + full_teks + "[/center]"
			teks_narasi.bbcode_enabled = true
		else:
			teks_narasi.text = full_teks
			teks_narasi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func create_placeholder_foto(index):
	var image = Image.create(600, 300, false, Image.FORMAT_RGBA8)
	var colors = [
		Color(0.5, 0.7, 0.5),
		Color(0.6, 0.5, 0.4),
		Color(0.4, 0.6, 0.8)
	]
	image.fill(colors[index % colors.size()])
	var texture = ImageTexture.create_from_image(image)
	texture_rect.texture = texture
	print("Placeholder foto untuk slide ", index + 1)

func _on_audio_pressed():
	if not audio_player or not audio_player.stream:
		return
	
	if audio_player.playing:
		audio_player.stop()
		if btn_audio:
			btn_audio.text = "▶"
		is_audio_playing = false
		# Jika audio di-pause, hentikan typing juga
		stop_typing()
	else:
		# Jika teks sudah selesai, mulai dari awal lagi
		if current_char_index >= full_teks.length():
			start_typing()
		else:
			# Lanjutkan audio dan typing
			audio_player.play()
			if btn_audio:
				btn_audio.text = "⏹"
			is_audio_playing = true
			# Lanjutkan typing kalau terhenti
			if not typewriter_timer.is_stopped() == false:
				typewriter_timer.start()

func _on_audio_narasi_finished():
	if btn_audio:
		btn_audio.text = "▶"
	is_audio_playing = false
	# Pastikan teks sudah lengkap ketika audio selesai
	skip_typing()

func _on_skip_pressed():
	# Hentikan audio
	if audio_player and audio_player.playing:
		audio_player.stop()
		if btn_audio:
			btn_audio.text = "▶"
	
	# Tampilkan teks lengkap dulu (opsional, bisa dihapus kalau mau langsung next)
	skip_typing()
	
	# Lanjut ke slide berikutnya
	current_slide += 1
	load_slide(current_slide)

func go_to_world():
	print("Lanjut ke World Scene")
	stop_typing()
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func go_to_main_menu():
	stop_typing()
	get_tree().change_scene_to_file("res://Scenes/ui/main_menu.tscn")
