## A class that holds the result of a validation operation.
## Evaluates a set of ValidationCondition upon initialization,
## and stores any resulting error messages.
## Used by GodotDoctor to report validation results.
class_name ValidationResult
extends RefCounted

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
	errors = GodotDoctor.evaluate_conditions(conditions)
