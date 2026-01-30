extends CharacterBody3D

const SPEED = 5.0
const GRAVITY = 9.8
const JUMP_VELOCITY = 4.5

@onready var camera = $Camera3D
var sensivity = 0.003


func _ready():
	pass
	

func _unhandled_input(event):
	# ❗ STOP camera movement saat game di-pause
	if get_tree().paused:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensivity)
		camera.rotate_x(-event.relative.y * sensivity)
		camera.rotation.x = clamp(
			camera.rotation.x,
			deg_to_rad(-60),
			deg_to_rad(70)
		)


func _physics_process(delta):
	if get_tree().paused:
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
