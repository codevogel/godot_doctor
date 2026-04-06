## Handles all validation logic for Godot Doctor.
## Validates scene roots and resources by collecting and evaluating [ValidationCondition]s,
## then emitting results for the active [GodotDoctorValidationCollector] to capture.
## Settings are accessed via the [GodotDoctorPlugin] singleton.
class_name GodotDoctorValidator

## Emitted when [param node] has been validated with the resulting [param messages].
signal validated_node(node: Node, messages: Array[GodotDoctorValidationMessage])
## Emitted when [param resource] has been validated with the resulting [param messages].
signal validated_resource(resource: Resource, messages: Array[GodotDoctorValidationMessage])

## The name of the method that nodes and resources should implement to supply validation conditions.
const VALIDATING_METHOD_NAME_GDSCRIPT: String = "_get_validation_conditions"
const VALIDATING_METHOD_NAME_CSHARP: String = "GetValidationConditions"

#region PUBLIC API - Entry points for validating scenes and resources


## Validates all eligible nodes in [param scene_root] and reports results via the active reporter.
## In editor mode, the scene must be currently open in the editor.
## In headless mode, any instantiated scene root can be passed directly.
func validate_scene_root(scene_root: Node) -> void:
	GodotDoctorNotifier.print_debug("Validating scene root: %s" % scene_root.name, self)

	# Grab all nodes that should be validated in the scene tree
	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(scene_root)
	GodotDoctorNotifier.print_debug("Found %d nodes to validate." % nodes_to_validate.size(), self)

	# Validate each node and report results
	for node: Node in nodes_to_validate:
		var messages: Array[GodotDoctorValidationMessage] = _collect_node_messages(node)
		validated_node.emit(node, messages)


## Validates [param resource] and reports results via the active reporter.
func validate_resource(resource: Resource) -> void:
	GodotDoctorNotifier.print_debug(
		"Resource validation requested for resource: %s" % resource.resource_path, self
	)

	# Check if the resource's script is in the ignore list before validating
	var script: Script = resource.get_script()
	if script in GodotDoctorPlugin.instance.settings.default_validation_ignore_list:
		return

	# Validate the resource and report results
	var messages: Array[GodotDoctorValidationMessage] = _collect_resource_messages(resource)
	validated_resource.emit(resource, messages)


#endregion

#region Message Collection - Evaluating validation conditions and generating messages


## Collects all validation messages for [param node] by evaluating its conditions.
## Handles both @tool and non-@tool scripts transparently.
func _collect_node_messages(node: Node) -> Array[GodotDoctorValidationMessage]:
	GodotDoctorNotifier.print_debug("Collecting messages for node: %s" % node.name, self)

	# The target is either the original node (for @tool scripts)
	# or a temporary instance (for non-@tool scripts).
	var validation_target: Object = _make_instance_from_potential_placeholder_node(node)

	# Declare an array to hold all validation conditions that will be evaluated for this node.
	var conditions: Array[ValidationCondition] = []

	# If default validations are enabled, generate conditions based on exported properties.
	if GodotDoctorPlugin.instance.settings.use_default_validations:
		conditions.append_array(
			ValidationCondition.get_default_validation_conditions(validation_target)
		)

	var validating_method_name: String = _get_validating_method_name(validation_target)

	# If the node implements the validating method, call it and append its conditions.
	if validation_target.has_method(validating_method_name):
		GodotDoctorNotifier.print_debug(
			"Calling %s on %s" % [validating_method_name, validation_target], self
		)
		# We expect the method to return an array of ValidationCondition objects.
		var generated_conditions: Array[ValidationCondition] = []
		var generated: Array = validation_target.call(validating_method_name)
		generated_conditions.assign(generated)
		GodotDoctorNotifier.print_debug("Generated validation conditions: %s" % [generated], self)
		# Append the generated conditions to the list of conditions to evaluate.
		conditions.append_array(generated)
	elif not GodotDoctorPlugin.instance.settings.use_default_validations:
		# This shouldn't happen since we only collect nodes that have the method
		# in _find_nodes_to_validate_in_tree: Nodes that don't have the method
		# should be filtered out when use_default_validations is disabled.
		# Report this just in case of mis-use or unexpected edge cases.
		push_error(
			(
				"_collect_node_messages called on %s, but it has no validation method (%s)."
				% [validation_target.name, validating_method_name]
			)
		)
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()

	# Actual evaluation takes place in the creation of the GodotDoctorValidationResult.
	# We collect the resulting messages here to report back to the user.
	var messages: Array[GodotDoctorValidationMessage] = (
		GodotDoctorValidationResult.new(conditions).messages
	)

	# Free the temporary instance if we created one for validation.
	if validation_target != node and is_instance_valid(validation_target):
		validation_target.free()

	return messages


## Collects all validation messages for [param resource] by evaluating its conditions.
func _collect_resource_messages(resource: Resource) -> Array[GodotDoctorValidationMessage]:
	GodotDoctorNotifier.print_debug(
		"Collecting messages for resource: %s" % resource.resource_path, self
	)
	var conditions: Array[ValidationCondition] = []

	# If default validations are enabled, generate conditions based on exported properties.
	if GodotDoctorPlugin.instance.settings.use_default_validations:
		conditions.append_array(ValidationCondition.get_default_validation_conditions(resource))

	var validating_method_name: String = _get_validating_method_name(resource)
	# If the resource implements the validating method, call it and append its conditions.
	if resource.has_method(validating_method_name):
		var generated_conditions: Array[ValidationCondition] = []
		var generated: Array = resource.call(validating_method_name)
		generated_conditions.assign(generated)
		conditions.append_array(generated)

	# Actual evaluation takes place in the creation of the GodotDoctorValidationResult,
	# we collect the resulting messages here to report back to the user.
	return GodotDoctorValidationResult.new(conditions).messages


#endregion

#region Helper Methods


func _get_validating_method_name(target: Object) -> String:
	if target.has_method(VALIDATING_METHOD_NAME_GDSCRIPT):
		return VALIDATING_METHOD_NAME_GDSCRIPT
	if target.has_method(VALIDATING_METHOD_NAME_CSHARP):
		return VALIDATING_METHOD_NAME_CSHARP
	return ""


## Recursively finds all nodes in [param node]'s subtree that should be validated.
## Returns all nodes with a script when default validations are enabled,
## or only nodes that implement [constant VALIDATING_METHOD_NAME_GDSCRIPT].
func _find_nodes_to_validate_in_tree(node: Node, recursing: bool = false) -> Array:
	if not recursing:
		GodotDoctorNotifier.print_debug("Finding nodes to validate at root: %s" % node.name, self)
	var nodes_to_validate: Array = []

	var script: Script = node.get_script()
	if (
		script != null
		and not (script in GodotDoctorPlugin.instance.settings.default_validation_ignore_list)
	):
		if (
			GodotDoctorPlugin.instance.settings.use_default_validations
			or not _get_validating_method_name(node).is_empty()
		):  # ← replaces the has_method check
			nodes_to_validate.append(node)

	for child in node.get_children():
		nodes_to_validate.append_array(_find_nodes_to_validate_in_tree(child, true))
	return nodes_to_validate


#region Placeholder Instance Creation


## Creates a temporary instance of [param original_node]'s script for validation purposes.
## For non-@tool scripts, creates a new instance and copies properties and children.
## For @tool scripts or nodes without a script, returns [param original_node] unchanged.
func _make_instance_from_potential_placeholder_node(original_node: Node) -> Object:
	GodotDoctorNotifier.print_debug(
		"Making instance from placeholder for node: %s" % original_node.name, self
	)
	var script: Script = original_node.get_script()
	var is_tool_script: bool = script and script.is_tool()

	if not (script and not is_tool_script):
		return original_node

	var new_instance: Node = script.new()
	new_instance.name = original_node.name

	for child in original_node.get_children():
		new_instance.add_child(child.duplicate())

	_copy_properties(original_node, new_instance)
	return new_instance


## Copies all editor-visible properties from [param from_node] to [param to_node].
## Used to transfer state from an editor node to a temporary validation instance.
func _copy_properties(from_node: Node, to_node: Node) -> void:
	GodotDoctorNotifier.print_debug(
		"Copying properties from %s to placeholder instance" % [from_node.name], self
	)
	for prop in from_node.get_property_list():
		if prop.usage & PROPERTY_USAGE_EDITOR:
			to_node.set(prop.name, from_node.get(prop.name))


#endregion


#region Condition Evaluation
## Evaluates [param conditions] and returns an array of [GodotDoctorValidationMessage]
## for all conditions that fail.
## This is called during the creation of a [GodotDoctorValidationResult]
static func evaluate_conditions(
	conditions: Array[ValidationCondition]
) -> Array[GodotDoctorValidationMessage]:
	var errors: Array[GodotDoctorValidationMessage] = []
	for condition in conditions:
		var result: Variant = condition.evaluate()
		match typeof(result):
			TYPE_BOOL:
				# The result of the evaluation is a boolean, which means the condition has
				# passed when true, and failed when false.
				var condition_passed: bool = result
				if not condition_passed:
					errors.append(
						GodotDoctorValidationMessage.new(
							condition.error_message, condition.severity_level
						)
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
						GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
						continue
					nested_conditions.append(expected_condition as ValidationCondition)

				var nested_errors: Array[GodotDoctorValidationMessage] = evaluate_conditions(
					nested_conditions
				)
				errors.append_array(nested_errors)
			_:
				push_error(
					"An unexpected type was returned during evaluation of a ValidationCondition."
				)
				GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
	return errors
#endregion
