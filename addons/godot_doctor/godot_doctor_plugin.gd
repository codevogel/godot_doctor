## Godot Doctor - A plugin to validate node and resource configurations in the Godot Editor.
## Author: CodeVogel (https://codevogel.com/)
## Repository: https://github.com/codevogel/godot_doctor
## Report issues or feature requests at https://github.com/codevogel/godot_doctor/issues
## License: MIT
@tool
extends EditorPlugin

## Emitted when a validation is requested, passing the root node of the current edited scene.
signal validation_requested(scene_root: Node)

## The method name that nodes and resources should implement to provide validation conditions.
const VALIDATING_METHOD_NAME: String = "_get_validation_conditions"
## The path of the dock scene used to display validation warnings.
const VALIDATOR_DOCK_SCENE_PATH: String = "res://addons/godot_doctor/dock/godot_doctor_dock.tscn"
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

## The dock for displaying validation results.
var _dock: GodotDoctorDock


## Called when we enable the plugin
func _enable_plugin() -> void:
	_print_debug("Enabling plugin...")
	# We don't really have any globals to load yet, but this is where we would do it.

	if settings.show_welcome_dialog:
		_show_welcome_dialog()


## Called when we disable the plugin
func _disable_plugin() -> void:
	_print_debug("Disabling plugin...")


## Initializes the plugin by connecting signals and adding the dock to the editor.
func _enter_tree():
	_print_debug("Entering tree...")
	_connect_signals()
	_dock = preload(VALIDATOR_DOCK_SCENE_PATH).instantiate() as GodotDoctorDock
	add_control_to_dock(
		_setting_dock_slot_to_editor_dock_slot(settings.default_dock_position), _dock
	)
	_push_toast("Plugin loaded.", 0)


## Cleans up the plugin by disconnecting signals and removing the dock.
func _exit_tree():
	_print_debug("Exiting tree...")
	_disconnect_signals()
	_remove_dock()
	_push_toast("Plugin unloaded.", 0)


## Connects all necessary signals for the plugin to function.
func _connect_signals():
	_print_debug("Connecting signals...")
	scene_saved.connect(_on_scene_saved)
	validation_requested.connect(_on_validation_requested)


## Disconnects all connected signals to avoid dangling connections.
func _disconnect_signals():
	_print_debug("Disconnecting signals...")
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)
	if validation_requested.is_connected(_on_validation_requested):
		validation_requested.disconnect(_on_validation_requested)


## Shows a welcome dialog to the user.
func _show_welcome_dialog():
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Godot Doctor"
	dialog.dialog_text = ""
	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)
	var label: Label = Label.new()
	label.text = "Godot Doctor is ready! 👨🏻‍⚕️🩺\nThe plugin has succesfully been enabled. You'll now see the Godot Doctor dock in your editor.\nYou can change its default position in the settings resource (addons/godot_doctor/settings).\nYou can also disable this dialog there.\nBasic usage instructions are available in the README or on the GitHub repository.\nPlease report any issues, bugs, or feature requests on GitHub.\nHappy developing!\n- CodeVogel 🐦"
	vbox.add_child(label)
	var link_button: LinkButton = LinkButton.new()
	link_button.text = "GitHub Repository"
	link_button.uri = "https://github.com/codevogel/godot_doctor"
	vbox.add_child(link_button)

	get_editor_interface().get_base_control().add_child(dialog)
	dialog.exclusive = false
	dialog.popup_centered()


## Removes the dock from the editor and frees it.
func _remove_dock():
	remove_control_from_docks(_dock)
	_dock.free()


## Called when a scene is saved.
## Emits the validation_requested signal with the current edited scene root.
func _on_scene_saved(file_path: String) -> void:
	_print_debug("Scene saved: %s" % file_path)
	var current_edited_scene_root: Node = get_editor_interface().get_edited_scene_root()
	if not is_instance_valid(current_edited_scene_root):
		_print_debug("No current edited scene root. Skipping validation.")
		return
	validation_requested.emit(current_edited_scene_root)


## Handles the validation request by finding all nodes to validate and validating them.
func _on_validation_requested(scene_root: Node) -> void:
	# Clear previous errors
	_dock.clear_errors()

	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if edited_object is Resource:
		_validate_resource(edited_object as Resource)

	# Find all nodes to validate
	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(scene_root)
	_print_debug("Found %d nodes to validate." % nodes_to_validate.size())

	# Validate each node
	for node: Node in nodes_to_validate:
		_validate_node(node)


func _validate_resource(resource: Resource):
	var validation_conditions: Array[ValidationCondition] = []
	if settings.use_default_validations:
		validation_conditions.append_array(_get_default_validation_conditions(resource))
	if resource.has_method(VALIDATING_METHOD_NAME):
		var generated_conditions: Array[ValidationCondition] = resource.call(VALIDATING_METHOD_NAME)
		validation_conditions.append_array(generated_conditions)
	_validate_resource_validation_conditions(resource, validation_conditions)


func _validate_resource_validation_conditions(
	resource: Resource, validation_conditions: Array[ValidationCondition]
) -> void:
	var validation_result: ValidationResult = ValidationResult.new(validation_conditions)
	if validation_result.errors.size() > 0:
		_push_toast(
			(
				"Found %s configuration warning(s) in %s."
				% [validation_result.errors.size(), resource.resource_path]
			),
			1
		)
	for error in validation_result.errors:
		var name: String = resource.resource_path.split("/")[-1]
		_print_debug("Found error in resource %s: %s" % [name, error])
		_print_debug("Adding error to dock...")
		# Push the warning to the dock, passing the original node so the user can locate it.
		_dock.add_resource_warning_to_dock(
			resource, "[b]Configuration warning in %s:[/b]\n%s" % [name, error]
		)


## Finds all nodes in the tree that implement the VALIDATING_METHOD_NAME method recursively.
## Returns an array of nodes that implement the VALIDATING_METHOD_NAME method.
func _find_nodes_to_validate_in_tree(node: Node) -> Array:
	var nodes_to_validate: Array = []

	# Only add nodes that have a script attached
	if node.get_script() != null:
		# Add all nodes if use_default_validations is true,
		# or add only the nodes that have the method if it is false
		if settings.use_default_validations or node.has_method(VALIDATING_METHOD_NAME):
			nodes_to_validate.append(node)

	# Add their children too, if any
	var children: Array[Node] = node.get_children()
	for child in children:
		nodes_to_validate.append_array(_find_nodes_to_validate_in_tree(child))
	return nodes_to_validate


## Validates a single node by calling its validation method and processing the results.
## Expects only nodes that are already confirmed to implement the VALIDATING_METHOD_NAME method.
func _validate_node(node: Node) -> void:
	_print_debug("Validating node: %s" % node.name)
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
		_print_debug("Calling %s on %s" % [VALIDATING_METHOD_NAME, validation_target])
		var generated_conditions = validation_target.call(VALIDATING_METHOD_NAME)
		_print_debug("Generated validation conditions: %s" % [generated_conditions])
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


## Handle validation for an array of validation conditions for Nodes
func _validate_node_validation_conditions(
	node: Node, validation_conditions: Array[ValidationCondition]
) -> void:
	var errors: PackedStringArray = []
	# ValidationResult processes the conditions upon instantiation.
	var validation_result = ValidationResult.new(validation_conditions)
	errors.append_array(validation_result.errors)
	# Process the resulting errors
	if errors.size() > 0:
		_push_toast(
			"Found %s configuration warnings in %s." % [validation_result.errors.size(), node.name],
			1
		)
	for error in errors:
		_print_debug("Found error in node %s: %s" % [node.name, error])
		_print_debug("Adding error to dock...")
		# Push the warning to the dock, passing the original node so the user can locate it.
		_dock.add_node_warning_to_dock(
			node, "[b]Configuration warning in %s:[/b]\n%s" % [node.name, error]
		)


## Get the default validation conditions for an Object
## (Scan it's export properties and check if Objects are valid instances and whether
##  strings are non-empty)
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


## Get all props that are annotated with `@export` from an object
func _get_export_props(object: Object) -> Array[Dictionary]:
	if object == null:
		return []

	var script: Script = object.get_script()
	if script == null and not object is Resource:
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


## If the original node is a placeholder for a non-@tool script, create a new instance of the script
## and copy over the properties and children from the original node.
## If the original node is a @tool script or has no script, return the original node
func _make_instance_from_placeholder(original_node: Node) -> Object:
	var script: Script = original_node.get_script()
	var is_tool_script: bool = script and script.is_tool()

	if not (script and not is_tool_script):
		# If there's no script, or if it's a @tool script, return the original node.
		# (The non-placeholder instance doesn't matter, sine we won't be validating it anyway,
		# or already exists, because it is a @tool script.)
		return original_node

	# Create a new instance of the script
	var new_instance: Node = script.new()

	# Duplicate the children from the original node to the new instance
	for child in original_node.get_children():
		new_instance.add_child(child.duplicate())

	_copy_properties(original_node, new_instance)
	return new_instance


## Copies all editable properties from one node to another.
func _copy_properties(from_node: Node, to_node: Node) -> void:
	for prop in from_node.get_property_list():
		if prop.usage & PROPERTY_USAGE_EDITOR:
			to_node.set(prop.name, from_node.get(prop.name))


## Prints a debug message if debug prints are enabled in settings.
func _print_debug(message: String) -> void:
	if settings.show_debug_prints:
		print("[GODOT DOCTOR] %s" % message)


## Pushes a toast message to the editor toaster if enabled in settings.
func _push_toast(message: String, severity: int = 0) -> void:
	if settings.show_toasts:
		EditorInterface.get_editor_toaster().push_toast("Godot Doctor: %s" % message, severity)


## Maps the custom DockSlot enum from settings to the EditorPlugin.DockSlot enum.
func _setting_dock_slot_to_editor_dock_slot(dock_slot: GodotDoctorSettings.DockSlot) -> DockSlot:
	match dock_slot:
		GodotDoctorSettings.DockSlot.DOCK_SLOT_LEFT_UL:
			return DockSlot.DOCK_SLOT_LEFT_UL
		GodotDoctorSettings.DockSlot.DOCK_SLOT_LEFT_BL:
			return DockSlot.DOCK_SLOT_LEFT_BL
		GodotDoctorSettings.DockSlot.DOCK_SLOT_LEFT_UR:
			return DockSlot.DOCK_SLOT_LEFT_UR
		GodotDoctorSettings.DockSlot.DOCK_SLOT_LEFT_BR:
			return DockSlot.DOCK_SLOT_LEFT_BR
		GodotDoctorSettings.DockSlot.DOCK_SLOT_RIGHT_UL:
			return DockSlot.DOCK_SLOT_RIGHT_UL
		GodotDoctorSettings.DockSlot.DOCK_SLOT_RIGHT_BL:
			return DockSlot.DOCK_SLOT_RIGHT_BL
		GodotDoctorSettings.DockSlot.DOCK_SLOT_RIGHT_UR:
			return DockSlot.DOCK_SLOT_RIGHT_UR
		GodotDoctorSettings.DockSlot.DOCK_SLOT_RIGHT_BR:
			return DockSlot.DOCK_SLOT_RIGHT_BR
		_:
			return DockSlot.DOCK_SLOT_RIGHT_BL  # Default fallback
