@tool
extends Node
class_name MyTool

@export var my_int: int = 0
@export var my_max_int: int = 100


func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.simple(
			my_int <= my_max_int, "my_int must be less than %s but is %s" % [my_max_int, my_int]
		),
	]
	return conditions
