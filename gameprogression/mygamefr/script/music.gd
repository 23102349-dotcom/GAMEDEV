extends Node

var music: AudioStreamPlayer

func _ready():
	music = AudioStreamPlayer.new()
	music.stream = load("res://assets/brackeys_platformer_assets/music/time_for_adventure.mp3")
	add_child(music)
	music.finished.connect(_on_music_finished)
	if not music.playing:
		music.play()

func _on_music_finished():
	music.play()
