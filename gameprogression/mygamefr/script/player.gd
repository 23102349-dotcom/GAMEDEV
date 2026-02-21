extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -200.0
const COMBO_RESET_TIME = 0.8
const ATTACK_DAMAGE = 20
const HEAVY_ATTACK_DAMAGE = 40
const ATTACK_COOLDOWN = 1.5
const MAX_HP = 100

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_right: Area2D = $HitboxRight
@onready var hitbox_left: Area2D = $HitboxLeft

var hp: int = MAX_HP
var combo_step: int = 0
var combo_timer: float = 0.0
var attack_queued: bool = false
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var is_hurt: bool = false
var coins: int = 0
var current_damage: int = 0
var already_hit: Array = []  # track who was already hit this swing

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	hitbox_right.set_deferred("monitoring", false)
	hitbox_left.set_deferred("monitoring", false)
	hitbox_right.body_entered.connect(_on_hit)
	hitbox_left.body_entered.connect(_on_hit)

func _on_hit(body):
	if body in already_hit:
		return
	if body.is_in_group("enemy"):
		already_hit.append(body)
		body.take_damage(current_damage)

func get_hitbox() -> Area2D:
	if sprite.flip_h:
		return hitbox_left
	else:
		return hitbox_right

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if combo_step > 0 and not is_attacking:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_step = 0

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	if Input.is_action_just_pressed("attack"):
		if attack_cooldown_timer <= 0:
			if is_attacking:
				attack_queued = true
			else:
				start_attack(false)

	if Input.is_action_just_pressed("heavy_attack"):
		if attack_cooldown_timer <= 0:
			if is_attacking:
				attack_queued = true
			else:
				start_attack(true)

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if not is_attacking:
		if direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")

	move_and_slide()

func start_attack(heavy: bool):
	is_attacking = true
	attack_queued = false
	attack_cooldown_timer = ATTACK_COOLDOWN
	combo_timer = COMBO_RESET_TIME
	already_hit.clear()  # reset hit list each swing

	if heavy:
		current_damage = HEAVY_ATTACK_DAMAGE
		sprite.play("attack2")
	else:
		current_damage = ATTACK_DAMAGE
		combo_step += 1
		sprite.play("attack1")

	get_hitbox().set_deferred("monitoring", true)

func _on_animation_finished():
	if sprite.animation != "attack1" and sprite.animation != "attack2":
		return
	is_attacking = false
	already_hit.clear()
	hitbox_right.set_deferred("monitoring", false)
	hitbox_left.set_deferred("monitoring", false)
	if attack_queued:
		attack_queued = false
		start_attack(false)
	else:
		combo_step = 0
		sprite.play("idle")

func take_damage(amount: int):
	if is_hurt:
		return
	hp -= amount
	print("Player HP: ", hp)
	if hp <= 0:
		get_tree().call_deferred("reload_current_scene")
		return
	is_hurt = true
	await get_tree().create_timer(0.5).timeout
	is_hurt = false

func collect_coin():
	coins += 1
	print("Coins: ", coins)
