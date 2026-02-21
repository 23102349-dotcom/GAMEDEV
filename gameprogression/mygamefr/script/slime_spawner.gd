extends Node

const SLIME_SCENE = preload("res://scenes/Slime.tscn")
const SPAWN_TIME = 5.0

@onready var spawn_point = $Marker2D

@export var slime_name: String = "Slime"

var timer: float = 0.0
var counting: bool = false

func _ready():
	var slime = get_parent().get_node_or_null(slime_name)
	if slime:
		slime.spawner = self
		print("Spawner ", name, " assigned to: ", slime.name)
	else:
		print("Spawner ", name, " could not find: ", slime_name)

func _process(delta: float) -> void:
	if not counting:
		return
	timer += delta
	if timer >= SPAWN_TIME:
		timer = 0.0
		counting = false
		spawn_slime()

func start_spawn_timer():
	timer = 0.0
	counting = true
	print(name, " slime died - spawning in ", SPAWN_TIME, " seconds...")

func spawn_slime():
	var slime = SLIME_SCENE.instantiate()
	slime.position = spawn_point.global_position
	slime.spawner = self
	get_parent().add_child(slime)
	print(name, " spawned a new slime!")
