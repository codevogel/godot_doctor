## Holds the validation messages collected for a single node during a CLI validation run.
class_name GodotDoctorNodeReport

## A human-readable path string identifying the validated node.
var node_ancestor_path: String
## The [GodotDoctorValidationMessage]s produced for this node.
var messages: Array[GodotDoctorValidationMessage]


## Initializes the report with [param node_ancestor_path] and [param messages].
func _init(node_ancestor_path: String, messages: Array[GodotDoctorValidationMessage]) -> void:
	self.node_ancestor_path = node_ancestor_path
	self.messages = messages


## Returns the number of messages with severity level [constant ValidationCondition.Severity.INFO]
## for this node.
func get_info_messages_count() -> int:
	var info_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.INFO
	)
	return info_messages.size()


## Returns the number of messages with severity level
## [constant ValidationCondition.Severity.WARNING] for this node.
func get_warning_messages_count() -> int:
	var warning_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.WARNING
	)
	return warning_messages.size()


## Returns the number of messages with severity level [constant ValidationCondition.Severity.ERROR]
## for this node.
func get_hard_error_messages_count() -> int:
	var hard_error_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.ERROR
	)
	return hard_error_messages.size()
