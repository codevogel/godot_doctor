class_name ScriptWithChildCount
extends Node


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [ValidationCondition.has_child_count(self, 3, name)]
