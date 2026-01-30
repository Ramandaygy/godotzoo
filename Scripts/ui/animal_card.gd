extends Button
class_name AnimalCard

signal card_pressed(animal_data)

var animal_data: Dictionary = {}

func _ready():
	focus_mode = Control.FOCUS_NONE


func set_data(data: Dictionary):
	animal_data = data

	# Nama hewan
	if has_node("CardContent/AnimalName"):
		$CardContent/AnimalName.text = animal_data.get("Nama", "Unknown")

	# Icon
	if has_node("CardContent/AnimalIcon"):
		var img_path = animal_data.get("image", "")
		if img_path != "" and FileAccess.file_exists(img_path):
			$CardContent/AnimalIcon.texture = load(img_path)


func _pressed():
	if animal_data.is_empty():
		push_warning("AnimalCard ditekan tapi data kosong")
		return

	print("CARD DITEKAN:", animal_data.get("Nama"))
	card_pressed.emit(animal_data)
