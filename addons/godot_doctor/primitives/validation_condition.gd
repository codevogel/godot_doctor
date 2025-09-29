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


static func scene_is_of_type(
	packed_scene: PackedScene, expected_type: Variant, variable_name: String = "Packed Scene"
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> Variant:
			if packed_scene == null:
				return [ValidationCondition.simple(false, "%s is null." % variable_name)]

			var class_result := _get_class_name_from_packed_scene(packed_scene)
			var expected_name: StringName = expected_type.get_global_name()

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

			var found_name := class_result.found_class_name
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
		""
	)


static func _get_class_name_from_packed_scene(packed_scene: PackedScene) -> ClassNameQueryResult:
	var state := packed_scene.get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"script":
			var script: Script = state.get_node_property_value(0, i)
			return ClassNameQueryResult.new(true, script.get_global_name())
	return ClassNameQueryResult.new(false)


static func _inherits_from(child_class_name: StringName, parent_class_name: StringName) -> bool:
	if ClassDB.class_exists(child_class_name):
		return child_class_name in ClassDB.get_inheriters_from_class(parent_class_name)

	for class_info in ProjectSettings.get_global_class_list():
		if class_info.class == child_class_name:
			return (
				class_info.base == parent_class_name
				or _inherits_from(class_info.base, parent_class_name)
			)

	return false
