## A simple example script demonstrating how to require an exact child count.
## Used by GodotDoctor to show the [method ValidationCondition.has_child_count] helper.
class_name ScriptWithChildCount
extends Node


## Returns a [ValidationCondition] that fails if this node does not have exactly 3 children.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [ValidationCondition.has_child_count(self, 3, name)]
