extends CharacterBody2D

const SPEED = 60.0
const DETECT_RANGE = 150.0
const ATTACK_RANGE = 30.0
const IDLE_TIME = 1.0
const MAX_HP = 10

@export var move_distance: float = 100.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var attack_hitbox: Area2D = $AttackHitbox

const PORTAL_SCENE = preload("res://scenes/portal.tscn")

var hp: int = MAX_HP
var direction: int = 1
var idle_timer: float = 0.0
var is_attacking: bool = false
var is_hurt: bool = false
var player = null
var start_position: Vector2
var already_hit: Array = []

enum State { IDLE, ATTACK, HURT }
var state = State.IDLE

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("idle")
	start_position = global_position
	player = get_tree().get_first_node_in_group("player")
	set_collision_mask_value(2, false)
	attack_hitbox.set_deferred("monitoring", false)
	attack_hitbox.body_entered.connect(_on_attack_hit)

func _on_attack_hit(body):
	if body in already_hit:
		return
	if body.is_in_group("player"):
		already_hit.append(body)
		body.take_damage(20)

func _physics_process(delta: float) -> void:
	if is_hurt:
		return

	var distance = INF
	if player:
		distance = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			floor_check.position.x = abs(floor_check.position.x) * direction

			if not floor_check.is_colliding():
				direction *= -1
			elif global_position.x >= start_position.x + move_distance:
				direction = -1
			elif global_position.x <= start_position.x - move_distance:
				direction = 1

			velocity.x = direction * SPEED
			sprite.flip_h = direction > 0
			sprite.play("idle")

			if distance < DETECT_RANGE:
				var dir_to_player = sign(player.global_position.x - global_position.x)
				if abs(player.global_position.x - start_position.x) < move_distance + 20:
					direction = dir_to_player
					sprite.flip_h = direction > 0

			if distance < ATTACK_RANGE:
				state = State.ATTACK
				start_attack()
				return

			idle_timer -= delta
			if idle_timer <= 0:
				velocity.x = 0
				idle_timer = IDLE_TIME

		State.ATTACK:
			velocity.x = 0

	move_and_slide()

func start_attack():
	is_attacking = true
	already_hit.clear()
	sprite.play("attack")
	await get_tree().create_timer(0.3).timeout
	if not is_attacking or state != State.ATTACK:
		attack_hitbox.set_deferred("monitoring", false)
		return
	attack_hitbox.set_deferred("monitoring", true)
	await get_tree().create_timer(0.2).timeout
	attack_hitbox.set_deferred("monitoring", false)
	already_hit.clear()

func take_damage(amount: int):
	if is_hurt:
		return
	hp -= amount
	print("Boss HP: ", hp)
	if hp <= 0:
		is_attacking = false
		attack_hitbox.set_deferred("monitoring", false)
		already_hit.clear()
		sprite.play("die")
		set_physics_process(false)
		return
	is_attacking = false
	attack_hitbox.set_deferred("monitoring", false)
	already_hit.clear()
	is_hurt = true
	state = State.HURT
	velocity.x = 0
	sprite.play("hurt")

func _on_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false
		attack_hitbox.set_deferred("monitoring", false)
		already_hit.clear()
		state = State.IDLE
		sprite.play("idle")
		idle_timer = randf_range(2.0, 5.0)
	elif sprite.animation == "hurt":
		is_hurt = false
		is_attacking = false
		attack_hitbox.set_deferred("monitoring", false)
		already_hit.clear()
		state = State.IDLE
		sprite.play("idle")
	elif sprite.animation == "die":
		var portal = PORTAL_SCENE.instantiate()
		portal.position = position
		get_parent().call_deferred("add_child", portal)
		queue_free()
