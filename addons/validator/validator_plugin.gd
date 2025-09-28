@tool
extends EditorPlugin

const VALIDATING_METHOD_NAME: String = "_get_validation_conditions"
const VALIDATOR_DOCK_SCENE_PATH: String = "res://addons/validator/dock/validator_dock.tscn"
const VALIDATOR_SETTINGS_PATH: String = "res://addons/validator/settings/validator_settings.tres"
var dock: ValidatorDock

var settings: ValidatorSettings:
	get:
		if not settings:
			settings = load(VALIDATOR_SETTINGS_PATH) as ValidatorSettings
		return settings


func _enable_plugin() -> void:
	_print_debug("Enabling plugin...")


func _disable_plugin() -> void:
	_print_debug("Disabling plugin...")


func _enter_tree():
	_print_debug("Entering tree...")
	_connect_signals()
	dock = preload(VALIDATOR_DOCK_SCENE_PATH).instantiate() as ValidatorDock
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)


func _exit_tree():
	_print_debug("Exiting tree...")
	_disconnect_signals()
	_remove_dock()


func _connect_signals():
	_print_debug("Connecting signals...")
	scene_saved.connect(_on_scene_saved)


func _disconnect_signals():
	_print_debug("Disconnecting signals...")
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)


func _remove_dock():
	remove_control_from_docks(dock)
	dock.free()


func _on_scene_saved(file_path: String) -> void:
	_print_debug("Scene saved: %s" % file_path)
	var current_edited_scene_root: Node = get_editor_interface().get_edited_scene_root()
	if not is_instance_valid(current_edited_scene_root):
		_print_debug("No current edited scene root. Skipping validation.")
		return

	dock.clear_errors()

	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(current_edited_scene_root)
	_print_debug("Found %d nodes to validate." % nodes_to_validate.size())

	for node: Node in nodes_to_validate:
		_validate_node(node)


## Finds all nodes in the tree that implement the VALIDATING_METHOD_NAME method recursively.
## Returns an array of nodes that implement the VALIDATING_METHOD_NAME method.
func _find_nodes_to_validate_in_tree(node: Node) -> Array:
	var nodes_to_validate: Array = []

	if node.has_method(VALIDATING_METHOD_NAME):
		nodes_to_validate.append(node)

	for child in node.get_children():
		nodes_to_validate.append_array(_find_nodes_to_validate_in_tree(child))
	return nodes_to_validate


func _validate_node(node: Node) -> void:
	_print_debug("Validating node: %s" % node.name)
	var validation_target: Object = node
	validation_target = _make_instance_from_placeholder(node)

	# Now call the method on the appropriate target (the original node if @tool,
	# or the new instance if non-@tool).
	if validation_target.has_method(VALIDATING_METHOD_NAME):
		_print_debug("Calling %s on %s" % [VALIDATING_METHOD_NAME, validation_target])
		var generated_conditions = validation_target.call(VALIDATING_METHOD_NAME)
		_print_debug("Generated validation conditions: %s" % [generated_conditions])
		var validation_result = ValidationResult.new(generated_conditions)
		for error in validation_result.errors:
			_print_debug("Validation error in node %s: %s" % [node.name, error])
			dock.add_to_dock(node, "[b]Configuration warning in %s:[/b]\n%s" % [node.name, error])

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


func _make_instance_from_placeholder(original_node: Node) -> Object:
	var script: Script = original_node.get_script()
	var is_tool_script: bool = script and script.is_tool()

	if not (script and not is_tool_script):
		# If there's no script, or if it's a @tool script, return the original node.
		# (The non-placeholder instance doesn't matter or already exists)
		return original_node

	# Create a new instance of the script
	var new_instance: Node = script.new()

	# Duplicate the children from the original node to the new instance
	for child in original_node.get_children():
		new_instance.add_child(child.duplicate())

	_copy_properties(original_node, new_instance)
	return new_instance


func _copy_properties(from_node: Node, to_node: Node) -> void:
	for prop in from_node.get_property_list():
		if prop.usage & PROPERTY_USAGE_EDITOR:  # Only copy editable properties
			to_node.set(prop.name, from_node.get(prop.name))


func _print_debug(message: String) -> void:
	if settings.show_debug_prints:
		print("[VALIDATOR] %s" % message)
