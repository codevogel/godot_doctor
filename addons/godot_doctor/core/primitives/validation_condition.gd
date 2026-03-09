## A class that represents a validation condition.
## It holds a callable that performs the validation,
## and an error message to be used if the validation fails.
## The callable should return either a `bool`, or
## an `Array` of nested `ValidationConditions`.
## Used by GodotDoctor to define validation rules.
class_name ValidationCondition
extends RefCounted

enum Severity { INFO, WARNING, ERROR }

var callable: Callable
var error_message: String
var severity_level: Severity


## Initializes a ValidationCondition with a callable and an error message.
## The callable should return either a `bool`, or
## an `Array` of nested `ValidationConditions`.
## The validation fails if the Callable evaluates to `false`.
## If the validation fails, the error_message will be used as a warning.
func _init(
	callable: Callable, error_message: String, severity_level: Severity = Severity.WARNING
) -> void:
	self.callable = callable
	self.error_message = error_message
	self.severity_level = severity_level


## Evaluates the callable with the provided arguments.
## Returns either a `bool` or an `Array` of nested `ValidationConditions`.
## If the callable does not return a `bool` or an `Array` of `GodotDoctor
## Conditions`, an error will be pushed and `null` will be returned.
func evaluate(args: Array = []) -> Variant:
	var result: Variant = callable.callv(args)
	if typeof(result) == TYPE_BOOL:
		return result
	if typeof(result) == TYPE_ARRAY:
		# Ensure all items in the array are ValidationConditions
		for item in result:
			if typeof(item) != typeof(ValidationCondition):
				#gdlint: disable = max-line-length
				push_error(
					"ValidationCondition Callable returned an array, but not all items are ValidationCondition instances."
				)
				#gd-lint: enable = max-line-length
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
static func simple(
	result: bool, error_message: String, severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return ValidationCondition.new(func(): return result, error_message, severity_level)


## Helper method that creates a ValidationCondition that checks whether a given instance is valid.
## `instance` should be the Object we want to validate.
## `variable_name` is the name of the variable being checked, and is "Instance" by default.
## This is a convenience method for checking instance validity, that generates a default error message.
static func is_instance_valid(
	instance: Object, variable_name: String = "Instance", severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return is_instance_valid(instance),
		"%s is not a valid instance." % variable_name,
		severity_level
	)


## Helper method that creates a ValidationCondition that checks whether a given string is not empty.
## `value` should be the String we want to validate.
## `variable_name` is the name of the variable being checked, and is "String" by default.
## This is a convenience method for checking string emptiness, that generates a default error message.
static func string_not_empty(
	value: String, variable_name: String = "String", severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return not value.is_empty(), "%s is empty." % variable_name, severity_level
	)


## Helper method that creates a ValidationCondition that checks whether a given string,
## after stripping leading and trailing whitespace, is not empty.
## `value` should be the String we want to validate.
## `variable_name` is the name of the variable being checked, and is "String" by default.
## This is a convenience method for checking stripped string emptiness,
## that generates a default error message.
static func stripped_string_not_empty(
	value: String, variable_name: String = "String", severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return string_not_empty(value.strip_edges(), variable_name, severity_level)


## Helper method that creates a ValidationCondition that checks whether a given value is within a specified integer range.
## `value` should be the integer we want to validate.
## `range` should be the `RangeInt` we want to check against.
## `variable_name` is the name of the variable being checked, and is "Value" by default.
## This is a convenience method for checking integer ranges, that generates a default error message.
static func is_in_range_int(
	value: int,
	range: RangeInt,
	variable_name: String = "Value",
	severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return range.contains(value),
		"%s (%d) is out of range (%d to %d)." % [variable_name, value, range.start, range.end],
		severity_level
	)


## Helper method that creates a ValidationCondition that checks whether a given value is within a specified float range.
## `value` should be the float we want to validate.
## `range` should be the `RangeFloat` we want to check against.
## `variable_name` is the name of the variable being checked, and is "Value" by default.
## This is a convenience method for checking float ranges, that generates a default error message.
static func is_in_range_float(
	value: float,
	range: RangeFloat,
	variable_name: String = "Value",
	severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return range.contains(value),
		"%s (%f) is out of range (%f to %f)." % [variable_name, value, range.start, range.end],
		severity_level
	)


## Returns a validation condition that checks whether the `node` has `expected_count` children.
## `node` should be the Node we want to validate.
## `expected_count` should be the number of children we expect the node to have.
## `variable_name` is the name of the variable name used for the `node`, and is "Node" by default.
## This is a convenience method for checking child count, that generates a default error message.
static func has_child_count(
	node: Node,
	expected_count: int,
	variable_name: String = "Node",
	severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return node.get_child_count() == expected_count,
		(
			"%s has %d children, expected %d."
			% [variable_name, node.get_child_count(), expected_count]
		),
		severity_level
	)


## Returns a validation condition that checks whether the `node` has at least `minimum_count` children.
## `node` should be the Node we want to validate.
## `minimum_count` should be the minimum number of children we expect the node to have.
## `variable_name` is the name of the variable name used for the `node`, and is "Node" by default.
## This is a convenience method for checking minimum child count, that generates a default error message.
static func has_minimum_child_count(
	node: Node,
	minimum_count: int,
	variable_name: String = "Node",
	severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return node.get_child_count() >= minimum_count,
		(
			"%s has %d children, expected at least %d."
			% [variable_name, node.get_child_count(), minimum_count]
		),
		severity_level
	)


## Returns a validation condition that checks whether the `node` has at most `maximum_count` children.
## `node` should be the Node we want to validate.
## `maximum_count` should be the maximum number of children we expect the node to have.
## `variable_name` is the name of the variable name used for the `node`, and is "Node" by default.
## This is a convenience method for checking maximum child count, that generates a default error message.
static func has_maximum_child_count(
	node: Node,
	maximum_count: int,
	variable_name: String = "Node",
	severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return node.get_child_count() <= maximum_count,
		(
			"%s has %d children, expected at most %d."
			% [variable_name, node.get_child_count(), maximum_count]
		),
		severity_level
	)


## Returns a validation condition that checks whether the `node` has no children.
## `node` should be the Node we want to validate.
## `variable_name` is the name of the variable name used for the `node`, and is "Node" by default.
## This is a convenience method for checking absence of children, that generates a default error message.
static func has_no_children(
	node: Node, variable_name: String = "Node", severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return has_child_count(node, 0, variable_name, severity_level)


## Returns a validation condition that checks whether the `node` has a child at the specified `path`.
## `node` should be the Node we want to validate.
## `path` should be the NodePath we want to check for existence.
## `variable_name` is the name of the variable name used for the `node`, and is "Node" by default.
## This is a convenience method for checking child existence, that generates a default error message.
static func has_node_path(
	node: Node,
	path: NodePath,
	variable_name: String = "Node",
	severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return node.has_node(path),
		"%s does not have a child at path: %s." % [variable_name, path],
		severity_level
	)


## Returns a validation condition that checks whether the `packed_scene` is of `expected_type`.
## `packed_scene` should be the scene we want to validate.
## `expected_type` should be the type of the script attached to the root node of the `packed_scene`.
## `variable_name` is the name of the variable name used for the `packed_scene`, and is "Packed Scene" by default.
static func scene_is_of_type(
	packed_scene: PackedScene,
	expected_type: Variant,
	variable_name: String = "Packed Scene",
	severity_level: Severity = Severity.ERROR
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
						),
						severity_level
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
							),
							severity_level
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
						),
						severity_level
					)
				]
			return true,
		"",  # No error message needed here, as the condition is always true at this point.
		severity_level
	)


## Helper method that extracts the class name from a PackedScene.
static func _get_class_name_from_packed_scene(packed_scene: PackedScene) -> ClassNameQueryResult:
	var state: SceneState = packed_scene.get_state()

	# Walk up the tree in case this PackedScene inherits from another PackedScene
	while state.get_base_scene_state() != null:
		state = state.get_base_scene_state()

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
