## A simple example script demonstrating how to cap the maximum number of children.
## Used by GodotDoctor to show the [method ValidationCondition.has_maximum_child_count] helper.
class_name ScriptWithMaximumChildCount
extends Node


## Returns a [ValidationCondition] that fails if this node has more than 3 children.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [ValidationCondition.has_maximum_child_count(self, 3, name)]
