extends Node

const SERVER_KEY = "defaultkey"
const HOST = "127.0.0.1"
const PORT = 7350

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var match_id: String = ""
var my_session_id: String = ""
var players: Dictionary = {}

signal match_joined
signal player_joined(session_id)
signal player_left(session_id)
signal player_state_received(session_id, state)
func _ready():
	client = Nakama.create_client(SERVER_KEY, HOST, PORT, "http", false)
	print("Nakama client created")

func authenticate():
	print("Authenticating...")
	var device_id = str(randi()) + str(Time.get_ticks_msec())
	var result = await client.authenticate_device_async(device_id, null, true)
	if result == null:
		print("Auth result is null!")
		return false
	if result.is_exception():
		print("Auth failed: ", result.get_exception().message)
		return false
	session = result
	print("Authenticated! User ID: ", session.user_id)
	return true

func connect_socket():
	print("Connecting socket...")
	if session == null:
		print("Session is null!")
		return false
	
	var adapter = NakamaSocketAdapter.new()
	add_child(adapter)
	socket = NakamaSocket.new(adapter, HOST, PORT, "ws", false)
	
	var result = await socket.connect_async(session)
	if result == null or result.is_exception():
		print("Socket failed: ", result.get_exception().message if result else "null")
		return false
	
	socket.received_match_state.connect(_on_match_state)
	socket.received_match_presence.connect(_on_match_presence)
	print("Socket connected!")
	return true

func create_match():
	print("Creating match...")
	if socket == null:
		print("Socket is null!")
		return ""
	var result = await socket.create_match_async()
	if result == null or result.is_exception():
		print("Create match error: ", result.get_exception().message if result else "null")
		return ""
	match_id = result.match_id
	my_session_id = result.self_user.session_id
	print("Match created! ID: ", match_id)
	# Do NOT emit match_joined here — lobby handles host flow
	return match_id

func join_match(id: String):
	print("Joining match: ", id)
	if socket == null:
		print("Socket is null!")
		return false
	var result = await socket.join_match_async(id)
	if result == null or result.is_exception():
		print("Join error: ", result.get_exception().message if result else "null")
		return false
	match_id = result.match_id
	my_session_id = result.self_user.session_id
	
	# Spawn players already in the match before we joined
	for presence in result.presences:
		if presence.session_id != my_session_id:
			players[presence.session_id] = presence
			print("Already in match: ", presence.session_id)
	
	emit_signal("match_joined")  # lobby loads game.tscn here
	return true

func send_player_state(pos: Vector2, flip_h: bool, animation: String):
	if socket == null or match_id == "":
		print("Cannot send state - socket: ", socket, " match_id: ", match_id)
		return
	print("Sending state: ", pos)  # add this
	var state = {
		"x": pos.x,
		"y": pos.y,
		"flip": flip_h,
		"anim": animation
	}
	socket.send_match_state_async(match_id, 1, JSON.stringify(state))
func _on_match_state(state):
	var decoded = JSON.parse_string(state.data)  # remove the base64 decode
	if decoded:
		emit_signal("player_state_received", state.presence.session_id, decoded)
func _on_match_presence(presence):
	for user in presence.joins:
		if user.session_id != my_session_id:
			players[user.session_id] = user
			emit_signal("player_joined", user.session_id)
			print("Player joined: ", user.session_id)
	for user in presence.leaves:
		players.erase(user.session_id)
		emit_signal("player_left", user.session_id)
		print("Player left: ", user.session_id)
