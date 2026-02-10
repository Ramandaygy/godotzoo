extends HSlider

@export var audio_bus_name: String

var audio_bus_id 


func _ready() -> void:
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)

# ============================================
# TTS FUNCTIONS - Text to Speech
# Ditambahkan untuk Virtual Zoo Tour
# ============================================

## Fungsi: Memainkan narasi dengan suara TTS
## Parameter: teks (String) - teks yang akan dibacakan
func play_narasi(teks: String):
	if teks.is_empty():
		push_warning("TTS: Empty text provided")
		return
	
	# Hentikan narasi yang sedang berjalan
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
		print("🔇 Stopped previous TTS")
	
	# Cari suara Bahasa Indonesia
	var voices = DisplayServer.tts_get_voices_for_language("id")
	var selected_voice = ""
	
	if voices.size() > 0:
		selected_voice = voices[0]
		print("🔊 Using Indonesian voice: ", selected_voice.substr(0, 30))
	else:
		# Fallback: pakai suara apa saja yang tersedia
		var all_voices = DisplayServer.tts_get_voices()
		if all_voices.size() > 0:
			selected_voice = all_voices[0]
			print("🔊 Using default voice: ", selected_voice.substr(0, 30))
		else:
			push_error("❌ No TTS voices available on this device")
			return
	
	# Mainkan TTS
	DisplayServer.tts_speak(teks, selected_voice)
	print("🗣️ TTS: ", teks.substr(0, 50), "...")

## Fungsi: Menghentikan narasi TTS
func stop_narasi():
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
		print("🔇 TTS stopped by request")
