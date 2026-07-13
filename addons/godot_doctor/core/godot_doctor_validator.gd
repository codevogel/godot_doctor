## Handles all validation logic for Godot Doctor.
## Validates scene roots and resources by collecting and evaluating [ValidationCondition]s,
## then emitting results for the active [GodotDoctorValidationCollector] to capture.
## Settings are accessed via the [GodotDoctorPlugin] singleton.
class_name GodotDoctorValidator

## Emitted when [param node] has been validated with the resulting [param messages].
signal validated_node(node: Node, messages: Array[GodotDoctorValidationMessage])
## Emitted when [param resource] has been validated with the resulting [param messages].
signal validated_resource(resource: Resource, messages: Array[GodotDoctorValidationMessage])

## Traversal State Keys used to track recursion (caused by cyclic references)
enum TraversalStateKey {
	ACTIVE_NODE_IDS,
	WARNED_NODE_IDS,
	VALIDATION_ROOT_NAME,
	CYLIC_WARNING_MESSAGES,
}

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

	# Validate the resource and report results
	var messages: Array[GodotDoctorValidationMessage] = _collect_resource_messages(resource)
	validated_resource.emit(resource, messages)


#endregion

#region Message Collection - Evaluating validation conditions and generating messages


## Collects all validation messages for [param node] by evaluating its conditions.
## Handles both @tool and non-@tool scripts transparently.
func _collect_node_messages(node: Node) -> Array[GodotDoctorValidationMessage]:
	GodotDoctorNotifier.print_debug("Collecting messages for node: %s" % node.name, self)

	# Tracks all Node instances created during placeholder conversion so they can
	# be freed after validation. Passed through the conversion chain by reference.
	var extra_to_free: Array[Node] = []
	# Tracks recursion state while converting exported node references so
	# cyclic dependencies do not cause stack overflows.
	var traversal_state: Dictionary[int, Variant] = {
		TraversalStateKey.ACTIVE_NODE_IDS: {},
		TraversalStateKey.WARNED_NODE_IDS: {},
		TraversalStateKey.VALIDATION_ROOT_NAME: node.name,
		TraversalStateKey.CYLIC_WARNING_MESSAGES: [],
	}

	# The target is either the original node (for @tool scripts)
	# or a temporary instance (for non-@tool scripts).
	var validation_target: Object = _make_instance_from_potential_placeholder_node(
		node, extra_to_free, traversal_state
	)

	# Declare an array to hold all validation conditions that will be evaluated for this node.
	var conditions: Array[ValidationCondition] = []

	var script: Script = node.get_script()
	if script == null:
		# This shouldn't happen since we only collect nodes with scripts
		# in _find_nodes_to_validate_in_tree
		GodotDoctorNotifier.print_debug(
			"No script found on node %s, skipping message collection." % node.name, self
		)
		return []

	# If default validations are enabled, generate conditions based on exported properties.
	if (
		GodotDoctorPlugin.instance.settings.use_default_validations
		and script not in GodotDoctorPlugin.instance.settings.default_validation_ignore_list
	):
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
	# Collect any cyclic warning messages that were generated
	# and append them to the final messages array.
	var cyclic_warning_messages: Array[GodotDoctorValidationMessage] = []
	cyclic_warning_messages.assign(
		traversal_state.get(TraversalStateKey.CYLIC_WARNING_MESSAGES, [])
	)
	messages.append_array(cyclic_warning_messages)

	# Free the temporary instance if we created one for validation.
	if validation_target != node and is_instance_valid(validation_target):
		validation_target.free()

	# Free any additional Node instances created during property conversion
	# (e.g. placeholder nodes referenced in exported Array properties).
	for instance: Node in extra_to_free:
		if is_instance_valid(instance):
			instance.free()

	return messages


## Collects all validation messages for [param resource] by evaluating its conditions.
func _collect_resource_messages(resource: Resource) -> Array[GodotDoctorValidationMessage]:
	GodotDoctorNotifier.print_debug(
		"Collecting messages for resource: %s" % resource.resource_path, self
	)
	var conditions: Array[ValidationCondition] = []

	var script: Script = resource.get_script()
	if script == null:
		GodotDoctorNotifier.print_debug(
			"No script found on resource %s, skipping message collection." % resource.resource_path,
			self
		)
		return []

	# If default validations are enabled, generate conditions based on exported properties.
	if (
		GodotDoctorPlugin.instance.settings.use_default_validations
		and script not in GodotDoctorPlugin.instance.settings.default_validation_ignore_list
	):
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
	if script != null:
		if (
			GodotDoctorPlugin.instance.settings.use_default_validations
			or not _get_validating_method_name(node).is_empty()
		):
			nodes_to_validate.append(node)

	for child in node.get_children():
		nodes_to_validate.append_array(_find_nodes_to_validate_in_tree(child, true))
	return nodes_to_validate


#region Placeholder Instance Creation


## Creates a temporary instance of [param original_node]'s script for validation purposes.
## For non-@tool scripts, creates a new instance and copies properties and children.
## For @tool scripts or nodes without a script, returns [param original_node] unchanged.
## [param extra_to_free] collects any Node instances created during property conversion
## so the caller can free them after validation.
func _make_instance_from_potential_placeholder_node(
	original_node: Node,
	extra_to_free: Array[Node] = [],
	traversal_state: Dictionary[int, Variant] = {}
) -> Object:
	GodotDoctorNotifier.print_debug(
		"Making instance from placeholder for node: %s" % original_node.name, self
	)
	var script: Script = original_node.get_script()
	var is_tool_script: bool = script and script.is_tool()

	if not (script and not is_tool_script):
		return original_node

	# Grab the active node IDs from the traversal state to detect cyclic references.
	var active_node_ids: Dictionary = traversal_state.get(TraversalStateKey.ACTIVE_NODE_IDS, {})
	var node_id: int = original_node.get_instance_id()
	# If this node is already in the active set, we have a cyclic reference.
	if active_node_ids.has(node_id):
		_warn_about_cyclic_node_reference(original_node, traversal_state)
		# We don't make a new instance here, as we would end up in an infinite loop,
		# as we would enter a reference cycle.
		# Instead, we return the original node, which will be used in the property copy.
		return original_node

	# Mark this node as active
	active_node_ids[node_id] = true
	traversal_state[TraversalStateKey.ACTIVE_NODE_IDS] = active_node_ids

	# Create the new instance.
	var new_instance: Node = script.new()
	new_instance.name = original_node.name

	for child in original_node.get_children():
		new_instance.add_child(child.duplicate())

	# Copy the properties over.
	_copy_properties(original_node, new_instance, extra_to_free, traversal_state)
	active_node_ids.erase(node_id)
	return new_instance


## Copies all editor-visible properties from [param from_node] to [param to_node].
## Used to transfer state from an editor node to a temporary validation instance.
## Recursively converts placeholder node instances in properties to proper instances.
## [param extra_to_free] collects any Node instances created during conversion.
func _copy_properties(
	from_node: Node,
	to_node: Node,
	extra_to_free: Array[Node] = [],
	traversal_state: Dictionary[int, Variant] = {}
) -> void:
	GodotDoctorNotifier.print_debug(
		"Copying properties from %s to placeholder instance" % [from_node.name], self
	)
	for prop in from_node.get_property_list():
		if prop.usage & PROPERTY_USAGE_EDITOR:
			var prop_name: StringName = prop.name
			var value: Variant = from_node.get(prop_name)
			var converted_value: Variant = _convert_placeholder_references(
				value, extra_to_free, traversal_state
			)

			if from_node is Control and prop_name == "size":
				to_node.set_deferred(prop_name, converted_value)
			else:
				to_node.set(prop_name, converted_value)


## Recursively converts placeholder node references to proper instances.
## Handles individual nodes, arrays, and other types transparently.
## [param extra_to_free] collects any Node instances created here so the
## caller can free them after validation.
func _convert_placeholder_references(
	value: Variant, extra_to_free: Array[Node] = [], traversal_state: Dictionary[int, Variant] = {}
) -> Variant:
	match typeof(value):
		TYPE_OBJECT:
			if value is Node:
				var node_value: Node = value
				var converted: Object = _make_instance_from_potential_placeholder_node(
					node_value, extra_to_free, traversal_state
				)
				# If a new instance was created, track it for cleanup.
				if converted != node_value and converted is Node:
					extra_to_free.append(converted as Node)
				return converted
			return value
		TYPE_ARRAY:
			# Recursively process array elements while preserving typed-array metadata.
			var source_array: Array = value
			var converted_array: Array = source_array.duplicate()
			for i in source_array.size():
				converted_array[i] = _convert_placeholder_references(
					source_array[i], extra_to_free, traversal_state
				)
			return converted_array
		_:
			# For all other types, return as-is
			return value


func _warn_about_cyclic_node_reference(
	node: Node, traversal_state: Dictionary[int, Variant]
) -> void:
	var warned_node_ids: Dictionary = traversal_state.get(TraversalStateKey.WARNED_NODE_IDS, {})
	# Get the unique instance ID of this node.
	var node_id: int = node.get_instance_id()
	if warned_node_ids.has(node_id):
		# Ignore if we already warned this node
		return

	var validation_root_name: String = traversal_state.get(
		TraversalStateKey.VALIDATION_ROOT_NAME, "<unknown>"
	)
	var warning_message: String = (
		(
			"Cyclic exported node reference detected at '%s' while validating '%s'. "
			+ "Skipping recursive placeholder conversion to prevent stack overflow."
		)
		% [node.name, validation_root_name]
	)
	GodotDoctorNotifier.print_debug(warning_message, self)

	warned_node_ids[node_id] = true
	traversal_state[TraversalStateKey.WARNED_NODE_IDS] = warned_node_ids
	var runtime_messages: Array[GodotDoctorValidationMessage] = []
	runtime_messages.assign(traversal_state.get(TraversalStateKey.CYLIC_WARNING_MESSAGES, []))
	runtime_messages.append(
		GodotDoctorValidationMessage.new(warning_message, ValidationCondition.Severity.WARNING)
	)
	traversal_state[TraversalStateKey.CYLIC_WARNING_MESSAGES] = runtime_messages


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
