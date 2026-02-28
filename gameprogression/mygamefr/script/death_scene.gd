extends CanvasLayer

@onready var spinner = $AnimatedSprite2D
@onready var timer = $Timer
@onready var fog = $ColorRect

var elapsed: float = 0.0

func _ready():
	spinner.play("loading")
	timer.wait_time = 6.0
	timer.one_shot = true
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _process(delta):
	elapsed += delta
	# animate the fog by updating shader time
	fog.material.set_shader_parameter("time_offset", elapsed * 1.5)

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.respawn()
	queue_free()
