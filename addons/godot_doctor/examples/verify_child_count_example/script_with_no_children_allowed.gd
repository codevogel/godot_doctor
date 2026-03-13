## A simple example script demonstrating how to require that a node has no children.
## Used by GodotDoctor to show the [method ValidationCondition.has_no_children] helper.
class_name ScriptWithNoChildrenAllowed
extends Node


## Returns a [ValidationCondition] that fails if this node has any children.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [ValidationCondition.has_no_children(self, name)]
