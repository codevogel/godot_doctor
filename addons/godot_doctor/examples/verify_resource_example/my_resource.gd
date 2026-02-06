## A simple Resource with exported variables and validation conditions.
## Used by GodotDoctor to demonstrate resource validation.
@tool
class_name MyResource
extends Resource

## A string that must not be empty.
@export var my_string: String
## An integer that must be between `my_min_int` and `my_max_int`.
@export var my_int: int = -1
## The maximum allowed value for `my_int`.
@export var my_max_int: int = 10
## The minimum allowed value for `my_int`.
@export var my_min_int: int = 0


## Get `ValidationCondition`s for exported variables.
## The signature is _get_validation_conditions(),
## so the validator can report incorrect values when inspecting this resource in the inspector.
func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		# A helper method for the condition below is ValidationCondition.is_in_range_int,
		# which does the exact same thing, but standardizes the error message.
		ValidationCondition.simple(
			my_int >= my_min_int and my_int <= my_max_int,
			"my_int must be between %d and %d, but is %s." % [my_min_int, my_max_int, my_int]
		),
		ValidationCondition.simple(my_string != "", "my_string must not be empty."),
		ValidationCondition.simple(
			my_max_int >= my_min_int, "my_max_int must be greater than or equal to my_min_int."
		),
		ValidationCondition.simple(
			my_min_int <= my_max_int, "my_min_int must be less than or equal to my_max_int."
		)
	]
	return conditions


## We can expose it publicly as well,
## so we can call it from other Nodes during scene validation,
## and return a nested array of `ValidationCondition`s
func get_validation_conditions() -> Array[ValidationCondition]:
	return _get_validation_conditions()
