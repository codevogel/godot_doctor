## A class that represents a validation condition.
## It holds a callable that performs the validation,
## and an error message to be used if the validation fails.
## The callable should return either a `bool`, or
## an `Array` of nested `ValidationConditions`.
## Used by GodotDoctor to define validation rules.
class_name ValidationCondition
extends RefCounted

enum Severity {
	## Informational message; does not indicate a problem.
	INFO,
	## A potential issue that does not prevent the project from running.
	WARNING,
	## A critical issue that should be resolved before shipping.
	ERROR
}

var callable: Callable
var error_message: String
var severity_level: Severity


## Initializes a [ValidationCondition] with [param callable] and [param error_message].
## The [param callable] should return either a [code]bool[/code], or
## an [code]Array[/code] of nested [ValidationCondition]s.
## The validation fails if [param callable] evaluates to [code]false[/code].
## If the validation fails, [param error_message] is reported at [param severity_level] severity.
func _init(
	callable: Callable, error_message: String, severity_level: Severity = Severity.WARNING
) -> void:
	self.callable = callable
	self.error_message = error_message
	self.severity_level = severity_level


## Evaluates the callable with [param args] as arguments.
## Returns either a [code]bool[/code] or an [code]Array[/code] of nested [ValidationCondition]s.
## If the callable does not return a [code]bool[/code] or an [code]Array[/code] of
## [ValidationCondition]s, an error will be pushed and [code]null[/code] will be returned.
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


## Creates a [ValidationCondition] that simply returns the provided [param result] boolean.
## If [param result] is [code]false[/code], [param error_message] is reported
## at [param severity_level] severity.
## This is a convenience method for creating basic validation conditions,
## useful for skipping the callable syntax.
static func simple(
	result: bool, error_message: String, severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return ValidationCondition.new(func(): return result, error_message, severity_level)


## Creates a [ValidationCondition] that checks whether [param instance] is a valid [Object].
## [param variable_name] is the display name used in the error message, defaulting to "Instance".
## This is a convenience method for checking instance validity with a default error message.
static func is_instance_valid(
	instance: Object, variable_name: String = "Instance", severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return is_instance_valid(instance),
		"%s is not a valid instance." % variable_name,
		severity_level
	)


## Creates a [ValidationCondition] that checks whether [param value] is not empty.
## [param variable_name] is the display name used in the error message, defaulting to "String".
## This is a convenience method for checking string emptiness with a default error message.
static func string_not_empty(
	value: String, variable_name: String = "String", severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return not value.is_empty(), "%s is empty." % variable_name, severity_level
	)


## Creates a [ValidationCondition] that checks whether [param value], after stripping
## leading and trailing whitespace, is not empty.
## [param variable_name] is the display name used in the error message, defaulting to "String".
## This is a convenience method for checking stripped string emptiness with a default error message.
static func stripped_string_not_empty(
	value: String, variable_name: String = "String", severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return string_not_empty(value.strip_edges(), variable_name, severity_level)


## Creates a [ValidationCondition] that checks whether [param value] falls within [param range].
## [param variable_name] is the display name used in the error message, defaulting to "Value".
## This is a convenience method for range-checking integers with a default error message.
static func is_in_range_int(
	value: int,
	range: GodotDoctorRangeInt,
	variable_name: String = "Value",
	severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return range.contains(value),
		"%s (%d) is out of range (%d to %d)." % [variable_name, value, range.start, range.end],
		severity_level
	)


## Creates a [ValidationCondition] that checks whether [param value] falls within [param range].
## [param variable_name] is the display name used in the error message, defaulting to "Value".
## This is a convenience method for range-checking floats with a default error message.
static func is_in_range_float(
	value: float,
	range: GodotDoctorRangeFloat,
	variable_name: String = "Value",
	severity_level: Severity = Severity.ERROR
) -> ValidationCondition:
	return ValidationCondition.new(
		func() -> bool: return range.contains(value),
		"%s (%f) is out of range (%f to %f)." % [variable_name, value, range.start, range.end],
		severity_level
	)


## Creates a [ValidationCondition] that checks whether [param node] has exactly [param expected_count] children.
## [param variable_name] is the display name used in the error message, defaulting to "Node".
## This is a convenience method for checking child count with a default error message.
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


## Creates a [ValidationCondition] that checks whether [param node] has at least [param minimum_count] children.
## [param variable_name] is the display name used in the error message, defaulting to "Node".
## This is a convenience method for checking minimum child count with a default error message.
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


## Creates a [ValidationCondition] that checks whether [param node] has at most [param maximum_count] children.
## [param variable_name] is the display name used in the error message, defaulting to "Node".
## This is a convenience method for checking maximum child count with a default error message.
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


## Creates a [ValidationCondition] that checks whether [param node] has no children.
## [param variable_name] is the display name used in the error message, defaulting to "Node".
## This is a convenience method for checking absence of children; equivalent to [method has_child_count] with [param expected_count] = 0.
static func has_no_children(
	node: Node, variable_name: String = "Node", severity_level: Severity = Severity.WARNING
) -> ValidationCondition:
	return has_child_count(node, 0, variable_name, severity_level)


## Creates a [ValidationCondition] that checks whether [param node] has a child at [param path].
## [param variable_name] is the display name used in the error message, defaulting to "Node".
## This is a convenience method for checking node path existence with a default error message.
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


## Creates a [ValidationCondition] that checks whether [param packed_scene] has a root node of [param expected_type].
## [param variable_name] is the display name used in the error message, defaulting to "Packed Scene".
## Returns nested [ValidationCondition]s describing any type mismatch in detail.
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
			var class_result: GodotDoctorClassNameQueryResult = _get_class_name_from_packed_scene(
				packed_scene
			)
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


## Extracts the class name from [param packed_scene]'s root node's script.
## Returns a [GodotDoctorClassNameQueryResult] indicating whether a script and class name were found.
static func _get_class_name_from_packed_scene(
	packed_scene: PackedScene
) -> GodotDoctorClassNameQueryResult:
	var state: SceneState = packed_scene.get_state()

	# Walk up the tree in case this PackedScene inherits from another PackedScene
	while state.get_base_scene_state() != null:
		state = state.get_base_scene_state()

	# Look for the script property in the root node (always index 0)
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"script":
			var script: Script = state.get_node_property_value(0, i)
			return GodotDoctorClassNameQueryResult.new(true, script.get_global_name())
	return GodotDoctorClassNameQueryResult.new(false)


## Returns [code]true[/code] if [param child_class_name] inherits from [param parent_class_name],
## either through ClassDB (for built-in classes) or the global class list (for user-defined classes).
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


#region Default Validation Generation


## Generates default validation conditions for [param validation_target] by inspecting its exported properties.
## Creates validation conditions for [Object] properties (checks if they are valid instances), and
## [String] properties (checks if they are non-empty after stripping whitespace).
## [b]NOTE: This is automatically used when the [member GodotDoctorSettings.use_default_validations] setting is enabled,
## you should probably not call this directly, unless you have a very good reason for doing so.[/b]
static func get_default_validation_conditions(
	validation_target: Object
) -> Array[ValidationCondition]:
	GodotDoctorNotifier.print_debug(
		"Generating default validation conditions for: %s" % validation_target
	)
	## Grab all exported properties from the target's script
	var export_props: Array[Dictionary] = _get_export_props(validation_target)
	var validation_conditions: Array[ValidationCondition] = []

	## For each exported property, generate a validation condition based on its type.
	for export_prop in export_props:
		var prop_name: String = export_prop["name"]
		var prop_value: Variant = validation_target.get(prop_name)
		var prop_type: Variant.Type = export_prop["type"]
		# This is where we can add more cases to support additional property types in the future, if need be.
		match prop_type:
			TYPE_OBJECT:
				validation_conditions.append(
					ValidationCondition.is_instance_valid(prop_value, prop_name)
				)
			TYPE_STRING:
				validation_conditions.append(
					ValidationCondition.stripped_string_not_empty(prop_value, prop_name)
				)
			_:
				continue
	return validation_conditions


## Retrieves all exported properties from [param object]'s script.
## Only includes properties that are both script variables and marked for editor visibility.
static func _get_export_props(object: Object) -> Array[Dictionary]:
	GodotDoctorNotifier.print_debug("Getting export properties for object: %s" % object)
	if object == null:
		return []

	var script: Script = object.get_script()
	if script == null:
		return []

	var export_props: Array[Dictionary] = []

	# Iterate through the script's properties and filter for those that are exported and visible in the editor.
	for prop in script.get_script_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if not (prop.usage & PROPERTY_USAGE_EDITOR):
			continue
		export_props.append(prop)

	return export_props

#endregion
