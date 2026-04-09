@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("Nakama", "res://addons/com.heroiclabs.nakama/Nakama.gd")

func _exit_tree():
	remove_autoload_singleton("Nakama")
