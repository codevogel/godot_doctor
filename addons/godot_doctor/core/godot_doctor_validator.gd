## Handles all validation logic for GodotDoctor.
## Validates scene roots and resources by collecting and evaluating ValidationConditions,
## then reporting results via the active ValidationReporter.
## Settings are accessed via the GodotDoctorPlugin singleton.
class_name GodotDoctorValidator

## The method name that nodes and resources should implement to provide validation conditions.
const VALIDATING_METHOD_NAME: String = "_get_validation_conditions"

var _reporter: ValidationReporter


func _init(reporter: ValidationReporter) -> void:
	_reporter = reporter


# ============================================================================
# PUBLIC API - Validation entry points
# ============================================================================


## Validates all eligible nodes in a scene and reports results via the active reporter.
## [param scene_root] - The root node of the scene to validate.
## In editor mode, the scene must be currently open in the editor.
## In headless mode, any instantiated scene root can be passed directly.
func validate_scene_root(scene_root: Node) -> void:
	GodotDoctorNotifier.print_debug("Validating scene root: %s" % scene_root.name)

	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(scene_root)
	GodotDoctorNotifier.print_debug("Found %d nodes to validate." % nodes_to_validate.size())

	for node: Node in nodes_to_validate:
		var messages: Array[ValidationMessage] = _collect_node_messages(node)
		_reporter.report_node_messages(node, messages)


## Validates a resource and reports results via the active reporter.
## [param resource] - The resource to validate.
func validate_resource(resource: Resource) -> void:
	GodotDoctorNotifier.print_debug(
		"Resource validation requested for resource: %s" % resource.resource_path
	)

	var script: Script = resource.get_script()
	if script in GodotDoctorPlugin.instance.settings.default_validation_ignore_list:
		return

	var messages: Array[ValidationMessage] = _collect_resource_messages(resource)
	_reporter.report_resource_messages(resource, messages)


# ============================================================================
# MESSAGE COLLECTION - Gathering ValidationMessages from nodes and resources
# ============================================================================


## Collects all validation messages for a node by evaluating its conditions.
## Handles both @tool and non-@tool scripts transparently.
func _collect_node_messages(node: Node) -> Array[ValidationMessage]:
	GodotDoctorNotifier.print_debug("Collecting messages for node: %s" % node.name)
	var validation_target: Object = _make_instance_from_placeholder(node)

	var conditions: Array[ValidationCondition] = []

	if GodotDoctorPlugin.instance.settings.use_default_validations:
		conditions.append_array(_get_default_validation_conditions(validation_target))

	if validation_target.has_method(VALIDATING_METHOD_NAME):
		GodotDoctorNotifier.print_debug(
			"Calling %s on %s" % [VALIDATING_METHOD_NAME, validation_target]
		)
		var generated: Array[ValidationCondition] = validation_target.call(VALIDATING_METHOD_NAME)
		GodotDoctorNotifier.print_debug("Generated validation conditions: %s" % [generated])
		conditions.append_array(generated)
	elif not GodotDoctorPlugin.instance.settings.use_default_validations:
		push_error(
			(
				"_collect_node_messages called on %s, but it has no validation method (%s)."
				% [validation_target.name, VALIDATING_METHOD_NAME]
			)
		)

	var messages: Array[ValidationMessage] = ValidationResult.new(conditions).messages

	if validation_target != node and is_instance_valid(validation_target):
		validation_target.free()

	return messages


## Collects all validation messages for a resource by evaluating its conditions.
func _collect_resource_messages(resource: Resource) -> Array[ValidationMessage]:
	GodotDoctorNotifier.print_debug("Collecting messages for resource: %s" % resource.resource_path)
	var conditions: Array[ValidationCondition] = []

	if GodotDoctorPlugin.instance.settings.use_default_validations:
		conditions.append_array(_get_default_validation_conditions(resource))

	if resource.has_method(VALIDATING_METHOD_NAME):
		var generated: Array[ValidationCondition] = resource.call(VALIDATING_METHOD_NAME)
		conditions.append_array(generated)

	return ValidationResult.new(conditions).messages


# ============================================================================
# HELPER METHODS - Node finding and property inspection
# ============================================================================


## Recursively finds all nodes in the scene tree that should be validated.
## Returns nodes that have a script attached.
## Returns all nodes that have a script when default validations are enabled,
## or only nodes that implement the VALIDATING_METHOD_NAME method.
func _find_nodes_to_validate_in_tree(node: Node, recursing: bool = false) -> Array:
	if not recursing:
		GodotDoctorNotifier.print_debug("Finding nodes to validate at root: %s" % node.name)
	var nodes_to_validate: Array = []

	var script: Script = node.get_script()
	if (
		script != null
		and not (script in GodotDoctorPlugin.instance.settings.default_validation_ignore_list)
	):
		if (
			GodotDoctorPlugin.instance.settings.use_default_validations
			or node.has_method(VALIDATING_METHOD_NAME)
		):
			nodes_to_validate.append(node)

	for child in node.get_children():
		nodes_to_validate.append_array(_find_nodes_to_validate_in_tree(child, true))
	return nodes_to_validate


## Generates default validation conditions for an object by inspecting its exported properties.
## Creates validation conditions for:
## - Object properties: checks if they are valid instances.
## - String properties: checks if they are non-empty after stripping whitespace.
func _get_default_validation_conditions(validation_target: Object) -> Array[ValidationCondition]:
	GodotDoctorNotifier.print_debug(
		"Generating default validation conditions for: %s" % validation_target
	)
	var export_props: Array[Dictionary] = _get_export_props(validation_target)
	var validation_conditions: Array[ValidationCondition] = []

	for export_prop in export_props:
		var prop_name: String = export_prop["name"]
		var prop_value: Variant = validation_target.get(prop_name)
		var prop_type: Variant.Type = export_prop["type"]
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


## Retrieves all exported properties from an object's script.
## Only includes properties that are both script variables and marked for editor visibility.
func _get_export_props(object: Object) -> Array[Dictionary]:
	GodotDoctorNotifier.print_debug("Getting export properties for object: %s" % object)
	if object == null:
		return []

	var script: Script = object.get_script()
	if script == null:
		return []

	var export_props: Array[Dictionary] = []

	for prop in script.get_script_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if not (prop.usage & PROPERTY_USAGE_EDITOR):
			continue
		export_props.append(prop)

	return export_props


# ============================================================================
# INSTANCE MANAGEMENT - Creating and copying node properties
# ============================================================================


## Creates a temporary instance of a non-@tool script for validation purposes.
## For non-@tool scripts, creates a new instance and copies properties and children.
## For @tool scripts or nodes without a script, returns the original node unchanged.
func _make_instance_from_placeholder(original_node: Node) -> Object:
	GodotDoctorNotifier.print_debug(
		"Making instance from placeholder for node: %s" % original_node.name
	)
	var script: Script = original_node.get_script()
	var is_tool_script: bool = script and script.is_tool()

	if not (script and not is_tool_script):
		return original_node

	var new_instance: Node = script.new()

	for child in original_node.get_children():
		new_instance.add_child(child.duplicate())

	_copy_properties(original_node, new_instance)
	return new_instance


## Copies all editor-visible properties from one node to another.
## Used to transfer state from the editor node to a temporary validation instance.
func _copy_properties(from_node: Node, to_node: Node) -> void:
	GodotDoctorNotifier.print_debug(
		"Copying properties from %s to placeholder instance" % [from_node.name]
	)
	for prop in from_node.get_property_list():
		if prop.usage & PROPERTY_USAGE_EDITOR:
			to_node.set(prop.name, from_node.get(prop.name))
