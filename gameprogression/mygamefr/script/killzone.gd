extends Area2D

@onready var timer = $Timer

func _ready():
	timer.timeout.connect(_on_timer_timeout)

func _on_body_entered(_body):
	if not _body.name == "Player":
		return
	body_entered.disconnect(_on_body_entered)
	print("You Died")
	timer.start()

func _on_timer_timeout():
	get_tree().reload_current_scene()
