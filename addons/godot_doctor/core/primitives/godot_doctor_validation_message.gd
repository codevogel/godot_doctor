## Holds a single validation message produced during a validation run.
## Contains a [member message] string and a [member severity_level] indicating its severity.
## Used by [GodotDoctorValidator] to convey information, warnings, or errors about
## validation targets.
class_name GodotDoctorValidationMessage
extends RefCounted

## The text content of this validation message.
var message: String
## The severity of this message, expressed as a [enum ValidationCondition.Severity] value.
var severity_level: ValidationCondition.Severity


## Initializes the validation message with [param message] as its text content
## and [param severity_level] as its severity.
func _init(message: String, severity_level: ValidationCondition.Severity) -> void:
	self.message = message
	self.severity_level = severity_level


static func promoted_severity_level(
	treat_warnings_as_errors: bool, severity_level: ValidationCondition.Severity
) -> ValidationCondition.Severity:
	if treat_warnings_as_errors and severity_level == ValidationCondition.Severity.WARNING:
		return ValidationCondition.Severity.ERROR
	return severity_level


static func map_to_promoted_severity_levels(
	treat_warnings_as_errors: bool, messages: Array[GodotDoctorValidationMessage]
) -> Array[ValidationCondition.Severity]:
	var mapped_promoted_severity_levels: Array = messages.map(
		func(msg: GodotDoctorValidationMessage) -> ValidationCondition.Severity:
			return promoted_severity_level(treat_warnings_as_errors, msg.severity_level)
	)
	var severity_levels: Array[ValidationCondition.Severity] = []
	severity_levels.assign(mapped_promoted_severity_levels)
	return severity_levels
