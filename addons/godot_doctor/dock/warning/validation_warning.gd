## A base class for validation warning UI components.
## Contains common UI elements like icon, label, and button.
## Subclasses should implement the _select_origin method to
## define behavior when the button is pressed.
## Used by GodotDoctor to display validation warnings for nodes and resources.
@abstract
@tool
class_name ValidationWarning
extends MarginContainer

## The icon displayed in the warning.
@export var icon: TextureRect
## The label displaying the warning message.
@export var label: RichTextLabel
## The button that, when pressed, selects the origin of the warning.
@export var button: Button


## Connect signals when the node is ready.
func _ready() -> void:
	_connect_signals()


## Connect signals for the button.
func _connect_signals() -> void:
	button.pressed.connect(_on_button_pressed)


## Handle button press to select the origin of the warning.
func _on_button_pressed() -> void:
	_select_origin()


## Abstract method to select the origin of the warning.
@abstract func _select_origin() -> void
