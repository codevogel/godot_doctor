## A class that holds the result of a validation operation.
## Evaluates a set of ValidationCondition upon initialization,
## and stores any resulting error messages.
## Used by GodotDoctor to report validation results.
class_name ValidationResult
extends RefCounted

## Indicates whether the validation passed or failed.
## True if there are no messages, false otherwise.
var ok: bool:
	get:
		return messages.size() == 0

## The list of error messages
var messages: Array[ValidationMessage] = []


## Initializes the ValidationResult.
## Provide an array of ValidationCondition, and it will evaluate them,
## populating the Results' messages array with any resulting error messages.
func _init(conditions: Array[ValidationCondition]) -> void:
	messages = GodotDoctor.evaluate_conditions(conditions)
