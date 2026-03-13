## A warning associated with a [Node] in the scene tree.
## Clicking the warning selects [member origin_node] in the scene tree.
## Used by GodotDoctor to show validation warnings related to nodes.
@tool
class_name GodotDoctorNodeValidationWarning
extends GodotDoctorValidationWarning

## The node that caused the warning.
var origin_node: Node


## Selects [member origin_node] in the scene tree editor.
func _select_origin() -> void:
	EditorInterface.edit_node(origin_node)
