extends Control

# Path to your main game scene — update this to match your actual scene path
const GAME_SCENE = "res://Main/main.tscn"

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Grab focus so keyboard/controller works immediately
	start_button.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(res://Main/main.tscn)


func _on_quit_pressed() -> void:
	get_tree().quit()
