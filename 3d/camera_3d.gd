extends Camera3D

@export var mouse_sensitivity := 0.003
@export var min_pitch := -80.0
@export var max_pitch := 80.0
@export var eye_height := 0.5  # tweak this to sit inside your mesh

var pitch := 0.0
var yaw := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	top_level = true

func _physics_process(_delta: float) -> void:
	var player := get_parent()
	global_position = player.global_position + Vector3(0, eye_height, 0)
	rotation.x = pitch
	rotation.y = yaw

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
