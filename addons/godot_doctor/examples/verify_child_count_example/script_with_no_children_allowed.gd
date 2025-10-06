extends Node
class_name ScriptWithNoChildrenAllowed


func _get_validation_conditions() -> Array[ValidationCondition]:
	return [ValidationCondition.has_no_children(self, name)]
