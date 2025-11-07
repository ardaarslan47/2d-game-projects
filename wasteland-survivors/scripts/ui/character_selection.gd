extends CanvasLayer

## Character selection menu with horizontal carousel navigation.
## Allows player to choose from 10 different characters with unique starting weapons.

signal character_selected(character_data: CharacterData)

var character_registry: Node = null
var current_index: int = 0

@onready var character_sprite: AnimatedSprite2D = $CenterContainer/VBoxContainer/CharacterPreviewContainer/CharacterPreview/AnimatedSprite2D
@onready var character_name_label: Label = $CenterContainer/VBoxContainer/CharacterNameLabel
@onready var weapon_label: Label = $CenterContainer/VBoxContainer/InfoContainer/WeaponLabel
@onready var passive_label: Label = $CenterContainer/VBoxContainer/InfoContainer/PassiveLabel
@onready var left_button: Button = $CenterContainer/VBoxContainer/CharacterPreviewContainer/LeftButton
@onready var right_button: Button = $CenterContainer/VBoxContainer/CharacterPreviewContainer/RightButton

func _ready() -> void:
	# Initialize character registry
	character_registry = Node.new()
	character_registry.set_script(load("res://scripts/character_registry.gd"))
	add_child(character_registry)

	# Load player sprite frames from player scene
	var player_scene: PackedScene = load("res://scenes/characters/player.tscn")
	if player_scene:
		var player_instance: Node = player_scene.instantiate()
		var player_sprite: AnimatedSprite2D = player_instance.get_node("AnimatedSprite2D")
		if player_sprite and player_sprite.sprite_frames:
			character_sprite.sprite_frames = player_sprite.sprite_frames
			character_sprite.animation = "down"
			character_sprite.play()
		player_instance.queue_free()
	else:
		print("Error: Could not load player scene for character preview")

	# Display first character
	_update_character_display()

func _update_character_display() -> void:
	var character: CharacterData = character_registry.get_character_at_index(current_index)
	if character == null:
		return

	# Update sprite color
	character_sprite.modulate = character.character_color

	# Update labels
	character_name_label.text = character.character_name
	weapon_label.text = "Starting Weapon: " + character.starting_weapon
	passive_label.text = "Passive: " + character.passive_description

	# Update button states (disable at edges)
	left_button.disabled = (current_index == 0)
	right_button.disabled = (current_index == character_registry.get_character_count() - 1)

func _on_left_button_pressed() -> void:
	if current_index > 0:
		current_index -= 1
		_update_character_display()

func _on_right_button_pressed() -> void:
	if current_index < character_registry.get_character_count() - 1:
		current_index += 1
		_update_character_display()

func _on_start_button_pressed() -> void:
	var selected_character: CharacterData = character_registry.get_character_at_index(current_index)
	if selected_character != null:
		character_registry.set_selected_character(selected_character)
		# Store in GameManager for global access
		GameManager.set_selected_character(selected_character)
		character_selected.emit(selected_character)
		# Load game scene
		get_tree().change_scene_to_file("res://scenes/game.tscn")
