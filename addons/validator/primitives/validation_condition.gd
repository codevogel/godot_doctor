extends RefCounted
class_name ValidationCondition

var callable: Callable
var error_message: String


## Initializes the ValidationCondition with a callable and an error message.
## The callable should return a boolean value indicating whether the condition passes.
## The error_message is presented if the condition fails.
func _init(callable: Callable, error_message: String) -> void:
	self.callable = callable
	self.error_message = error_message


## Evaluates the callable with the provided arguments (if any).
func evaluate(args: Array = []) -> bool:
	var result: Variant = callable.callv(args)
	if typeof(result) != TYPE_BOOL:
		push_error("ValidationCondition callable must return a boolean value.")
		return false
	return result


## Creates a simple ValidationCondition that returns a ValidationCondition with a
## Callable that returns the provided boolean result.
## Useful for bypassing the Callable syntax when a simple true/false condition is needed.
static func simple(result: bool, error_message: String) -> ValidationCondition:
	return ValidationCondition.new(func(): return result, error_message)
