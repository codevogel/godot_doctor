@tool
extends Resource
class_name MyResource

@export var my_string: String
@export var my_int: int
@export var my_max_int: int = 10
@export var my_min_int: int = 0


func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
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


func get_validation_conditions() -> Array[ValidationCondition]:
	return _get_validation_conditions()
