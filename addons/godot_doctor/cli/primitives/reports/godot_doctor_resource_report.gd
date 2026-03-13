## Holds the validation messages collected for a single resource during a CLI validation run.
class_name GodotDoctorResourceReport

## The validated [Resource].
var resource: Resource
## The [GodotDoctorValidationMessage]s produced for this resource.
var messages: Array[GodotDoctorValidationMessage]


## Initializes the report with [param resource] and [param messages].
func _init(resource: Resource, messages: Array[GodotDoctorValidationMessage]) -> void:
	self.resource = resource
	self.messages = messages


## Returns the number of messages with severity level [constant ValidationCondition.Severity.INFO]
## for this resource.
func get_info_messages_count() -> int:
	var info_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.INFO
	)
	return info_messages.size()


## Returns the number of messages with severity level
## [constant ValidationCondition.Severity.WARNING] for this resource.
func get_warning_messages_count() -> int:
	var warning_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.WARNING
	)
	return warning_messages.size()


## Returns the number of messages with severity level [constant ValidationCondition.Severity.ERROR]
## for this resource.
func get_hard_error_messages_count() -> int:
	var hard_error_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.ERROR
	)
	return hard_error_messages.size()


func has_errors(treat_warnings_as_errors: bool) -> bool:
	var total_errors = get_hard_error_messages_count()
	if treat_warnings_as_errors:
		total_errors += get_warning_messages_count()
	return total_errors > 0
