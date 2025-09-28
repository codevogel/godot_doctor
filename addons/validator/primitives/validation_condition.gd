extends RefCounted
class_name ValidationCondition

var callable: Callable
var error_message: String


## Initializes a ValidationCondition with a callable and an error message.
## The callable should return either a `bool`, or
## an `Array` of nested `ValidationConditions`.
## The validation fails if the Callable evaluates to `false`.
## If the validation fails, the error_message will be used as a warning.
func _init(callable: Callable, error_message: String) -> void:
	self.callable = callable
	self.error_message = error_message


## Evaluates the callable with the provided arguments.
## Returns either a `bool` or an `Array` of nested `ValidationConditions`.
## If the callable does not return a `bool` or an `Array` of `Validation
## Conditions`, an error will be pushed and `null` will be returned.
func evaluate(args: Array = []) -> Variant:
	var result: Variant = callable.callv(args)
	if typeof(result) == TYPE_BOOL:
		return result
	if typeof(result) == TYPE_ARRAY:
		# Esnure all items in the array are ValidationConditions
		for item in result:
			ValidationCondition.new
			if typeof(item) != typeof(ValidationCondition):
				push_error(
					"ValidationCondition Callable returned an array, but not all items are ValidationCondition instances."
				)
				return false
		return result
	push_error(
		"ValidationCondition Callable did not return a boolean or an array of ValidationConditions."
	)
	return null


## Helper method that creates a ValidationCondition with a callable that
## simply returns the provided `result` boolean.
## If the result is `false`, the provided error_message will be used.
## This is a convenience method for creating basic validation conditions,
## useful for skipping the callable syntax.
static func simple(result: bool, error_message: String) -> ValidationCondition:
	return ValidationCondition.new(func(): return result, error_message)
