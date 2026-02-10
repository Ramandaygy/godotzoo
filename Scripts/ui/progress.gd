extends Control  # atau CanvasLayer, sesuaikan

# ============================================
# PROGRESS.GD - HUD Koleksi Hewan
# ============================================

@onready var progress_label: Label = $ProgressLabel  # Sesuaikan nama!
@onready var grid_container: GridContainer = $GridContainer  # Sesuaikan!
@onready var prompt_label: Label = $PromptLabel  # Untuk "Tekan E..."

func _ready():
	# Connect ke signal AnimalData
	AnimalData.data_updated.connect(update_display)
	AnimalData.hewan_dikunjungi.connect(_on_hewan_baru)
	
	# Update tampilan awal
	update_display()
	
	# Sembunyikan prompt awalnya
	if prompt_label:
		prompt_label.hide()
	
	print("📊 Progress HUD ready")

func update_display():
	var prog = AnimalData.get_progress()
	
	# Update label counter
	if progress_label:
		progress_label.text = str(prog.dikunjungi) + "/" + str(prog.total) + " Hewan Dikunjungi"
	
	# Update icon grid (kalau ada)
	if grid_container:
		var i = 0
		for id in AnimalData.data_hewan:
			if i < grid_container.get_child_count():
				var icon = grid_container.get_child(i)
				
				# Ganti warna berdasarkan status
				if AnimalData.is_dikunjungi(id):
					icon.modulate = Color.WHITE  # Terang = sudah
				else:
					icon.modulate = Color.DARK_GRAY  # Gelap = belum
			i += 1
	
	print("📊 Progress updated: ", prog.dikunjungi, "/", prog.total)

func _on_hewan_baru(id: String):
	print("🎉 New animal visited: ", id)
	# Bisa tambah animasi, efek, atau suara di sini

func show_prompt(text: String):
	if prompt_label:
		prompt_label.text = text
		prompt_label.show()

func hide_prompt():
	if prompt_label:
		prompt_label.hide()
