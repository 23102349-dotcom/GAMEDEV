extends CanvasLayer

@onready var border: AnimatedSprite2D = $AnimatedSprite2D
@onready var portrait: AnimatedSprite2D = $AnimatedSprite2D2

func _ready():
	await get_tree().process_frame
	portrait.play("idle")

func update_portrait(anim_name: String, flipped: bool = false):  # 👈 added flipped
	if portrait == null:
		return
	if anim_name == "die":
		return
	portrait.flip_h = flipped  # 👈 mirrors the direction
	portrait.play(anim_name)
