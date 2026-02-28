extends CanvasLayer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coin_label: Label = $CoinLabel
@onready var coin_icon: TextureRect = $CoinIcon  # 👈 added

func update_hp(current_hp: int, max_hp: int):
	var percent = float(current_hp) / float(max_hp)
	if percent >= 1.0:
		sprite.play("fullbar")
	elif percent >= 0.8:
		sprite.play("fourbar")
	elif percent >= 0.6:
		sprite.play("midbar")
	elif percent >= 0.4:
		sprite.play("twobar")
	elif percent >= 0.2:
		sprite.play("onebar")
	else:
		sprite.play("nobar")

func update_coins(amount: int):
	coin_label.text = str(amount)  # 👈 just the number, icon does the talking
