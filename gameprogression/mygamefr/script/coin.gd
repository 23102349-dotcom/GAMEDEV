extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.collect_coin()
		$Picksound.play()
		# Hide coin immediately but wait for sound to finish before deleting
		$AnimatedSprite2D.visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		await $Picksound.finished
		queue_free()
