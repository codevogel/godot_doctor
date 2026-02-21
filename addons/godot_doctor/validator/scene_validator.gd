class_name SceneValidator extends RefCounted

## The method name that nodes and resources should implement to provide validation conditions.
const VALIDATING_METHOD_NAME: String = "_get_validation_conditions"

## The path of the settings resource used to configure the plugin.
const VALIDATOR_SETTINGS_PATH: String = "res://addons/godot_doctor/settings/godot_doctor_settings.tres"

## A Resource that holds the settings for the Godot Doctor plugin.
var settings: GodotDoctorSettings:
	get:
		# This may be used before @onready
		# so we lazy load it here if needed.
		if not settings:
			settings = load(VALIDATOR_SETTINGS_PATH) as GodotDoctorSettings
		return settings

var _output : ValidatorOutputInterface

func _init(output_interface : ValidatorOutputInterface) -> void : 
	_output = output_interface

# ============================================================================
# CORE VALIDATION - Main validation entry points for nodes and resources
# ============================================================================


## Validates a resource by collecting default validation conditions (if enabled)
## and any custom validation conditions defined in the resource.
## Processes the validation conditions and reports any errors to the dock.
func _validate_resource(resource: Resource):
	var validation_conditions: Array[ValidationCondition] = []
	if settings.use_default_validations:
		validation_conditions.append_array(_get_default_validation_conditions(resource))
	if resource.has_method(VALIDATING_METHOD_NAME):
		var generated_conditions: Array[ValidationCondition] = resource.call(VALIDATING_METHOD_NAME)
		validation_conditions.append_array(generated_conditions)
	_validate_resource_validation_conditions(resource, validation_conditions)


## Validates a single node by collecting default validation conditions (if enabled),
## custom validation conditions defined in the node (handling both @tool and non-@tool scripts),
## and processing the results.
## For non-@tool scripts, creates a temporary instance to call validation methods on.
func _validate_node(node: Node) -> void:
	_output._print_debug("Validating node: %s" % node.name)
	var validation_target: Object = node

	# Depending on whether the validation target is marked as @tool or not,
	# we may need to create a new instance of the script to call the method on.
	validation_target = _make_instance_from_placeholder(node)

	var validation_conditions: Array[ValidationCondition] = []

	if settings.use_default_validations:
		validation_conditions.append_array(_get_default_validation_conditions(validation_target))

	# Now call the method on the appropriate target (the original node if @tool,
	# or the new instance if non-@tool).
	if validation_target.has_method(VALIDATING_METHOD_NAME):
		_output._print_debug("Calling %s on %s" % [VALIDATING_METHOD_NAME, validation_target])
		var generated_conditions = validation_target.call(VALIDATING_METHOD_NAME)
		_output._print_debug("Generated validation conditions: %s" % [generated_conditions])
		validation_conditions.append_array(generated_conditions)
	elif not settings.use_default_validations:
		# This should never happen, since we filtered for nodes that have no validation method
		# when use_default_validations is false, but do this just in case
		push_error(
			(
				"_validate_node called on %s, but it didn't have the validation method (%s)."
				% [validation_target.name, VALIDATING_METHOD_NAME]
			)
		)

	_validate_node_validation_conditions(node, validation_conditions)

	# If we created a temporary instance, we should free it.
	if validation_target != node and is_instance_valid(validation_target):
		validation_target.free()


# ============================================================================
# VALIDATION CONDITION PROCESSING - Processing and reporting validation results
# ============================================================================


## Processes validation conditions for a resource.
## Evaluates all conditions, formats errors, displays toasts, and adds warnings to the dock.
func _validate_resource_validation_conditions(
	resource: Resource, validation_conditions: Array[ValidationCondition]
) -> void:
	var validation_result: ValidationResult = ValidationResult.new(validation_conditions)
	var validation_messages: Array[ValidationMessage] = validation_result.errors
	if validation_messages.size() > 0:
		var severity_level = (
			validation_messages
			. map(func(msg: ValidationMessage) -> int: return msg.severity_level)
			. max()
		)

		_output._push_toast(
			(
				"Found %s configuration warning(s) in %s."
				% [validation_result.errors.size(), resource.resource_path]
			),
			severity_level
		)
	for msg in validation_messages:
		var name: String = resource.resource_path.split("/")[-1]
		_output._print_debug(
			(
				"Found message with severity %s in node %s: %s"
				% [msg.severity_level, resource, msg.message]
			)
		)
		_output._print_debug("Adding message to dock...")
		# Push the warning to the dock, passing the original resource so the user can locate it.
		_output.add_resource_warning_to_dock(resource, msg)


## Processes validation conditions for a node.
## Evaluates all conditions, formats errors, displays toasts, and adds warnings to the dock.
func _validate_node_validation_conditions(
	node: Node, validation_conditions: Array[ValidationCondition]
) -> void:
	var validation_messages: Array[ValidationMessage] = []
	# ValidationResult processes the conditions upon instantiation.
	var validation_result = ValidationResult.new(validation_conditions)
	validation_messages.append_array(validation_result.errors)
	# Process the resulting errors
	if validation_messages.size() > 0:
		var severity_level = (
			validation_messages
			. map(func(msg: ValidationMessage) -> int: return msg.severity_level)
			. max()
		)

		_output._push_toast(
			(
				"Found %s configuration warning(s) in %s."
				% [validation_result.errors.size(), node.name]
			),
			severity_level
		)
	for msg in validation_messages:
		_output._print_debug(
			(
				"Found message with severity %s in node %s: %s"
				% [msg.severity_level, node.name, msg.message]
			)
		)
		_output._print_debug("Adding message to dock...")
		# Push the warning to the dock, passing the original node so the user can locate it.
		_output.add_node_warning_to_dock(node, msg)


# ============================================================================
# HELPER METHODS - Node finding and property inspection
# ============================================================================


## Recursively finds all nodes in the scene tree that should be validated.
## Returns nodes that have a script attached.
## Returns all nodes that have script when default validations are enabled
## or returns nodes that implement the VALIDATING_METHOD_NAME method.
func _find_nodes_to_validate_in_tree(node: Node) -> Array:
	var nodes_to_validate: Array = []

	# Only add nodes that have a script attached
	var script: Script = node.get_script()
	if script != null and not (script in settings.default_validation_ignore_list):
		# Add all nodes if use_default_validations is true,
		# or add only the nodes that have the method if it is false
		if settings.use_default_validations or node.has_method(VALIDATING_METHOD_NAME):
			nodes_to_validate.append(node)

	# Add their children too, if any
	var children: Array[Node] = node.get_children()
	for child in children:
		nodes_to_validate.append_array(_find_nodes_to_validate_in_tree(child))
	return nodes_to_validate


## Generates default validation conditions for an object by inspecting its exported properties.
## Creates validation conditions for:
## - Object properties: checks if they are valid instances
## - String properties: checks if they are non-empty after stripping whitespace
## Returns an array of generated ValidationCondition objects.
func _get_default_validation_conditions(validation_target: Object) -> Array[ValidationCondition]:
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
## Returns an array of property dictionaries containing metadata for each exported variable.
## Only includes properties that are both script variables and marked for editor visibility.
## Returns an empty array if the object is null, or has no script and isn't a resource.
func _get_export_props(object: Object) -> Array[Dictionary]:
	if object == null:
		return []

	var script: Script = object.get_script()
	if script == null:
		return []

	var export_props: Array[Dictionary] = []

	for prop in script.get_script_property_list():
		# Only include actual script variables
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue

		# Only include exported variables
		if not (prop.usage & PROPERTY_USAGE_EDITOR):
			continue

		export_props.append(prop)

	return export_props


# ============================================================================
# INSTANCE MANAGEMENT - Creating and copying node properties
# ============================================================================


## Creates a temporary instance of a non-@tool script for validation purposes.
## For non-@tool scripts, creates a new instance and copies properties and children.
## For @tool scripts or scripts with no script, returns the original node.
## This allows validation of non-@tool scripts without executing gameplay code in the editor.
func _make_instance_from_placeholder(original_node: Node) -> Object:
	var script: Script = original_node.get_script()
	var is_tool_script: bool = script and script.is_tool()

	if not (script and not is_tool_script):
		# If there's no script, or if it's a @tool script, return the original node.
		# (The non-placeholder instance doesn't matter, since we won't be validating it anyway,
		# or already exists, because it is a @tool script.)
		return original_node

	# Create a new instance of the script
	var new_instance: Node = script.new()

	# Duplicate the children from the original node to the new instance
	for child in original_node.get_children():
		new_instance.add_child(child.duplicate())

	_copy_properties(original_node, new_instance)
	return new_instance


## Copies all editor-visible properties from one node to another.
## This is used to transfer state from the editor node to a temporary validation instance.
func _copy_properties(from_node: Node, to_node: Node) -> void:
	for prop in from_node.get_property_list():
		if prop.usage & PROPERTY_USAGE_EDITOR:
			to_node.set(prop.name, from_node.get(prop.name))
