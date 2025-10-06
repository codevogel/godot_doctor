## A script that demonstrates how to validate exported variables.
## Used by GodotDoctor to show how to validate exported variables.
extends Node
class_name ScriptWithExportsExample

## A string that must not be empty.
@export var my_string: String = ""
## An integer that must be greater than zero.
@export var my_int: int = -42
## A Node that must be valid and named "ExpectedNodeName".
@export var my_node: Node


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		# A helper method for the condition below is ValidationCondition.string_not_empty,
		# which does the exact same thing, but standardizes the error message.
		ValidationCondition.simple(
			not my_string.strip_edges().is_empty(), "my_string must not be empty"
		),
		ValidationCondition.simple(my_int > 0, "my_int must be greater than zero"),
		ValidationCondition.new(
			func() -> bool:
				return is_instance_valid(my_node) and my_node.name == "ExpectedNodeName",
			"my_node must be valid and named 'ExpectedNodeName'"
		)
		# Note that we could also use the helper method ValidationCondition.is_instance_valid
		# to check if my_node is valid, which would standardize the error message.
	]
