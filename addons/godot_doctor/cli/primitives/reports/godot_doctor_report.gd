## Base class for all Godot Doctor report types.
## Provides shared utilities for counting and filtering validation messages by severity.
class_name GodotDoctorReport


## Returns the number of [constant ValidationCondition.Severity.INFO]-level messages from
## [param validation_messages].
func _get_num_infos(validation_messages: Array[GodotDoctorValidationMessage]) -> int:
	return _filter_by_severity_level(validation_messages, ValidationCondition.Severity.INFO).size()


## Returns the number of [constant ValidationCondition.Severity.WARNING]-level messages from
## [param validation_messages].
func _get_num_warnings(validation_messages: Array[GodotDoctorValidationMessage]) -> int:
	return (
		_filter_by_severity_level(validation_messages, ValidationCondition.Severity.WARNING).size()
	)


## Returns the number of [constant ValidationCondition.Severity.ERROR]-level messages from
## [param validation_messages].
func _get_num_errors(validation_messages: Array[GodotDoctorValidationMessage]) -> int:
	return _filter_by_severity_level(validation_messages, ValidationCondition.Severity.ERROR).size()


## Returns messages from [param validation_messages] that match the given [param severity].
func _filter_by_severity_level(
	validation_messages: Array[GodotDoctorValidationMessage], severity: int
) -> Array[GodotDoctorValidationMessage]:
	return validation_messages.filter(
		func(message: GodotDoctorValidationMessage) -> bool:
			return message.severity_level == severity
	)
