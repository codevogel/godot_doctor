class_name Validation


## Evaluates a list of ValidationConditions and returns a PackedStringArray of error messages for those that fail.
static func evaluate_conditions(conditions: Array[ValidationCondition]) -> PackedStringArray:
	var errors: PackedStringArray = []
	for condition in conditions:
		var condition_passed = condition.evaluate()
		if not condition_passed:
			errors.append(condition.error_message)
	return errors
