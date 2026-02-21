extends CharacterBody2D

const SPEED = 30.0
const MAX_HP = 10

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $DamageZone

const COIN_SCENE = preload("res://scenes/coin.tscn")

var direction: int = 1
var is_hurt: bool = false
var hp: int = MAX_HP
var spawner = null

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	add_to_group("enemy")
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, false)
	damage_zone.body_entered.connect(_on_damage_zone_entered)

func _on_damage_zone_entered(body):
	if body.is_in_group("player"):
		body.take_damage(10)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_hurt:
		velocity.x = direction * SPEED
		move_and_slide()
		if is_on_wall():
			direction *= -1
			sprite.flip_h = direction < 0
	else:
		velocity.x = 0
		move_and_slide()

func take_damage(amount: int):
	if is_hurt:
		return
	hp -= amount
	print("Slime HP: ", hp)
	if hp <= 0:
		drop_coin()
		if spawner:
			spawner.start_spawn_timer()
		queue_free()
		return
	is_hurt = true
	sprite.play("hurt")

func drop_coin():
	var coin = COIN_SCENE.instantiate()
	coin.position = position
	get_parent().call_deferred("add_child", coin)

func _on_animation_finished():
	if sprite.animation == "hurt":
		is_hurt = false
