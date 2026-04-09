extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("collect_coin"):
		body.collect_coin()
		$Picksound.play()
		$AnimatedSprite2D.visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		await $Picksound.finished
		queue_free()
