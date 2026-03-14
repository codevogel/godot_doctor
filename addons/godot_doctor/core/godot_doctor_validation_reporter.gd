## Base class for reporting validation results.
## Subclass this to implement different output strategies (editor UI, CLI, JSON, etc.)
@abstract class_name GodotDoctorValidationReporter

## Reports on the validation [param messages] produced by validating a [param node].
@abstract
func report_node_messages(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void

## Reports on the validation [param messages] produced by validating a [param resource].
@abstract func report_resource_messages(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void

## Called after all validation is complete
@abstract func on_validation_complete() -> void


## Returns a copy of [param validation_messages] with all WARNING severity levels promoted to ERROR.
func _apply_warnings_as_errors(
	validation_messages: Array[GodotDoctorValidationMessage],
) -> Array[GodotDoctorValidationMessage]:
	return validation_messages.map(
		func(msg: GodotDoctorValidationMessage) -> GodotDoctorValidationMessage:
			msg.severity_level = (
				msg.severity_level
				if msg.severity_level == ValidationCondition.Severity.ERROR
				else ValidationCondition.Severity.ERROR
			)
			return msg
	)


static func promoted_severity_level(
	treat_warnings_as_errors: bool, severity_level: ValidationCondition.Severity
) -> ValidationCondition.Severity:
	if treat_warnings_as_errors and severity_level == ValidationCondition.Severity.WARNING:
		return ValidationCondition.Severity.ERROR
	return severity_level
