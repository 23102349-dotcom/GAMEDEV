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
@onready var jump_sound = $Jumpsound
@onready var attack_sound = $Attacksound

var death_screen = preload("res://scenes/death_scene.tscn")
var hpbar_scene = preload("res://scenes/hpbar.tscn")
var characterpic_scene = preload("res://scenes/characterpic.tscn")
var hpbar = null
var characterpic = null

var spawn_position: Vector2
var hp: int = MAX_HP
var combo_step: int = 0
var combo_timer: float = 0.0
var attack_queued: bool = false
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var is_hurt: bool = false
var is_dead: bool = false
var coins: int = 0
var current_damage: int = 0
var already_hit: Array = []

# Nakama sync rate limiter
var sync_timer: float = 0.0
const SYNC_RATE: float = 0.05  # send 20 times per second

func _ready():
	spawn_position = global_position
	sprite.animation_finished.connect(_on_animation_finished)
	hitbox_right.set_deferred("monitoring", false)
	hitbox_left.set_deferred("monitoring", false)
	hitbox_right.body_entered.connect(_on_hit)
	hitbox_left.body_entered.connect(_on_hit)

	if not get_tree().root.has_node("hpbar"):
		hpbar = hpbar_scene.instantiate()
		hpbar.name = "hpbar"
		get_tree().root.call_deferred("add_child", hpbar)
	else:
		hpbar = get_tree().root.get_node("hpbar")

	if not get_tree().root.has_node("characterpic"):
		characterpic = characterpic_scene.instantiate()
		characterpic.name = "characterpic"
		get_tree().root.call_deferred("add_child", characterpic)
	else:
		characterpic = get_tree().root.get_node("characterpic")

	await get_tree().process_frame
	hpbar.update_hp(hp, MAX_HP)
	hpbar.update_coins(Global.coins)
	sprite.play("revive")
	characterpic.update_portrait("revive")

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
	if is_dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()
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
	if not is_attacking and not is_hurt:
		if direction != 0:
			sprite.play("run")
			characterpic.update_portrait("run", sprite.flip_h)
		else:
			sprite.play("idle")
			characterpic.update_portrait("idle", sprite.flip_h)
	move_and_slide()

	# Send position to Nakama at a fixed rate
	sync_timer += delta
	if sync_timer >= SYNC_RATE:
		sync_timer = 0.0
		if NakamaManager.socket != null and NakamaManager.match_id != "":
			NakamaManager.send_player_state(global_position, sprite.flip_h, sprite.animation)

func start_attack(heavy: bool):
	is_attacking = true
	attack_queued = false
	attack_cooldown_timer = ATTACK_COOLDOWN
	combo_timer = COMBO_RESET_TIME
	already_hit.clear()
	attack_sound.play()
	if heavy:
		current_damage = HEAVY_ATTACK_DAMAGE
		sprite.play("attack2")
		characterpic.update_portrait("attack2", sprite.flip_h)
	else:
		current_damage = ATTACK_DAMAGE
		combo_step += 1
		sprite.play("attack1")
		characterpic.update_portrait("attack1", sprite.flip_h)
	get_hitbox().set_deferred("monitoring", true)

func _on_animation_finished():
	if sprite.animation == "revive":
		sprite.play("idle")
		characterpic.update_portrait("idle")
		return
	if sprite.animation == "die":
		_show_death_overlay()
		return
	if sprite.animation == "hurt":
		is_hurt = false
		sprite.play("idle")
		characterpic.update_portrait("idle")
		return
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
		characterpic.update_portrait("idle")

func _show_death_overlay():
	var overlay = death_screen.instantiate()
	get_tree().root.add_child(overlay)

func take_damage(amount: int):
	if is_hurt or is_dead:
		return
	hp -= amount
	hpbar.update_hp(hp, MAX_HP)
	print("Player HP: ", hp)
	if hp <= 0:
		is_dead = true
		is_attacking = false
		hitbox_right.set_deferred("monitoring", false)
		hitbox_left.set_deferred("monitoring", false)
		sprite.play("die")
		return
	is_hurt = true
	sprite.play("hurt")
	characterpic.update_portrait("hurt", sprite.flip_h)

func respawn():
	global_position = spawn_position
	velocity = Vector2.ZERO
	hp = MAX_HP
	hpbar.update_hp(hp, MAX_HP)
	hpbar.update_coins(Global.coins)
	is_hurt = false
	is_attacking = false
	combo_step = 0
	attack_cooldown_timer = 0.0
	already_hit.clear()
	hitbox_right.set_deferred("monitoring", false)
	hitbox_left.set_deferred("monitoring", false)
	sprite.play("revive")
	characterpic.update_portrait("revive")
	await sprite.animation_finished
	is_dead = false
	sprite.play("idle")
	characterpic.update_portrait("idle")

func collect_coin():
	Global.coins += 1
	hpbar.update_coins(Global.coins)
	print("Coins: ", Global.coins)
