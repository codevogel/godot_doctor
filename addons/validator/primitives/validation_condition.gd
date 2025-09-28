extends RefCounted
class_name ValidationCondition

var callable: Callable
var error_message: String


## Initializes the ValidationCondition with a callable and an error message.
## The callable should return a boolean value indicating whether the condition passes.
## If the callable returns FALSE, the condition has failed.
## The error_message is used to describe the failure when the condition does not pass.
## Example:
## If we want to validate that a node is not null, the callable should look like
## `func() -> bool: return is_instance_valid(node)`
func _init(callable: Callable, error_message: String) -> void:
	self.callable = callable
	self.error_message = error_message


## Evaluates the callable with the provided arguments (if any).
## If this evaluates to FALSE, the condition has failed.
func evaluate(args: Array = []) -> bool:
	var result: Variant = callable.callv(args)
	if typeof(result) != TYPE_BOOL:
		push_error("ValidationCondition callable must return a boolean value.")
		return false
	return result


## Creates a simple ValidationCondition that returns a ValidationCondition with a
## Callable that returns the provided boolean result.
## Useful for bypassing the Callable syntax when a simple true/false condition is needed.
## Example:
## `ValidationCondition.simple(my_int > 0, "my_int must be greater than zero.")`
static func simple(result: bool, error_message: String) -> ValidationCondition:
	return ValidationCondition.new(func(): return result, error_message)
