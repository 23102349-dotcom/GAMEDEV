extends Area2D

@export var is_level_2: bool = false

func _ready():
	if is_level_2:
		monitoring = false
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		get_tree().call_deferred("change_scene_to_file", "res://scenes/next_level.tscn")
