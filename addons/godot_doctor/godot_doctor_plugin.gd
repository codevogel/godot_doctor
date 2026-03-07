## Godot Doctor - A plugin to validate node and resource configurations in the Godot Editor.
## Author: CodeVogel (https://codevogel.com/)
## Repository: https://github.com/codevogel/godot_doctor
## Report issues or feature requests at https://github.com/codevogel/godot_doctor/issues
## License: MIT
@tool
class_name GodotDoctorPlugin
extends EditorPlugin

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

## Singleton instance of the plugin for global access if needed.
## Avoid using this directly in most cases.
## This can, however,  be useful for starting validation from external scripts
## such as the Dock's 'Validate Now' button
static var instance: GodotDoctorPlugin

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

var _headless_mode: bool = false
var _num_errors: int = 0

# ============================================================================
# LIFECYCLE METHODS - Plugin initialization and cleanup
# ============================================================================


## Called when the plugin is enabled by the user through Project Settings > Plugins.
## Displays a welcome dialog if configured in settings.
func _enable_plugin() -> void:
	_print_debug("Enabling plugin...")
	instance = self
	# We don't really have any globals to load yet, but this is where we would do it.

	if settings.show_welcome_dialog:
		_show_welcome_dialog()


## Called when the plugin is disabled by the user through Project Settings > Plugins.
func _disable_plugin() -> void:
	instance = null
	_print_debug("Disabling plugin...")


## Called when the plugin enters the scene tree.
## Initializes the plugin by connecting signals and adding the dock to the editor.
func _enter_tree():
	if DisplayServer.get_name() == "headless":
		_headless_mode = true

	_print_debug("Entering tree...")
	_connect_signals()

	if _headless_mode and not settings.run_cli_in_headless_mode:
		_run_cli()
		return
	_add_dock()
	_push_toast("Plugin loaded.", 0)


## Called when the plugin exits the scene tree.
## Cleans up the plugin by disconnecting signals and removing the dock.
func _exit_tree():
	_print_debug("Exiting tree...")
	_disconnect_signals()
	if _headless_mode:
		return
	_remove_dock()
	_push_toast("Plugin unloaded.", 0)


## Entry point for running the plugin in CLI mode when in headless display server.
func _run_cli():
	for validation_suite in settings.validation_suites:
		_print_debug("Running validation suite: %s" % validation_suite.name)
		_run_cli_for_suite(validation_suite)

	get_tree().quit(0 if _num_errors == 0 else 1)


## Runs validation for a given validation suite in CLI mode.
func _run_cli_for_suite(validation_suite: ValidationSuite) -> void:
	var editor_interface: EditorInterface = get_editor_interface()

	for scene_path: String in validation_suite.scenes:
		editor_interface.open_scene_from_path(scene_path)
		_start_validate_scene_root(editor_interface.get_edited_scene_root(), validation_suite)

	for resource_path: String in validation_suite.resources:
		var resource = load(resource_path) as Resource
		editor_interface.get_inspector().edit(resource)
		_start_validate_edited_resource(resource, validation_suite)
		editor_interface.get_inspector().edit(null)


# ============================================================================
# SIGNAL MANAGEMENT - Connection and disconnection of signals
# ============================================================================


## Connects all necessary signals for the plugin to function.
func _connect_signals():
	_print_debug("Connecting signals...")
	scene_saved.connect(_on_scene_saved)


## Disconnects all connected signals to avoid dangling connections.
func _disconnect_signals():
	_print_debug("Disconnecting signals...")
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)


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


func _add_dock():
	_print_debug("Adding dock to editor...")
	_dock = preload(VALIDATOR_DOCK_SCENE_PATH).instantiate() as GodotDoctorDock
	add_control_to_dock(
		_setting_dock_slot_to_editor_dock_slot(settings.default_dock_position), _dock
	)


## Removes the validation warnings dock from the editor and frees it.
func _remove_dock():
	_print_debug("Removing dock from editor...")
	remove_control_from_docks(_dock)
	_dock.free()


# ============================================================================
# EVENT HANDLERS - Signal callbacks for scene saves and validation requests
# ============================================================================


## Called when a scene is saved by the user.
func _on_scene_saved(file_path: String) -> void:
	_print_debug("Scene saved: %s" % file_path)
	if settings.validate_on_save:
		validate_scene_root_and_edited_resource()


## Validation entry point for both scene root and edited resource.
## NOTE: This should not be used in headless mode, as it ignores
## the validation suites. Use _run_cli instead.
func validate_scene_root_and_edited_resource() -> void:
	print_debug("Validating scene root and edited resource...")
	var edited_scene_root: Node = null
	var edited_resource: Resource = null

	var current_edited_scene_root: Node = get_editor_interface().get_edited_scene_root()
	if current_edited_scene_root != null:
		edited_scene_root = current_edited_scene_root
	else:
		_print_debug("No current edited scene root. Skipping scene validation.")

	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if edited_object is Resource:
		var resource_script: Script = edited_object.get_script()
		if resource_script != null:
			edited_resource = edited_object as Resource
		else:
			_print_debug(
				"Edited resource %s has no script. Skipping resource validation." % edited_object
			)

	var validating_both_scene_and_resource: bool = (
		edited_scene_root != null and edited_resource != null
	)
	var validating_scene_only: bool = edited_scene_root != null and edited_resource == null
	var validating_resource_only: bool = edited_resource != null and edited_scene_root == null

	if validating_both_scene_and_resource:
		_print_debug("Validating both scene and resource...")
		_start_validate_scene_root(edited_scene_root, null, true)
		_start_validate_edited_resource(edited_resource, null, true)
	elif validating_scene_only:
		_print_debug("Validating scene only...")
		_start_validate_scene_root(edited_scene_root, null, true)
	elif validating_resource_only:
		_print_debug("Validating resource only...")
		_start_validate_edited_resource(edited_resource, null, true)


## Entry point to validate the currently edited scene root.
## [param edited_scene_root] - The root node of the currently edited scene to validate.
## [param validation_suite] - The validation suite to use for CLI mode validation.
## Leave [null] for editor validation.
## [param clear_errors] - Whether to clear existing errors from the dock before validating.
## NOTE: The [edited_scene_root] must be currently open in the editor for validation to work,
## as we need to traverse its nodes.
## TODO: test this note
func _start_validate_scene_root(
	edited_scene_root: Node, validation_suite: ValidationSuite = null, clear_errors: bool = false
) -> void:
	_print_debug("Scene root validation requested for scene: %s" % edited_scene_root.name)
	assert(get_editor_interface().get_edited_scene_root() == edited_scene_root)
	if clear_errors:
		_dock.clear_errors()

	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(edited_scene_root)
	_print_debug("Found %d nodes to validate." % nodes_to_validate.size())

	# Key: node path (String), Value: Array[ValidationMessage]
	var node_messages: Dictionary = {}
	for node: Node in nodes_to_validate:
		var messages: Array[ValidationMessage] = _validate_node(node)
		if messages.size() > 0:
			node_messages[edited_scene_root.get_path_to(node)] = messages

	if _headless_mode:
		_process_cli_scene_output(validation_suite, edited_scene_root, node_messages)


## Entry point to validate the currently edited resource.
## [param edited_resource] - The currently edited resource to validate.
## [param validation_suite] - The validation suite to use for CLI mode validation.
## Leave [null] for editor validation.
## [param clear_errors] - Whether to clear existing errors from the dock before validating.
func _start_validate_edited_resource(
	edited_resource: Resource, validation_suite: ValidationSuite = null, clear_errors: bool = false
) -> void:
	_print_debug("Resource validation requested for resource: %s" % edited_resource.resource_path)
	if clear_errors:
		_dock.clear_errors()

	var resource_validation_messages: Array[ValidationMessage] = []
	if edited_resource is Resource:
		var script: Script = edited_resource.get_script()
		if script not in settings.default_validation_ignore_list:
			resource_validation_messages.append_array(_validate_resource(edited_resource))

	if _headless_mode:
		_process_cli_resource_output(
			validation_suite, edited_resource, resource_validation_messages
		)


## Processes and prints validation results for scene validation in CLI mode.
func _process_cli_scene_output(
	validation_suite: ValidationSuite, scene_root: Node, node_messages: Dictionary
) -> void:
	assert(validation_suite != null)
	print("Scene: %s" % scene_root.name)
	for node_path in node_messages:
		var messages: Array = node_messages[node_path]
		for msg: ValidationMessage in messages:
			print("  [%s] %s: %s" % [msg.severity_level, node_path, msg.message])
			if (
				msg.severity_level == ValidationCondition.Severity.ERROR
				or (
					msg.severity_level == ValidationCondition.Severity.WARNING
					and validation_suite.treat_warnings_as_errors
				)
			):
				_num_errors += 1


## Processes and prints validation results for resource validation in CLI mode.
func _process_cli_resource_output(
	validation_suite: ValidationSuite, resource: Resource, messages: Array[ValidationMessage]
) -> void:
	assert(validation_suite != null)
	print("Resource: %s" % resource.resource_path)
	for msg: ValidationMessage in messages:
		print("  [%s] %s" % [msg.severity_level, msg.message])
		if (
			msg.severity_level == ValidationCondition.Severity.ERROR
			or (
				msg.severity_level == ValidationCondition.Severity.WARNING
				and validation_suite.treat_warnings_as_errors
			)
		):
			_num_errors += 1


# ============================================================================
# CORE VALIDATION - Main validation entry points for nodes and resources
# ============================================================================


## Validates a resource by collecting default validation conditions (if enabled)
## and any custom validation conditions defined in the resource.
## Processes the validation conditions and reports any errors to the dock.
## NOTE: This should not be called directly - use _start_validate_edited_resource instead,
## which handles setup and teardown for resource validation.
func _validate_resource(resource: Resource) -> Array[ValidationMessage]:
	var validation_conditions: Array[ValidationCondition] = []
	if settings.use_default_validations:
		validation_conditions.append_array(_get_default_validation_conditions(resource))
	if resource.has_method(VALIDATING_METHOD_NAME):
		var generated_conditions: Array[ValidationCondition] = resource.call(VALIDATING_METHOD_NAME)
		validation_conditions.append_array(generated_conditions)
	var validation_messages: Array[ValidationMessage] = _validate_resource_validation_conditions(
		resource, validation_conditions
	)
	return validation_messages


## Validates a single node by collecting default validation conditions (if enabled),
## custom validation conditions defined in the node (handling both @tool and non-@tool scripts),
## and processing the results.
## For non-@tool scripts, creates a temporary instance to call validation methods on.
## NOTE: This should not be called directly - use _start_validate_scene_root instead,
## which handles setup and teardown for scene validation.
func _validate_node(node: Node) -> Array[ValidationMessage]:
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

	var validation_messages: Array[ValidationMessage] = _validate_node_validation_conditions(
		node, validation_conditions
	)

	# If we created a temporary instance, we should free it.
	if validation_target != node and is_instance_valid(validation_target):
		validation_target.free()

	return validation_messages


# ============================================================================
# VALIDATION CONDITION PROCESSING - Processing and reporting validation results
# ============================================================================


## Processes validation conditions for a resource.
## Evaluates all conditions, formats errors, displays toasts, and adds warnings to the dock.
func _validate_resource_validation_conditions(
	resource: Resource, validation_conditions: Array[ValidationCondition]
) -> Array[ValidationMessage]:
	var validation_result: ValidationResult = ValidationResult.new(validation_conditions)
	var validation_messages: Array[ValidationMessage] = validation_result.messages
	if validation_messages.size() > 0:
		# Transform messages into errors if the setting is enabled.
		# NOTE: This is not done in headless mode, since the Validation Suites can define
		# this behavior themselves, and the plugin setting should not override that.
		if not _headless_mode:
			validation_messages.map(
				func(msg: ValidationMessage) -> ValidationMessage:
					var severity_level = msg.severity_level
					if settings.treat_warnings_as_errors:
						if severity_level == ValidationCondition.Severity.WARNING:
							severity_level = ValidationCondition.Severity.ERROR
					return ValidationMessage.new(msg.message, severity_level)
			)

		# Get the highest severity level among the messages to determine the toast severity.
		var severity_level = (
			validation_messages
			. map(func(msg: ValidationMessage) -> int: return msg.severity_level)
			. max()
		)

		if not _headless_mode:
			_push_toast(
				(
					"Found %s configuration warning(s) in %s."
					% [validation_result.messages.size(), resource.resource_path]
				),
				severity_level
			)
	for msg in validation_messages:
		var name: String = resource.resource_path.split("/")[-1]
		_print_debug(
			(
				"Found message with severity %s in node %s: %s"
				% [msg.severity_level, resource, msg.message]
			)
		)

		if not _headless_mode:
			_print_debug("Adding message to dock...")
			# Push the warning to the dock, passing the original resource so the user can locate it.
			_dock.add_resource_warning_to_dock(resource, msg)
	return validation_messages


## Processes validation conditions for a node.
## Evaluates all conditions, formats errors, displays toasts, and adds warnings to the dock.
func _validate_node_validation_conditions(
	node: Node, validation_conditions: Array[ValidationCondition]
) -> Array[ValidationMessage]:
	var validation_messages: Array[ValidationMessage] = []
	# ValidationResult processes the conditions upon instantiation.
	var validation_result = ValidationResult.new(validation_conditions)
	validation_messages.append_array(validation_result.messages)
	# Process the resulting errors
	if validation_messages.size() > 0:
		# Transform messages into errors if the setting is enabled.
		# NOTE: This is not done in headless mode, since the Validation Suites can define
		# this behavior themselves, and the plugin setting should not override that.
		if not _headless_mode:
			validation_messages.map(
				func(msg: ValidationMessage) -> ValidationMessage:
					var severity_level = msg.severity_level
					if settings.treat_warnings_as_errors:
						if severity_level == ValidationCondition.Severity.WARNING:
							severity_level = ValidationCondition.Severity.ERROR
					return ValidationMessage.new(msg.message, severity_level)
			)

		# Get the highest severity level among the messages to determine the toast severity.
		var severity_level = (
			validation_messages
			. map(func(msg: ValidationMessage) -> int: return msg.severity_level)
			. max()
		)

		if not _headless_mode:
			_push_toast(
				(
					"Found %s configuration warning(s) in %s."
					% [validation_result.messages.size(), node.name]
				),
				severity_level
			)
	for msg in validation_messages:
		_print_debug(
			(
				"Found message with severity %s in node %s: %s"
				% [msg.severity_level, node.name, msg.message]
			)
		)
		if not _headless_mode:
			_print_debug("Adding message to dock...")
			# Push the warning to the dock, passing the original node so the user can locate it.
			_dock.add_node_warning_to_dock(node, msg)
	return validation_messages


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
