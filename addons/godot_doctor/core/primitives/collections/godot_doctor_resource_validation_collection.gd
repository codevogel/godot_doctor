## A collection of validation messages for a resource.
class_name GodotDoctorResourceValidationCollection
extends GodotDoctorValidationCollection

## A dictionary mapping resource paths to their validation messages.
## [code]key[/code] is the resource path as a [String], and [code]value[/code] is
## [code]Array[lb]GodotDoctorValidationMessage[rb][/code].
var _resource_path_to_validation_messages_map: Dictionary = {}


## Adds the validation [param messages] for [param resource_path] to the collection.
## Fails if [param resource_path] already has validation messages in the collection.
func add_resource_validation(
	resource_path: String, messages: Array[GodotDoctorValidationMessage]
) -> void:
	GodotDoctorNotifier.print_debug(
		"Adding resource validation for resource: %s to collection %s" % [resource_path, self], self
	)
	_add_and_fail_if_already_has(resource_path, messages, _resource_path_to_validation_messages_map)


## Returns the map of resource paths to their validation messages.
func get_resource_path_to_validation_messages_map() -> Dictionary:
	return _resource_path_to_validation_messages_map
