extends Node

const REMOTE_PLAYER_SCENE = preload("res://scenes/remote_player.tscn")
var remote_players: Dictionary = {}

func _ready():
	if NakamaManager.socket == null:
		return
	
	NakamaManager.player_joined.connect(_on_player_joined)
	NakamaManager.player_left.connect(_on_player_left)
	NakamaManager.player_state_received.connect(_on_player_state)
	
	# Wait one frame for scene to fully initialize
	await get_tree().process_frame
	
	# Spawn anyone already in the match
	for session_id in NakamaManager.players:
		print("Spawning existing player: ", session_id)
		_on_player_joined(session_id)
func _on_player_joined(session_id: String):
	print("Remote player joined: ", session_id)
	if remote_players.has(session_id):
		return
	var remote = REMOTE_PLAYER_SCENE.instantiate()
	remote.name = session_id
	add_child(remote)
	remote_players[session_id] = remote

func _on_player_left(session_id: String):
	print("Remote player left: ", session_id)
	if remote_players.has(session_id):
		remote_players[session_id].queue_free()
		remote_players.erase(session_id)

func _on_player_state(session_id: String, state: Dictionary):
	if remote_players.has(session_id):
		var pos = Vector2(state["x"], state["y"])
		var flip = state["flip"]
		var anim = state["anim"]
		remote_players[session_id].update_state(pos, flip, anim)
