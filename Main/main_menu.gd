extends Control

@onready var play_button = $MarginContainer/VBoxContainer/PlayButton
@onready var options_button = $MarginContainer/VBoxContainer/OptionsButton
@onready var quit_button = $MarginContainer/VBoxContainer/QuitButton

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	play_button.grab_focus()

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Main/main.tscn")

func _on_options_pressed():
	print("Options menu opening...")

func _on_quit_pressed():
	get_tree().quit()
