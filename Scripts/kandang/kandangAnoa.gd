extends Control

# ID hewan (sesuai dengan key di JSON)
@export var hewan_id: String = "anoa"

# Referensi node
@onready var background = $Background if has_node("Background") else null
@onready var btn_close = $CloseButton if has_node("CloseButton") else null
@onready var panel = $Panel if has_node("Panel") else null
@onready var judul = $Panel/JudulLabel if has_node("Panel/JudulLabel") else null
@onready var foto = $Panel/FotoHewan if has_node("Panel/FotoHewan") else null
@onready var deskripsi = $Panel/deskripsi if has_node("Panel/deskripsi") else null
@onready var btn_audio = $Panel/ButtonAudio if has_node("Panel/ButtonAudio") else null
@onready var btn_kuis = $Panel/ButtonKuis if has_node("Panel/ButtonKuis") else null
@onready var btn_kembali = $ButtonKembali if has_node("ButtonKembali") else null
@onready var audio_player = $AudioNarasi if has_node("AudioNarasi") else null

# Referensi untuk 3D
@onready var viewport_container = $SubViewportContainer if has_node("SubViewportContainer") else null
@onready var sub_viewport = $SubViewportContainer/SubViewport if has_node("SubViewportContainer/SubViewport") else null
@onready var camera_3d = $SubViewportContainer/SubViewport/Camera3D if has_node("SubViewportContainer/SubViewport/Camera3D") else null
@onready var hewan_3d = $SubViewportContainer/SubViewport/anoa if has_node("SubViewportContainer/SubViewport/anoa") else null
@onready var anim_player = $AnimationPlayer if has_node("AnimationPlayer") else null

# Data hewan
var hewan_data = {}

func _ready():
	# Debug: Cek node
	check_nodes()
	
	# Ambil data dari AnimalData
	if has_node("/root/AnimalData"):
		print("✅ AnimalData ditemukan")
		hewan_data = AnimalData.get_hewan(hewan_id)
		
		# Tandai hewan ini sudah dikunjungi
		if not hewan_data.is_empty():
			AnimalData.kunjungi_hewan(hewan_id)
	else:
		print("❌ AnimalData TIDAK ditemukan, pakai fallback")
		hewan_data = get_fallback_data()
	
	# Setup viewport sebelum 3D
	setup_viewport()
	
	# Setup UI
	setup_ui()
	
	# Setup 3D
	setup_3d()
	
	# Hubungkan sinyal
	connect_signals()
	
	# Setup audio
	setup_audio()
	
	# Debug status setelah setup
	await get_tree().process_frame
	debug_viewport_status()

func check_nodes():
	print("🔍 Memeriksa node di scene KandangAnoa:")
	var nodes = [
		"Background", "CloseButton", "Panel", 
		"Panel/JudulLabel", "Panel/FotoHewan", "Panel/deskripsi",
		"Panel/ButtonAudio", "Panel/ButtonKuis", "ButtonKembali",
		"AudioNarasi", "SubViewportContainer", "AnimationPlayer",
		"SubViewportContainer/SubViewport/anoa"
	]
	
	for path in nodes:
		if has_node(path):
			print("  ✅ ", path)
		else:
			print("  ❌ ", path)
	
	# Cek node di dalam viewport
	if has_node("SubViewportContainer/SubViewport"):
		print("  🔍 Node di dalam SubViewport:")
		var viewport = $SubViewportContainer/SubViewport
		for child in viewport.get_children():
			print("    - ", child.name, " (", child.get_class(), ")")
			# Jika anaknya Node3D, cek komponennya
			if child is Node3D:
				for grandchild in child.get_children():
					print("      * ", grandchild.name, " (", grandchild.get_class(), ")")

func setup_viewport():
	"""Atur SubViewportContainer dan SubViewport agar 3D muncul"""
	print("🔧 Setup Viewport:")
	
	if viewport_container:
		# Atur container
		viewport_container.stretch = true
		viewport_container.anchor_left = 0.4
		viewport_container.anchor_top = 0.1
		viewport_container.anchor_right = 0.8
		viewport_container.anchor_bottom = 0.8
		print("  ✅ SubViewportContainer stretch=", viewport_container.stretch)
		
		if sub_viewport:
			# RESET KE PENGATURAN DEFAULT YANG AMAN
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			sub_viewport.disable_3d = false
			sub_viewport.transparent_bg = false
			sub_viewport.size = Vector2i(512, 512)
			print("  ✅ SubViewport diatur:")
			print("     - disable_3d: ", sub_viewport.disable_3d)
			print("     - transparent_bg: ", sub_viewport.transparent_bg)
			print("     - update_mode: ", sub_viewport.render_target_update_mode)
			
			# PASTIKAN ADA CAHAYA
			var has_light = false
			for child in sub_viewport.get_children():
				if child is Light3D:
					has_light = true
					print("  ✅ Cahaya ditemukan: ", child.name)
					break
			
			if not has_light:
				print("  ⚠️ Tidak ada cahaya, menambahkan cahaya default")
				var light = DirectionalLight3D.new()
				light.name = "DirectionalLight"
				light.rotation_degrees = Vector3(-45, 45, 0)
				light.light_energy = 1.5
				sub_viewport.add_child(light)
			
			# ATUR KAMERA
			if camera_3d:
				print("  ✅ Camera3D ditemukan")
				# Reset kamera ke posisi aman
				camera_3d.current = true
				camera_3d.position = Vector3(3, 2, 3)
				camera_3d.rotation_degrees = Vector3(-20, 135, 0)
				
				# Arahkan ke pusat
				camera_3d.look_at(Vector3(0, 1, 0), Vector3.UP)
				
				print("     - position: ", camera_3d.position)
				print("     - rotation: ", camera_3d.rotation_degrees)
				print("     - current: ", camera_3d.current)
			else:
				print("  ❌ Camera3D tidak ditemukan")
				create_default_camera()
		else:
			print("  ❌ SubViewport tidak ditemukan")
			create_default_viewport()
	else:
		print("  ❌ SubViewportContainer tidak ditemukan")
		create_default_viewport()

func create_default_camera():
	"""Buat kamera default jika tidak ada"""
	if not sub_viewport:
		return
	
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(3, 2, 3)
	camera.rotation_degrees = Vector3(-20, 135, 0)
	camera.current = true
	camera.look_at(Vector3(0, 1, 0), Vector3.UP)
	sub_viewport.add_child(camera)
	camera_3d = camera
	print("✅ Kamera default dibuat")

func create_default_viewport():
	"""Buat viewport default jika tidak ada"""
	print("🛠️ Membuat viewport default...")
	
	var container = SubViewportContainer.new()
	container.name = "SubViewportContainer"
	container.anchor_left = 0.4
	container.anchor_top = 0.1
	container.anchor_right = 0.8
	container.anchor_bottom = 0.8
	container.stretch = true
	add_child(container)
	viewport_container = container
	
	var viewport = SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = Vector2i(512, 512)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = false
	viewport.transparent_bg = false
	container.add_child(viewport)
	sub_viewport = viewport
	
	# Buat kamera
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(3, 2, 3)
	camera.rotation_degrees = Vector3(-20, 135, 0)
	camera.current = true
	viewport.add_child(camera)
	camera_3d = camera
	
	# Buat cahaya
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight"
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 1.5
	viewport.add_child(light)
	
	print("✅ Viewport default dibuat dengan kamera dan cahaya")

func connect_signals():
	if btn_audio:
		btn_audio.pressed.connect(_on_audio_pressed)
		print("✅ Signal btn_audio terhubung")
	if btn_kuis:
		btn_kuis.pressed.connect(_on_kuis_pressed)
		print("✅ Signal btn_kuis terhubung")
	if btn_kembali:
		btn_kembali.pressed.connect(_on_kembali_pressed)
		print("✅ Signal btn_kembali terhubung")
	if btn_close:
		btn_close.pressed.connect(_on_kembali_pressed)
		print("✅ Signal btn_close terhubung")

func setup_ui():
	if hewan_data.is_empty():
		if deskripsi:
			deskripsi.text = "Data hewan tidak ditemukan!"
		return
	
	# Judul
	if judul:
		judul.text = hewan_data.get("nama", "HEWAN").to_upper()
		print("✅ Judul diatur: ", judul.text)
	
	# Deskripsi
	if deskripsi:
		var teks = "[b]" + hewan_data.get("nama_latin", "") + "[/b]\n\n"
		teks += hewan_data.get("fakta_menarik", "") + "\n\n"
		teks += "🌳 [b]Habitat:[/b] " + hewan_data.get("habitat", "") + "\n"
		teks += "🍃 [b]Makanan:[/b] " + hewan_data.get("makanan", "") + "\n"
		teks += "⚠️ [b]Status:[/b] " + hewan_data.get("status", "")
		deskripsi.text = teks
		print("✅ Deskripsi diatur")
	
	# Foto
	if foto:
		var foto_paths = [
			"res://Assets/gambar/" + hewan_id + ".jpg",
			"res://Assets/gambar/" + hewan_id + ".png",
			"res://Assets/gambar/" + hewan_id + ".jpeg"
		]
		
		var loaded = false
		for path in foto_paths:
			if ResourceLoader.exists(path):
				foto.texture = load(path)
				loaded = true
				print("✅ Foto dimuat dari: ", path)
				break
		
		if not loaded:
			# Placeholder
			var image = Image.create(400, 300, false, Image.FORMAT_RGBA8)
			image.fill(Color(0.5, 0.7, 0.5))
			foto.texture = ImageTexture.create_from_image(image)
			print("🖼️ Menggunakan placeholder foto")

func setup_3d():
	"""Setup model 3D dan animasi"""
	print("🎬 Setup 3D:")
	
	# CARI MODEL 3D DI VIEWPORT (TIDAK HANYA YANG BERNAMA "anoa")
	var found_model = false
	
	if sub_viewport:
		# Cari semua Node3D di viewport (kecuali camera dan light)
		for child in sub_viewport.get_children():
			if child is Node3D and not child is Camera3D and not child is Light3D:
				hewan_3d = child
				found_model = true
				print("  ✅ Model 3D ditemukan: ", child.name, " (", child.get_class(), ")")
				break
	
	if found_model and hewan_3d:
		print("  ✅ Menggunakan model: ", hewan_3d.name)
		
		# Reset posisi model ke tengah
		hewan_3d.position = Vector3(0, 0, 0)
		hewan_3d.visible = true
		
		# Atur scale jika perlu
		if hewan_3d.has_method("get_scale"):
			print("     - scale saat ini: ", hewan_3d.scale)
		
		# Mainkan animasi jika ada AnimationPlayer
		if anim_player:
			# Cek apakah ada animasi yang bisa dimainkan
			var anim_list = anim_player.get_animation_list()
			if anim_list.size() > 0:
				anim_player.play(anim_list[0])
				print("  ✅ Animasi '", anim_list[0], "' dimainkan")
			else:
				print("  ⚠️ Tidak ada animasi di AnimationPlayer")
		else:
			print("  ⚠️ AnimationPlayer tidak ditemukan")
	else:
		print("  ⚠️ Model 3D tidak ditemukan di viewport, buat model sederhana")
		create_simple_model()

func create_simple_model():
	"""Buat model sederhana jika tidak ada asset"""
	print("🛠️ Membuat model sederhana...")
	
	if not sub_viewport:
		print("❌ Tidak bisa membuat model: viewport tidak ada")
		return
	
	# Hapus model lama jika ada (agar tidak numpuk)
	for child in sub_viewport.get_children():
		if child is Node3D and not child is Camera3D and not child is Light3D:
			child.queue_free()
	
	# Buat node untuk model
	var model = Node3D.new()
	model.name = "anoa_placeholder"
	sub_viewport.add_child(model)
	hewan_3d = model
	
	# Buat material yang lebih terang
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.5, 0.2)
	
	# Buat badan (cube)
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.scale = Vector3(1.2, 0.8, 2.0)
	body.position = Vector3(0, 1, 0)
	body.material_override = material
	model.add_child(body)
	
	# Buat kepala (sphere)
	var head = MeshInstance3D.new()
	head.mesh = SphereMesh.new()
	head.scale = Vector3(0.6, 0.6, 0.6)
	head.position = Vector3(1.5, 1.8, 0)
	head.material_override = material
	model.add_child(head)
	
	# Buat kaki
	var kaki_material = StandardMaterial3D.new()
	kaki_material.albedo_color = Color(0.6, 0.4, 0.15)
	
	var kaki_pos = [Vector3(-0.7, 0.4, 0.8), Vector3(0.7, 0.4, 0.8), 
					Vector3(-0.7, 0.4, -0.8), Vector3(0.7, 0.4, -0.8)]
	
	for pos in kaki_pos:
		var kaki = MeshInstance3D.new()
		kaki.mesh = BoxMesh.new()
		kaki.scale = Vector3(0.4, 0.8, 0.4)
		kaki.position = pos
		kaki.material_override = kaki_material
		model.add_child(kaki)
	
	# Buat lantai sederhana agar model tidak melayang
	var floor = MeshInstance3D.new()
	floor.mesh = BoxMesh.new()
	floor.scale = Vector3(5, 0.1, 5)
	floor.position = Vector3(0, -0.5, 0)
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.3, 0.5, 0.3)
	floor.material_override = floor_material
	sub_viewport.add_child(floor)
	
	print("✅ Model sederhana dibuat dengan lantai")
	
	# Buat animasi
	create_simple_animation()

func create_simple_animation():
	"""Buat animasi sederhana untuk model"""
	if not hewan_3d:
		return
	
	# Buat AnimationPlayer jika belum ada
	if not anim_player:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		add_child(anim_player)
	
	# Buat animation library
	var library = AnimationLibrary.new()
	var anim = Animation.new()
	anim.length = 4.0
	
	# Track rotasi
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, str(hewan_3d.get_path()) + ":rotation_degrees")
	anim.track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(track_idx, 2.0, Vector3(0, 180, 0))
	anim.track_insert_key(track_idx, 4.0, Vector3(0, 360, 0))
	anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_LINEAR)
	
	# Tambahkan animasi ke library
	library.add_animation("rotate", anim)
	
	# Tambahkan library ke AnimationPlayer
	anim_player.add_animation_library("", library)
	
	# Mainkan animasi
	anim_player.play("rotate")
	print("✅ Animasi rotasi dibuat")

func setup_audio():
	if audio_player:
		var audio_paths = [
			"res://Assets/audio/" + hewan_id + ".ogg",
			"res://Assets/audio/" + hewan_id + ".mp3"
		]
		
		for path in audio_paths:
			if ResourceLoader.exists(path):
				audio_player.stream = load(path)
				audio_player.finished.connect(_on_audio_finished)
				if btn_audio:
					btn_audio.disabled = false
					btn_audio.icon = get_theme_icon("Play", "EditorIcons")
				print("✅ Audio dimuat dari: ", path)
				return
		
		# Jika tidak ada audio
		if btn_audio:
			btn_audio.disabled = true
			btn_audio.text = "🔇"
			print("⚠️ Audio tidak ditemukan")
	else:
		print("⚠️ Audio player tidak ditemukan")

func _on_audio_pressed():
	if not audio_player or not audio_player.stream:
		return
	
	if audio_player.playing:
		audio_player.stop()
		btn_audio.icon = get_theme_icon("Play", "EditorIcons")
	else:
		audio_player.play()
		btn_audio.icon = get_theme_icon("Stop", "EditorIcons")

func _on_audio_finished():
	if btn_audio:
		btn_audio.icon = get_theme_icon("Play", "EditorIcons")

func _on_kuis_pressed():
	var kuis_data = hewan_data.get("kuis", {})
	if kuis_data.size() > 0:
		print("📋 Membuka kuis untuk ", hewan_id)
		if has_node("/root/SceneSwitcher"):
			SceneSwitcher.goto_scene("res://Scenes/ui/kuisUI.tscn", {
				"hewan_id": hewan_id,
				"hewan_nama": hewan_data.get("nama", ""),
				"kuis_pertanyaan": kuis_data.get("pertanyaan", ""),
				"kuis_pilihan": kuis_data.get("pilihan", []),
				"kuis_jawaban": kuis_data.get("jawaban_benar", 0)
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
	print("🔙 Kembali ke world")
	if has_node("/root/SceneSwitcher"):
		SceneSwitcher.goto_scene("res://Scenes/world.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/world.tscn")

func debug_viewport_status():
	print("\n=== STATUS VIEWPORT ===")
	
	if viewport_container:
		print("Container - stretch: ", viewport_container.stretch)
		print("Container - anchors: ", viewport_container.anchor_left, ",", viewport_container.anchor_top, ",", viewport_container.anchor_right, ",", viewport_container.anchor_bottom)
		
		if sub_viewport:
			print("\n📊 Viewport Settings:")
			print("  - size: ", sub_viewport.size)
			print("  - disable_3d: ", sub_viewport.disable_3d)
			print("  - transparent_bg: ", sub_viewport.transparent_bg)
			print("  - update_mode: ", sub_viewport.render_target_update_mode)
			
			print("\n📋 Node di Viewport:")
			var node_count = 0
			var has_camera = false
			var has_light = false
			
			for child in sub_viewport.get_children():
				print("  - ", child.name, " (", child.get_class(), ")")
				node_count += 1
				
				if child is Camera3D:
					has_camera = true
					print("    📷 pos: ", child.position)
					print("    📷 current: ", child.current)
				if child is Light3D:
					has_light = true
					print("    💡 energy: ", child.light_energy)
			
			print("\nTotal node: ", node_count)
			print("Camera ada: ", has_camera)
			print("Light ada: ", has_light)
			
			# Cek texture
			var tex = sub_viewport.get_texture()
			if tex:
				print("\nTexture size: ", tex.get_size())
			else:
				print("\n❌ Tidak ada texture")
		else:
			print("❌ SubViewport tidak ada")
	else:
		print("❌ SubViewportContainer tidak ada")
	
	print("========================\n")

func get_fallback_data() -> Dictionary:
	return {
		"nama": "ANOA",
		"nama_latin": "Bubalus depressicornis",
		"fakta_menarik": "Anoa adalah hewan endemik Sulawesi yang terancam punah.",
		"habitat": "Hutan Sulawesi",
		"makanan": "Rumput, daun",
		"status": "Terancam Punah",
		"kuis": {
			"pertanyaan": "Di mana habitat asli Anoa?",
			"pilihan": ["Jawa", "Sumatera", "Sulawesi", "Kalimantan"],
			"jawaban_benar": 2
		}
	}
