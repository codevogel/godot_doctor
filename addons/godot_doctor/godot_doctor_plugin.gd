## Godot Doctor - A plugin to validate node and resource configurations in the Godot Editor.
## Author: CodeVogel (https://codevogel.com/)
## Repository: https://github.com/codevogel/godot_doctor
## Report issues or feature requests at https://github.com/codevogel/godot_doctor/issues
## License: MIT
@tool
extends EditorPlugin

## Emitted when a validation is requested, passing the root node of the current edited scene.
signal validation_requested(scene_root: Node)

#gdlint: disable=max-line-length
## The method name that nodes and resources should implement to provide validation conditions.
const VALIDATING_METHOD_NAME: String = "_get_validation_conditions"
## The path of the dock scene used to display validation warnings.
const VALIDATOR_DOCK_SCENE_PATH: String = "res://addons/godot_doctor/dock/godot_doctor_dock.tscn"
## The path of the settings resource used to configure the plugin.
const VALIDATOR_SETTINGS_PATH: String = "res://addons/godot_doctor/settings/godot_doctor_settings.tres"
const PLUGIN_WELCOME_MESSAGE: String = "Godot Doctor is ready! 👨🏻‍⚕️🩺\nThe plugin has succesfully been enabled. You'll now see the Godot Doctor dock in your editor.\nYou can change its default position in the settings resource (addons/godot_doctor/settings).\nYou can also disable this dialog there.\nBasic usage instructions are available in the README or on the GitHub repository.\nPlease report any issues, bugs, or feature requests on GitHub.\nHappy developing!\n- CodeVogel 🐦"
const PLUGIN_REPOSITORY_URL: String = "https://github.com/codevogel/godot_doctor"
#gdlint: enable=max-line-length

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

# ============================================================================
# LIFECYCLE METHODS - Plugin initialization and cleanup
# ============================================================================


## Called when the plugin is enabled by the user through Project Settings > Plugins.
## Displays a welcome dialog if configured in settings.
func _enable_plugin() -> void:
	_print_debug("Enabling plugin...")
	# We don't really have any globals to load yet, but this is where we would do it.

	if settings.show_welcome_dialog:
		_show_welcome_dialog()


## Called when the plugin is disabled by the user through Project Settings > Plugins.
func _disable_plugin() -> void:
	_print_debug("Disabling plugin...")


## Called when the plugin enters the scene tree.
## Initializes the plugin by connecting signals and adding the dock to the editor.
func _enter_tree():
	_print_debug("Entering tree...")
	_connect_signals()
	_dock = preload(VALIDATOR_DOCK_SCENE_PATH).instantiate() as GodotDoctorDock
	add_control_to_dock(
		_setting_dock_slot_to_editor_dock_slot(settings.default_dock_position), _dock
	)
	_push_toast("Plugin loaded.", 0)


## Called when the plugin exits the scene tree.
## Cleans up the plugin by disconnecting signals and removing the dock.
func _exit_tree():
	_print_debug("Exiting tree...")
	_disconnect_signals()
	_remove_dock()
	_push_toast("Plugin unloaded.", 0)


# ============================================================================
# SIGNAL MANAGEMENT - Connection and disconnection of signals
# ============================================================================


## Connects all necessary signals for the plugin to function.
## Connects to scene_saved and validation_requested signals.
func _connect_signals():
	_print_debug("Connecting signals...")
	scene_saved.connect(_on_scene_saved)
	validation_requested.connect(_on_validation_requested)


## Disconnects all connected signals to avoid dangling connections.
## Safely disconnects even if signals are not currently connected.
func _disconnect_signals():
	_print_debug("Disconnecting signals...")
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)
	if validation_requested.is_connected(_on_validation_requested):
		validation_requested.disconnect(_on_validation_requested)


# ============================================================================
# UI AND DIALOG MANAGEMENT - Welcome dialog and dock management
# ============================================================================


## Shows a welcome dialog to the user on first plugin enable.
## Displays the welcome message and a link to the GitHub repository.
func _show_welcome_dialog():
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Godot Doctor"
	dialog.dialog_text = ""
	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)
	var label: Label = Label.new()
	label.text = PLUGIN_WELCOME_MESSAGE
	vbox.add_child(label)
	var link_button: LinkButton = LinkButton.new()
	link_button.text = "GitHub Repository"
	link_button.uri = PLUGIN_REPOSITORY_URL
	vbox.add_child(link_button)

	get_editor_interface().get_base_control().add_child(dialog)
	dialog.exclusive = false
	dialog.popup_centered()


## Removes the validation warnings dock from the editor and frees it.
func _remove_dock():
	remove_control_from_docks(_dock)
	_dock.free()


# ============================================================================
# EVENT HANDLERS - Signal callbacks for scene saves and validation requests
# ============================================================================


## Called when a scene is saved by the user.
## Retrieves the edited scene root and emits the validation_requested signal.
func _on_scene_saved(file_path: String) -> void:
	_print_debug("Scene saved: %s" % file_path)
	var current_edited_scene_root: Node = get_editor_interface().get_edited_scene_root()
	if not is_instance_valid(current_edited_scene_root):
		_print_debug("No current edited scene root. Skipping validation.")
		return
	validation_requested.emit(current_edited_scene_root)


## Called when validation is requested for the current scene.
## Clears previous errors, validates the edited resource if applicable,
## finds all nodes to validate in the scene tree, and validates each one.
func _on_validation_requested(scene_root: Node) -> void:
	# Clear previous errors
	_dock.clear_errors()

	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if edited_object is Resource:
		var script: Script = edited_object.get_script()
		if script not in settings.default_validation_ignore_list:
			_validate_resource(edited_object as Resource)

	# Find all nodes to validate
	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(scene_root)
	_print_debug("Found %d nodes to validate." % nodes_to_validate.size())

	# Validate each node
	for node: Node in nodes_to_validate:
		_validate_node(node)


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


# ============================================================================
# VALIDATION CONDITION PROCESSING - Processing and reporting validation results
# ============================================================================


## Processes validation conditions for a resource.
## Evaluates all conditions, formats errors, displays toasts, and adds warnings to the dock.
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
		# Push the warning to the dock, passing the original resource so the user can locate it.
		_dock.add_resource_warning_to_dock(
			resource, "[b]Configuration warning in %s:[/b]\n%s" % [name, error]
		)


## Processes validation conditions for a node.
## Evaluates all conditions, formats errors, displays toasts, and adds warnings to the dock.
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


# ============================================================================
# UTILITY METHODS - Debug printing, toasts, and configuration mapping
# ============================================================================


## Prints a debug message to the console if debug printing is enabled in settings.
func _print_debug(message: String) -> void:
	if settings.show_debug_prints:
		print("[GODOT DOCTOR] %s" % message)


## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## [param severity] - 0 for info (default), 1 for warning, 2 for error.
func _push_toast(message: String, severity: int = 0) -> void:
	if settings.show_toasts:
		EditorInterface.get_editor_toaster().push_toast("Godot Doctor: %s" % message, severity)


## Converts the custom DockSlot enum from settings to the EditorPlugin.DockSlot enum.
## Maps all eight dock slot positions from the settings enum to the engine enum values.
#gdlint:disable = max-returns
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
#gdlint:enable = max-returns
