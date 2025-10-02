## A class that represents a validation condition.
## It holds a callable that performs the validation,
## and an error message to be used if the validation fails.
## The callable should return either a `bool`, or
## an `Array` of nested `ValidationConditions`.
## Used by GodotDoctor to define validation rules.
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
## If the callable does not return a `bool` or an `Array` of `GodotDoctor
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
		return result as Array[ValidationCondition]
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


## Returns a validation condition that checks whether the `packed_scene` is of `expected_type`.
## `packed_scene` should be the scene we want to validate.
## `expected_type` should be the type of the script attached to the root node of the `packed_scene`.
## `variable_name` is the name of the variable name used for the `packed_scene`, and is "Packed Scene" by default.
static func scene_is_of_type(
	packed_scene: PackedScene, expected_type: Variant, variable_name: String = "Packed Scene"
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> Variant:
			# If the expected type isn't assigned, return a nested condition indicating failure.
			if packed_scene == null:
				return [ValidationCondition.simple(false, "%s is null." % variable_name)]

			# Get the class name, and convert the expected type to a StringName
			var class_result: ClassNameQueryResult = _get_class_name_from_packed_scene(packed_scene)
			var expected_name: StringName = expected_type.get_global_name()

			# If there's no script, return a nested condition indicating failure.
			if not class_result.has_script:
				return [
					ValidationCondition.simple(
						false,
						(
							"%s has no script attached. (Expecting: %s)"
							% [variable_name, expected_name]
						)
					)
				]

			# If the script has no class_name, return a nested condition indicating failure.
			if not class_result.has_class_name:
				return [
					(
						ValidationCondition
						. simple(
							false,
							(
								"%s has a script attached, but it bears no 'class_name'. (Expecting: %s)"
								% [variable_name, expected_name]
							)
						)
					)
				]

			# If the found class name doesn't match the expected name, or
			# doesn't inherit from it, return a nested condition indicating failure.
			var found_name: StringName = class_result.found_class_name
			if found_name != expected_name and not _inherits_from(found_name, expected_name):
				return [
					ValidationCondition.simple(
						false,
						(
							"%s script type (%s) is a mismatch. (Expecting: %s)"
							% [variable_name, found_name, expected_name]
						)
					)
				]
			return true,
		"" # No error message needed here, as the condition is always true at this point.
	)

## Helper method that extracts the class name from a PackedScene.
static func _get_class_name_from_packed_scene(packed_scene: PackedScene) -> ClassNameQueryResult:
	var state: SceneState = packed_scene.get_state()
	# Look for the script property in the root node (always index 0)
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"script":
			var script: Script = state.get_node_property_value(0, i)
			return ClassNameQueryResult.new(true, script.get_global_name())
	return ClassNameQueryResult.new(false)

## Helper method that checks if a class (by name) inherits from another class (by name).
static func _inherits_from(child_class_name: StringName, parent_class_name: StringName) -> bool:
	# If found in ClassDB, it's an internal class.
	if ClassDB.class_exists(child_class_name):
		return child_class_name in ClassDB.get_inheriters_from_class(parent_class_name)

	# Otherwise, check in the global class list.
	for class_info in ProjectSettings.get_global_class_list():
		# Check for match
		if class_info.class == child_class_name:
			return (
				class_info.base == parent_class_name
				or _inherits_from(class_info.base, parent_class_name)
			)
	# If not found, return false.
	return false
