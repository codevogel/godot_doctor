@tool
extends MarginContainer
class_name ValidationWarning

var origin_node: Node
@export var icon: TextureRect
@export var label: RichTextLabel
@export var button: Button


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	var selection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(origin_node)
