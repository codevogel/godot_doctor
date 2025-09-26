extends Node
# Global class_name is Validation


## Evaluates a list of ValidationConditions and returns a PackedStringArray of error messages for those that fail.
static func evaluate_conditions(conditions: Array[ValidationCondition]) -> PackedStringArray:
	var errors: PackedStringArray = []
	for condition in conditions:
		if not condition.evaluate():
			errors.append(condition.error_message)
	return errors
