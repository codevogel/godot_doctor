@tool
extends ValidationWarning
class_name NodeValidationWarning

var origin_node: Node


func _select_origin() -> void:
	EditorInterface.edit_node(origin_node)
