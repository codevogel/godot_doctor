## A warning associated with a [Node] in the scene tree.
## Clicking the warning selects [member origin_node] in the scene tree.
## Used by [GodotDoctorDock] to show validation warnings related to nodes.
@tool
class_name GodotDoctorNodeValidationWarning
extends GodotDoctorValidationWarning

## The node that caused the warning.
var origin_node: Node

## The root node of the scene that contains [member origin_node].
var origin_node_root: Node


## Selects [member origin_node] in the scene tree editor.
func _select_origin() -> void:
	if origin_node == null:
		GodotDoctorNotifier.print_debug(
			"Cannot select origin node for validation warning because origin_node is null.", self
		)
		push_warning(
			"Cannot select origin node for validation warning because origin_node is null."
		)
		return
	EditorInterface.open_scene_from_path(origin_node_root.scene_file_path)
	EditorInterface.edit_node(origin_node)
