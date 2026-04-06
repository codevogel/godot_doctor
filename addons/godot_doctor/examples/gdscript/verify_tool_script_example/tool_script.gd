## A simple tool script with exported variables for demonstrative purposes.
## Used by GodotDoctor to show how to validate exported variables in a tool script.
@tool
class_name ToolScript
extends Node

## An integer that must be less than `my_max_int`.
@export var my_int: int = 0
## The maximum allowed value for `my_int`.
@export var my_max_int: int = 100


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.simple(
			my_int <= my_max_int, "my_int must be less than %s but is %s" % [my_max_int, my_int]
		),
	]
	return conditions
