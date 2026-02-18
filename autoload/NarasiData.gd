extends Node

var data_narasi = {}

func _ready():
	load_data()

func load_data():
	var file = FileAccess.open("res://data/narasi.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			data_narasi = json.data
			print("✅ Narasi loaded: ", data_narasi.keys())
		else:
			print("❌ Error parsing narasi.json")
	else:
		print("❌ File narasi.json tidak ditemukan")
		create_default_data()

func get_narasi(hewan_id: String) -> Dictionary:
	if data_narasi.has(hewan_id):
		return data_narasi[hewan_id]
	return {}

func create_default_data():
	data_narasi = {
		"anoa": {
			"pembuka": "Ini adalah Anoa, hewan endemik Sulawesi.",
			"fakta_1": "Anoa adalah kerbau kerdil.",
			"penutup": "Jaga Anoa!"
		}
	}
