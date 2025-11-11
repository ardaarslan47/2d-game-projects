class_name ActionMenu
extends PanelContainer

## Action menu popup for player actions.
## Displays available actions like Move, Attack, Wait, Cancel.

# Signals
signal action_selected(action: String)

# Onready variables
@onready var move_button: Button = $VBoxContainer/MoveButton
@onready var attack_button: Button = $VBoxContainer/AttackButton
@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton


func _ready() -> void:
	# Connect button signals
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	# Initially hide the menu
	hide()


## Show the menu at the specified screen position.
func show_at_position(screen_pos: Vector2) -> void:
	global_position = screen_pos
	show()


## Hide the menu.
func hide_menu() -> void:
	hide()


# Button handlers
func _on_move_pressed() -> void:
	print("ActionMenu: Move selected")
	action_selected.emit("move")
	hide()


func _on_attack_pressed() -> void:
	print("ActionMenu: Attack selected")
	action_selected.emit("attack")
	hide()


func _on_wait_pressed() -> void:
	print("ActionMenu: Wait selected")
	action_selected.emit("wait")
	hide()


func _on_cancel_pressed() -> void:
	print("ActionMenu: Cancel selected")
	action_selected.emit("cancel")
	hide()
