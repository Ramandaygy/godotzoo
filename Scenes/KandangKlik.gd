# kandang_klik.gd (FIX - Tanpa Global/UIHelper)
extends Node3D

@export var kandang_scene_path: String = "res://Scenes/kandang/KandangAnoa.tscn"
@export var hewan_id: String = "anoa"
@export var jarak_klik_maksimal: float = 10.0

@onready var area_klik: Area3D = $AreaKlik
@onready var kandang_trigger: Area3D = $KandangTrigger if has_node("KandangTrigger") else null
@onready var visual_kandang: MeshInstance3D = $VisualKandang if has_node("VisualKandang") else null

var player: Node3D = null
var bisa_diklik: bool = false
var is_hovering: bool = false
var hint_label: Label = null

func _ready():
	if area_klik:
		area_klik.input_event.connect(_on_area_input_event)
		area_klik.mouse_entered.connect(_on_mouse_entered)
		area_klik.mouse_exited.connect(_on_mouse_exited)
		print("✅ AreaKlik setup")
	
	if kandang_trigger:
		kandang_trigger.body_entered.connect(_on_trigger_enter)
		kandang_trigger.body_exited.connect(_on_trigger_exit)
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	# Buat hint label
	setup_hint_label()

func setup_hint_label():
	hint_label = Label.new()
	hint_label.name = "KandangHint"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.position = Vector2(400, 550)
	hint_label.size = Vector2(400, 50)
	hint_label.add_theme_font_size_override("font_size", 20)
	hint_label.add_theme_color_override("font_color", Color.WHITE)
	hint_label.visible = false
	get_tree().root.add_child(hint_label)

func _process(_delta):
	if player:
		var jarak = global_position.distance_to(player.global_position)
		bisa_diklik = jarak <= jarak_klik_maksimal

func _on_trigger_enter(body: Node3D):
	if body.is_in_group("player"):
		player = body
		bisa_diklik = true

func _on_trigger_exit(body: Node3D):
	if body.is_in_group("player"):
		bisa_diklik = false
		hide_hint()

func _on_mouse_entered():
	is_hovering = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	highlight_visual(true)
	
	if bisa_diklik:
		show_hint("Klik untuk melihat " + hewan_id)

func _on_mouse_exited():
	is_hovering = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	highlight_visual(false)
	hide_hint()

func _on_area_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if bisa_diklik:
				klik_kandang()
			else:
				show_hint("Terlalu jauh! Dekatkan untuk melihat " + hewan_id)

func klik_kandang():
	print("🎯 Masuk kandang: ", hewan_id)
	
	# Simpan data sementara di root
	var save_node = Node.new()
	save_node.name = "TempKandangData"
	save_node.set_meta("hewan_id", hewan_id)
	if player:
		save_node.set_meta("player_pos", player.global_position)
	get_tree().root.add_child(save_node)
	
	# Pindah scene
	get_tree().change_scene_to_file(kandang_scene_path)

func highlight_visual(aktif: bool):
	if visual_kandang:
		var tween = create_tween()
		if aktif:
			tween.tween_property(visual_kandang, "scale", Vector3(1.05, 1.05, 1.05), 0.2)
		else:
			tween.tween_property(visual_kandang, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

func show_hint(teks: String):
	if hint_label:
		hint_label.text = teks
		hint_label.visible = true

func hide_hint():
	if hint_label:
		hint_label.visible = false
