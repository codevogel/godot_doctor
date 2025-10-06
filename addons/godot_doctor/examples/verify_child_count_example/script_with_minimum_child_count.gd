extends Node
class_name ScriptWithMinimumChildCount


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [ValidationCondition.has_minimum_child_count(self, 3, name)]
