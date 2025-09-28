class_name Validation


## Evaluates a list of ValidationConditions and returns a PackedStringArray of error messages for those that fail.
static func evaluate_conditions(conditions: Array[ValidationCondition]) -> PackedStringArray:
	var errors: PackedStringArray = []
	for condition in conditions:
		var result: Variant = condition.evaluate()
		match typeof(result):
			TYPE_BOOL:
				# The result of the evaluation is a boolean, which means the condition has
				# passed when true, and failed when false.
				var condition_passed: bool = result
				if not condition_passed:
					errors.append(condition.error_message)
			TYPE_ARRAY:
				# The result of the evaluation is an array of nested ValidationConditions,
				# which need to be evaluated recursively.
				var nested_conditions: Array[ValidationCondition] = result
				var nested_errors: PackedStringArray = evaluate_conditions(nested_conditions)
				errors.append_array(nested_errors)
			_:
				push_error(
					"An unexpected type was returned during evaluation of a ValidationCondition."
				)
	return errors
