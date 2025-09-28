@tool
extends EditorPlugin

const VALIDATING_METHOD_NAME := "_get_validation_conditions"
var dock: ValidatorDock


func _enable_plugin() -> void:
	print("[VALIDATOR] Enabling plugin...")
	# Add autoloads here.


func _disable_plugin() -> void:
	print("[VALIDATOR] Disabling plugin...")
	# Remove autoloads here.


func _enter_tree():
	print("[VALIDATOR] Entering tree...")
	scene_saved.connect(_on_scene_saved)
	dock = preload("res://addons/validator/dock/validator_dock.tscn").instantiate() as ValidatorDock
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)


func _exit_tree():
	print("[VALIDATOR] Exiting tree...")
	# Clean-up of the plugin goes here.
	# Remove the dock.
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)
	remove_control_from_docks(dock)
	# Erase the control from the memory.
	dock.free()


func get_all_children_that_are_tree_recursive(node: Node) -> Array:
	var labels: Array = []
	if node is Tree:
		labels.append(node)
	for child in node.get_children():
		labels.append_array(get_all_children_that_are_tree_recursive(child))
	return labels


func _on_scene_saved(file_path: String) -> void:
	print("[VALIDATOR] Scene saved.")
	var current_edited_scene_root: Node = get_editor_interface().get_edited_scene_root()
	if not is_instance_valid(current_edited_scene_root):
		print("[Validator] No current edited scene root. Skipping validation.")
		return

	dock.clear_errors()

	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(current_edited_scene_root)
	print("[Validator] Found %d nodes to validate." % nodes_to_validate.size())

	for node: Node in nodes_to_validate:
		print("[Validator] Calling %s on node: %s" % [VALIDATING_METHOD_NAME, node.name])

		var validation_target: Object = node
		var script: Script = node.get_script()
		var is_tool_script: bool = script and script.is_tool()

		# Check if the script is NOT in tool mode (i.e., it's a placeholder).
		if script and not is_tool_script:
			# If the script is NOT a tool script, the node is a placeholder.
			# We must create a new instance of the script to call its method.
			# This new instance will run in tool mode because it's being created
			# within an `@tool` context
			var new_instance: Node = script.new()

			# Copy properties (like the exported 'my_other_node') from the
			# scene placeholder node to the new validation instance.
			for prop in node.get_property_list():
				if prop.usage & PROPERTY_USAGE_EDITOR:  # Only copy editable properties
					new_instance.set(prop.name, node.get(prop.name))

			# Set the validation target to the new, fully-initialized instance
			validation_target = new_instance

		# Now call the method on the appropriate target (the original node if @tool,
		# or the new instance if non-@tool).
		if validation_target.has_method(VALIDATING_METHOD_NAME):
			# The script is loaded, and method call should now work.
			var generated_conditions = validation_target.call(VALIDATING_METHOD_NAME)
			print("[Validator] Generated validation conditions: %s" % [generated_conditions])
			var validation_result = ValidationResult.new(generated_conditions)
			for error in validation_result.errors:
				print("[Validator] Validation error in node %s: %s" % [node.name, error])
				dock.add_to_dock(
					node, "[b]Configuration warning in %s:[/b]\n%s" % [node.name, error]
				)

		else:
			push_error(
				(
					"Validation target %s does not have method %s."
					% [validation_target.name, VALIDATING_METHOD_NAME]
				)
			)

		# If we created a temporary instance, we should free it.
		if validation_target != node and is_instance_valid(validation_target):
			# If the new instance is a Node, you'd usually want to use queue_free().
			# However, since this is in the editor and not part of the scene tree,
			# simply using free() is faster and appropriate.
			validation_target.free()


func _find_nodes_to_validate_in_tree(node: Node) -> Array:
	var nodes_to_validate: Array = []

	if node.has_method(VALIDATING_METHOD_NAME):
		nodes_to_validate.append(node)

	for child in node.get_children():
		nodes_to_validate.append_array(_find_nodes_to_validate_in_tree(child))
	return nodes_to_validate
