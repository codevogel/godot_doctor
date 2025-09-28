@tool
extends Node
class_name MyTool

@export var my_int: int = 0


func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.simple(my_int > 10, "my_int must be greater than 10"),
	]
	return conditions
