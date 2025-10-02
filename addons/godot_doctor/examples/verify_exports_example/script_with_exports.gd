extends Node
class_name ScriptWithExportsExample

@export var my_string: String = ""
@export var my_int: int = -42
@export var my_node: Node


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		ValidationCondition.simple(
			not my_string.strip_edges().is_empty(), "my_string must not be empty"
		),
		ValidationCondition.simple(my_int > 0, "my_int must be greater than zero"),
		ValidationCondition.new(
			func() -> bool:
				return is_instance_valid(my_node) and my_node.name == "ExpectedNodeName",
			"my_node must be valid and named 'ExpectedNodeName'"
		)
	]
