## Holds validation results for a single resource.
class_name GodotDoctorResourceReport
extends GodotDoctorReport

## The resource path (or UID) identifying the validated resource.
var _resource_path: String
## The list of validation messages associated with this resource.
var _validation_messages: Array[GodotDoctorValidationMessage] = []


## Creates a new [GodotDoctorResourceReport] for the resource at [param resource_path]
## with the given [param validation_messages].
func _init(resource_path: String, validation_messages: Array[GodotDoctorValidationMessage]) -> void:
	_resource_path = resource_path
	_validation_messages = validation_messages


## Returns the number of [constant ValidationCondition.Severity.INFO]-level validation
## messages for this resource.
func get_num_infos() -> int:
	return _get_num_infos(_validation_messages)


## Returns the number of [constant ValidationCondition.Severity.WARNING]-level validation
## messages for this resource.
func get_num_warnings() -> int:
	return _get_num_warnings(_validation_messages)


## Returns the number of [constant ValidationCondition.Severity.ERROR]-level validation
## messages for this resource.
func get_num_errors() -> int:
	return _get_num_errors(_validation_messages)


## Returns the path (or UID) of the validated resource.
func get_resource_path() -> String:
	return _resource_path


## Returns all validation messages associated with this resource.
func get_validation_messages() -> Array[GodotDoctorValidationMessage]:
	return _validation_messages
