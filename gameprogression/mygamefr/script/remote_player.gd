extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func update_state(pos: Vector2, flip_h: bool, animation: String):
	global_position = pos
	sprite.flip_h = flip_h
	if sprite.animation != animation:
		sprite.play(animation)
