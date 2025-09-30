@abstract @tool
extends MarginContainer
class_name ValidationWarning

@export var icon: TextureRect
@export var label: RichTextLabel
@export var button: Button


func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	button.pressed.connect(_on_button_pressed)
	
func _on_button_pressed() -> void:
	_select_origin()
	
@abstract
func _select_origin() -> void
