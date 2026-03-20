## A collection of validation messages for nodes.
class_name GodotDoctorNodeValidationCollection
extends GodotDoctorValidationCollection

## A dictionary mapping node ancestor paths to their validation messages.
## [code]key[/code] is the node ancestor path as a [String],
## and [code]value[/code] is [code]Array[lb]GodotDoctorValidationMessage[rb][/code].
var _node_ancestor_path_to_validation_messages_map: Dictionary = {}


## Adds the validation [param messages] for [param node_ancestor_path] to the collection.
## Fails if [param node_ancestor_path] already has validation messages in the collection.
func add_node_validation(
	node_ancestor_path: String, messages: Array[GodotDoctorValidationMessage]
) -> void:
	GodotDoctorNotifier.print_debug(
		"Adding node validation for node: %s to collection %s" % [node_ancestor_path, self], self
	)
	_add_and_fail_if_already_has(
		node_ancestor_path, messages, _node_ancestor_path_to_validation_messages_map
	)


## Returns the map of node ancestor paths to their validation messages.
func get_node_ancestor_path_to_validation_messages_map() -> Dictionary:
	return _node_ancestor_path_to_validation_messages_map
