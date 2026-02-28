extends CharacterBody2D

const SPEED = 60.0
const DETECT_RANGE = 150.0
const ATTACK_RANGE = 30.0
const IDLE_TIME = 1.0
const MAX_HP = 50

@export var move_distance: float = 100.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_check: RayCast2D = $FloorCheck
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var death_sound = $Deathsound
@onready var hurt_sound = $Hurtsound
@onready var attack_sound = $Attacksound

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

func is_player_dead() -> bool:  # 👈 helper to check player state
	return player == null or player.is_dead

func _physics_process(delta: float) -> void:
	if is_hurt:
		return

	# 👈 if player is dead, cancel attack and go back to idle roaming
	if is_player_dead():
		if state == State.ATTACK:
			is_attacking = false
			attack_hitbox.set_deferred("monitoring", false)
			already_hit.clear()
			state = State.IDLE
			sprite.play("idle")
		if state == State.IDLE:
			_do_idle_walk(delta)
			move_and_slide()
		return

	var distance = INF
	if player:
		distance = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			_do_idle_walk(delta)

			if distance < DETECT_RANGE:
				var dir_to_player = sign(player.global_position.x - global_position.x)
				if abs(player.global_position.x - start_position.x) < move_distance + 20:
					direction = dir_to_player
					sprite.flip_h = direction > 0

			if distance < ATTACK_RANGE:
				state = State.ATTACK
				start_attack()
				return

		State.ATTACK:
			velocity.x = 0

	move_and_slide()

func _do_idle_walk(delta: float):  # 👈 extracted so we can reuse it
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

	idle_timer -= delta
	if idle_timer <= 0:
		velocity.x = 0
		idle_timer = IDLE_TIME

func start_attack():
	if is_player_dead():  # 👈 don't start attack if player already dead
		state = State.IDLE
		return
	is_attacking = true
	already_hit.clear()
	sprite.play("attack")
	await get_tree().create_timer(1.1).timeout
	if not is_attacking or state != State.ATTACK:
		attack_hitbox.set_deferred("monitoring", false)
		return
	if is_player_dead():  # 👈 check again before hitbox activates
		attack_hitbox.set_deferred("monitoring", false)
		state = State.IDLE
		is_attacking = false
		return
	attack_hitbox.set_deferred("monitoring", true)
	attack_sound.play()
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
	hurt_sound.play()
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
		await get_tree().create_timer(0.2).timeout
		death_sound.play()
		await death_sound.finished
		var portal = PORTAL_SCENE.instantiate()
		portal.position = position
		get_parent().call_deferred("add_child", portal)
		queue_free()
