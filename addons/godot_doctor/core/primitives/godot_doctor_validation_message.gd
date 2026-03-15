## Holds a single validation message produced during a validation run.
## Contains a [member message] string and a [member severity_level] indicating its severity.
## Used by GodotDoctor to convey information, warnings, or errors about validation targets.
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
