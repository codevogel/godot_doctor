## A utility class for evaluating validation conditions and collecting error messages.
## This class provides a static method to evaluate a list of ValidationCondition instances
## Used by Godot Doctor to check for various conditions in a Godot project.
class_name GodotDoctor


## Evaluates a list of ValidationConditions
## and returns a PackedStringArray of error messages for those that fail.
static func evaluate_conditions(conditions: Array[ValidationCondition]) -> Array[ValidationMessage]:
	var errors: Array[ValidationMessage] = []
	for condition in conditions:
		var result: Variant = condition.evaluate()
		match typeof(result):
			TYPE_BOOL:
				# The result of the evaluation is a boolean, which means the condition has
				# passed when true, and failed when false.
				var condition_passed: bool = result
				if not condition_passed:
					errors.append(
						ValidationMessage.new(condition.error_message, condition.severity_level)
					)
			TYPE_ARRAY:
				# The result of the evaluation is an array of nested ValidationConditions,
				# which need to be evaluated recursively.
				# Since it is returned as a Variant,
				# we first need to ensure that it is indeed an Array[ValidationCondition]
				var nested_conditions: Array[ValidationCondition] = []
				for expected_condition in result:
					if expected_condition is not ValidationCondition:
						push_error(
							"Nested ValidationCondition array contained a different type than ValidationCondition"
						)
					nested_conditions.append(expected_condition as ValidationCondition)

				var nested_errors: Array[ValidationMessage] = evaluate_conditions(nested_conditions)
				errors.append_array(nested_errors)
			_:
				push_error(
					"An unexpected type was returned during evaluation of a ValidationCondition."
				)
	return errors


## Compares two floating-point numbers for
## approximate equality within a specified epsilon tolerance.
static func is_equal_approx(a: float, b: float, epsilon: float = 0.0001) -> bool:
	return abs(a - b) <= epsilon
