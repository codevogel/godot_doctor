## A class that holds the result of a validation operation.
## Evaluates a set of [ValidationCondition] instances upon initialization,
## and stores any resulting validation messages.
## Used by [GodotDoctorValidator] to report validation results.
class_name GodotDoctorValidationResult
extends RefCounted

## Indicates whether the validation passed or failed.
## [code]true[/code] if there are no messages, [code]false[/code] otherwise.
var ok: bool:
	get:
		return messages.size() == 0

## The list of validation messages.
var messages: Array[GodotDoctorValidationMessage] = []


## Initializes the result by evaluating [param conditions].
## Any conditions that fail populate [member messages] with their error messages.
func _init(conditions: Array[ValidationCondition]) -> void:
	messages = GodotDoctorValidator.evaluate_conditions(conditions)
