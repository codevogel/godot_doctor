## A base class for validation warning UI components.
## Contains common UI elements like [member icon], [member label], and [member button].
## Subclasses should implement [method _select_origin] to define behaviour
## when [member button] is pressed.
## Used by [GodotDoctorDock] to display validation warnings for nodes and resources.
@abstract
@tool
class_name GodotDoctorValidationWarning
extends MarginContainer

## The icon displayed in the warning.
@export var icon: TextureRect
## The label displaying the warning message.
@export var label: RichTextLabel
## The button that, when pressed, selects the origin of the warning.
@export var button: Button


## Connects the [member button] pressed signal on entering the scene tree.
func _ready() -> void:
	_connect_signals()


## Connects the [member button] pressed signal to [method _on_button_pressed].
func _connect_signals() -> void:
	button.pressed.connect(_on_button_pressed)


## Called when [member button] is pressed; delegates to [method _select_origin].
func _on_button_pressed() -> void:
	_select_origin()


## Selects or navigates to the warning's origin in the editor.
@abstract func _select_origin() -> void
