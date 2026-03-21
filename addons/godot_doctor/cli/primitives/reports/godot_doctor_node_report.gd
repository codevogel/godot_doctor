## Holds validation results for a single node within a scene.
class_name GodotDoctorNodeReport
extends GodotDoctorReport

## The path of the node relative to the scene root, including all ancestor names.
var _node_ancestor_path: String
## The list of validation messages associated with this node.
var _validation_messages: Array[GodotDoctorValidationMessage] = []


## Creates a new [GodotDoctorNodeReport] for the node at [param node_ancestor_path]
## with the given [param validation_messages].
func _init(
	node_ancestor_path: String, validation_messages: Array[GodotDoctorValidationMessage]
) -> void:
	_node_ancestor_path = node_ancestor_path
	_validation_messages = validation_messages


## Returns the number of [constant ValidationCondition.Severity.INFO]-level validation
## messages for this node.
func get_num_infos() -> int:
	return _get_num_infos(_validation_messages)


## Returns the number of [constant ValidationCondition.Severity.WARNING]-level validation
## messages for this node.
func get_num_warnings() -> int:
	return _get_num_warnings(_validation_messages)


## Returns the number of [constant ValidationCondition.Severity.ERROR]-level validation
## messages for this node.
func get_num_errors() -> int:
	return _get_num_errors(_validation_messages)


## Returns the ancestor path of this node relative to the scene root.
func get_node_ancestor_path() -> String:
	return _node_ancestor_path


## Returns all validation messages associated with this node.
func get_validation_messages() -> Array[GodotDoctorValidationMessage]:
	return _validation_messages


## Returns the name of the node, derived from its ancestor path.
func get_node_name() -> String:
	var ancestor_node_names: PackedStringArray = _node_ancestor_path.split("/")
	return ancestor_node_names[ancestor_node_names.size() - 1]
