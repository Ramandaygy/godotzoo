extends Control

# ============================================
# KUIS_UI.GD - Panel Kuis Pilihan Ganda
# ============================================

var id_hewan: String = ""
var data_kuis: Dictionary = {}
var jawaban_benar: int = 0
var sudah_jawab: bool = false

@onready var judul_label = $Panel/VBoxContainer/JudulLabel
@onready var pertanyaan_label = $Panel/VBoxContainer/PertanyaanLabel
@onready var pilihan_container = $Panel/VBoxContainer/PilihanContainer
@onready var feedback_label = $Panel/VBoxContainer/FeedbackLabel

func _ready():
	# Tetap jalan saat pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	feedback_label.hide()
	print("❓ KuisUI ready")

func setup(id: String, kuis_data: Dictionary):
	id_hewan = id
	data_kuis = kuis_data
	
	# Validasi data
	if kuis_data.is_empty():
		push_error("Kuis data empty")
		queue_free()
		return
	
	jawaban_benar = kuis_data.get("jawaban_benar", 0)
	
	# Set judul dengan nama hewan
	var nama_hewan = AnimalData.get_hewan(id).get("nama", "Hewan")
	judul_label.text = "Kuis " + nama_hewan
	
	# Set pertanyaan
	pertanyaan_label.text = kuis_data.get("pertanyaan", "Pertanyaan?")
	
	# Setup tombol pilihan
	var pilihan = kuis_data.get("pilihan", ["A", "B", "C", "D"])
	for i in range(4):
		var btn = pilihan_container.get_child(i)
		if i < pilihan.size():
			btn.text = String.chr(65 + i) + ". " + pilihan[i]  # A. B. C. D.
			btn.pressed.connect(_on_jawab.bind(i))
			btn.modulate = Color.WHITE  # Reset warna
			btn.disabled = false
		else:
			btn.hide()  # Sembunyikan kalau pilihan kurang dari 4
	
	sudah_jawab = false
	print("❓ Kuis setup: ", pertanyaan_label.text)

func _on_jawab(index: int):
	if sudah_jawab:
		return
	
	sudah_jawab = true
	var btn = pilihan_container.get_child(index)
	
	print("📝 Jawaban: ", index, " (Benar: ", jawaban_benar, ")")
	
	# Cek jawaban
	if index == jawaban_benar:
		# BENAR
		btn.modulate = Color.GREEN
		feedback_label.text = "✅ Benar! Bagus sekali!"
		feedback_label.modulate = Color.GREEN
		AudioControl.play_narasi("Benar! Bagus sekali!")
	else:
		# SALAH
		btn.modulate = Color.RED
		var huruf_benar = String.chr(65 + jawaban_benar)
		feedback_label.text = "❌ Salah! Jawaban yang benar: " + huruf_benar
		feedback_label.modulate = Color.RED
		
		# Highlight jawaban benar
		pilihan_container.get_child(jawaban_benar).modulate = Color.GREEN
	
	feedback_label.show()
	
	# Disable semua tombol
	for i in range(4):
		pilihan_container.get_child(i).disabled = true
	
	# Tutup otomatis setelah 3 detik
	await get_tree().create_timer(3.0).timeout
	print("❌ Kuis closing")
	queue_free()
