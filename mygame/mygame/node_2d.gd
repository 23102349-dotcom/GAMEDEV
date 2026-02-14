extends Node2D

var velocity := Vector2(200, 150)
@onready var label: Label = $Label

func _ready():
	randomize()
	label.modulate = random_color()

func _process(delta):
	position += velocity * delta

	var screen_size = get_viewport_rect().size
	var label_size = label.size
	var bounced := false

	if position.x <= 0 or position.x + label_size.x >= screen_size.x:
		velocity.x *= -1
		bounced = true

	if position.y <= 0 or position.y + label_size.y >= screen_size.y:
		velocity.y *= -1
		bounced = true

	if bounced:
		label.modulate = random_color()

func random_color() -> Color:
	return Color(randf(), randf(), randf(), 1.0)
