## A warning that is associated with a `Node` in the scene tree.
## Clicking on the warning will select the `Node` in the scene tree.
## Used by GodotDoctor to show warnings related to nodes.
@tool
class_name NodeValidationWarning
extends ValidationWarning

## The node that caused the warning.
var origin_node: Node


## Select the origin of the warning by selecting the node in the scene tree.
func _select_origin() -> void:
	EditorInterface.edit_node(origin_node)
