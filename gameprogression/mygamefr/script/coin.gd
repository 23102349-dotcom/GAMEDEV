extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	print("Coin ready!")

func _on_body_entered(body):
	print("Coin touched by: ", body.name)
	if body.name == "Player":
		body.collect_coin()
		queue_free() 
