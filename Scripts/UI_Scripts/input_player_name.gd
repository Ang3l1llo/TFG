extends Control

@onready var name_player = $LineEdit
@onready var start_button_sound = $Start_button_sound
@onready var start_button = $Button
@onready var loading_bar = $AnimatedSprite2D

func _ready():
	loading_bar.modulate = Color(0, 0.5, 1) 
	loading_bar.visible = false
	
func _on_start_button_pressed():
	start_button.disabled = true
	var nombre = name_player.text.strip_edges()
	start_button_sound.play()
	await start_button_sound.finished
	if nombre != "":
		loading_bar.visible = true
		loading_bar.play()
		Global.create_player(nombre, self)  # Crea el jugador en la API
	else:
		print("Please enter a valid name")

func _on_create_player_completed(_result, response_code, _headers, body):
	if response_code == 201:
		var response = JSON.parse_string(body.get_string_from_utf8())
		Global.player_id = response["id"]
		get_tree().change_scene_to_file("res://Scenes/UI/intro_lore.tscn")
	else:
		print("Error creating player:", response_code)
