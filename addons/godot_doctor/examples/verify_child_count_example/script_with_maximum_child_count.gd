extends Node
class_name ScriptWithMaximumChildCount


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [ValidationCondition.has_maximum_child_count(self, 3, name)]
