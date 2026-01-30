extends Control

@onready var animal_view = $PaddingPage/MainContainer/ContentContainer/AnimalView
@onready var zone_view = $PaddingPage/MainContainer/ContentContainer/ZoneView
@onready var animal_grid = $PaddingPage/MainContainer/ContentContainer/AnimalView/AnimalGrid

@onready var detail_overlay = $DetailOverlay
@onready var detail_panel = $DetailOverlay/DetailPanel
@onready var detail_title = $DetailOverlay/DetailPanel/PanelPadding/PanelContent/AnimalTitle
@onready var detail_image = $DetailOverlay/DetailPanel/PanelPadding/PanelContent/AnimalImage


func _ready():
	show_animal()

	detail_overlay.visible = false
	detail_panel.visible = false

	if detail_overlay.has_node("OverlayBg"):
		$DetailOverlay/OverlayBg.gui_input.connect(_on_overlay_clicked)

	load_data_to_existing_cards()
	register_existing_cards()

func show_animal():
	animal_view.visible = true
	zone_view.visible = false


func show_zone():
	animal_view.visible = false
	zone_view.visible = true


func _on_animal_tab_button_toggled(button_pressed: bool):
	if button_pressed:
		show_animal()


func _on_zona_tab_button_toggled(button_pressed: bool):
	if button_pressed:
		show_zone()

func load_data_to_existing_cards():
	var animals := AnimalData.load_animals()
	var cards := animal_grid.get_children()

	for i in range(min(animals.size(), cards.size())):
		var card = cards[i]
		if card is AnimalCard:
			card.set_data(animals[i])

func register_existing_cards():
	for card in animal_grid.get_children():
		if card is AnimalCard:
			if not card.card_pressed.is_connected(open_animal_detail):
				card.card_pressed.connect(open_animal_detail)

func open_animal_detail(animal_data: Dictionary):
	print("OPEN POPUP:", animal_data.get("Nama"))

	detail_overlay.visible = true
	detail_panel.visible = true

	detail_title.text = animal_data.get("Nama", "Unknown")

	if animal_data.has("image") and FileAccess.file_exists(animal_data["image"]):
		detail_image.texture = load(animal_data["image"])

func _on_overlay_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		detail_overlay.visible = false
		detail_panel.visible = false
