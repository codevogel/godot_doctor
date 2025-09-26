extends RefCounted
class_name ValidationResult

## Indicates whether the validation passed or failed.
## True if there are no errors, false otherwise.
var ok: bool:
	get:
		return errors.size() == 0

## The list of error messages
var errors: PackedStringArray = []


## Initializes the ValidationResult.
## Provide an array of ValidationCondition, and it will evaluate them,
## populating the Results' errors array with any resulting error messages.
func _init(conditions: Array[ValidationCondition]) -> void:
	errors = Validation.evaluate_conditions(conditions)
