extends Node
class_name AnimalData

static func load_animals() -> Array:
	var path := "res://data/animals.json"

	if not FileAccess.file_exists(path):
		push_error("animals.json not found")
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open animals.json")
		return []

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed == null or typeof(parsed) != TYPE_ARRAY:
		push_error("Invalid animals.json format (must be Array)")
		return []

	return parsed
