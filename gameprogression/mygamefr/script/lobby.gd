extends Node2D

@onready var status_label = $CanvasLayer/VBoxContainer/StatusLabel
@onready var create_btn = $CanvasLayer/VBoxContainer/CreateMatch
@onready var join_btn = $CanvasLayer/VBoxContainer/JoinMatch
@onready var match_id_input = $CanvasLayer/VBoxContainer/MatchIDInput

var is_searching: bool = false

func _ready():
	create_btn.pressed.connect(_on_create_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	status_label.text = "Connecting..."
	NakamaManager.match_joined.connect(_on_match_joined)
	await _connect()

func _connect():
	var ok = await NakamaManager.authenticate()
	if not ok:
		status_label.text = "Auth failed!"
		return
	ok = await NakamaManager.connect_socket()
	if not ok:
		status_label.text = "Socket failed!"
		return
	status_label.text = "Connected! Choose an option."

func _on_create_pressed():
	if is_searching:
		return
	is_searching = true
	create_btn.disabled = true
	join_btn.disabled = true
	status_label.text = "Creating match..."

	var id = await NakamaManager.create_match()
	if id == "":
		status_label.text = "Failed to create match!"
		is_searching = false
		create_btn.disabled = false
		join_btn.disabled = false
		return

	# Show ID briefly then go straight to game
	status_label.text = "Match ID:\n[" + id + "]\n\nLoading world..."
	await get_tree().create_timer(2.0).timeout  # give player time to read the ID
	get_tree().change_scene_to_file("res://scenes/game.tscn")
func _on_join_pressed():
	if is_searching:
		return
	var id = match_id_input.text.strip_edges()
	if id == "":
		status_label.text = "Enter a Match ID first!"
		return
	is_searching = true
	create_btn.disabled = true
	join_btn.disabled = true
	status_label.text = "Joining match..."
	await NakamaManager.join_match(id)

func _on_match_joined():
	status_label.text = "Match joined! Loading game..."
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")
