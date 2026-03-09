## Godot Doctor - A plugin to validate node and resource configurations in the Godot Editor.
## Author: CodeVogel (https://codevogel.com/)
## Repository: https://github.com/codevogel/godot_doctor
## Report issues or feature requests at https://github.com/codevogel/godot_doctor/issues
## License: MIT
@tool
class_name GodotDoctorPlugin
extends EditorPlugin

## Emitted when validation is complete.
## In Headless mode, this signals the CLI reporter to exit the process.
## In Editor mode, this can be used to trigger any post-validation actions.
signal validation_complete

#gdlint: disable=max-line-length
## The method name that nodes and resources should implement to provide validation conditions.
const VALIDATING_METHOD_NAME: String = "_get_validation_conditions"
## The path of the dock scene used to display validation warnings.
const VALIDATOR_DOCK_SCENE_PATH: String = "res://addons/godot_doctor/editor/dock/godot_doctor_dock.tscn"
## The path of the settings resource used to configure the plugin.
const VALIDATOR_SETTINGS_PATH: String = "res://addons/godot_doctor/settings/godot_doctor_settings.tres"
const PLUGIN_WELCOME_MESSAGE: String = "Godot Doctor is ready! 👨🏻‍⚕️🩺\nThe plugin has succesfully been enabled. You'll now see the Godot Doctor dock in your editor.\nYou can change its default position in the settings resource (addons/godot_doctor/settings).\nYou can also disable this dialog there.\nBasic usage instructions are available in the README or on the GitHub repository.\nPlease report any issues, bugs, or feature requests on GitHub.\nHappy developing!\n- CodeVogel 🐦"
const PLUGIN_REPOSITORY_URL: String = "https://github.com/codevogel/godot_doctor"
#gdlint: enable=max-line-length

## Singleton instance of the plugin for global access if needed.
## Avoid using this directly in most cases.
## This can, however, be useful for starting validation from external scripts
## such as the Dock's 'Validate Now' button.
static var instance: GodotDoctorPlugin:
	get:
		assert(_instance != null, "GodotDoctorPlugin instance is not initialized yet.")
		return _instance

static var _instance: GodotDoctorPlugin = null

## A Resource that holds the settings for the Godot Doctor plugin.
var settings: GodotDoctorSettings:
	get:
		# This may be used before @onready
		# so we lazy load it here if needed.
		if not settings:
			settings = load(VALIDATOR_SETTINGS_PATH) as GodotDoctorSettings
		return settings

## The dock for displaying validation results (editor mode only).
var _dock: GodotDoctorDock

## The active reporter — either EditorValidationReporter or CLIValidationReporter.
var _reporter: ValidationReporter

# ============================================================================
# LIFECYCLE METHODS - Plugin initialization and cleanup
# ============================================================================


## Called when the plugin is enabled by the user through Project Settings > Plugins.
## Displays a welcome dialog if configured in settings.
func _enable_plugin() -> void:
	GodotDoctorNotifier.print_debug("Enabling plugin...")

	if settings.show_welcome_dialog:
		_show_welcome_dialog()
	GodotDoctorNotifier.print_debug("Plugin enabled")


## Called when the plugin is disabled by the user through Project Settings > Plugins.
func _disable_plugin() -> void:
	GodotDoctorNotifier.print_debug("Disabling plugin...")
	GodotDoctorNotifier.print_debug("Plugin disabled")


## Called when the plugin enters the scene tree.
## Initializes the plugin by connecting signals and adding the dock to the editor,
## or running in CLI mode when headless.
func _enter_tree():
	_instance = self
	GodotDoctorNotifier.print_debug("Set plugin singleton")
	GodotDoctorNotifier.print_debug("Entering tree...")

	if DisplayServer.get_name() == "headless":
		if settings.run_cli_in_headless_mode:
			_reporter = CLIValidationReporter.new(get_tree())
			_connect_signals()
			_run_cli()
		return

	_add_dock()
	_reporter = EditorValidationReporter.new(_dock, settings)
	_connect_signals()
	GodotDoctorNotifier.push_toast("Plugin loaded.", 0)
	GodotDoctorNotifier.print_debug("Entered tree")


## Called when the plugin exits the scene tree.
## Cleans up the plugin by disconnecting signals and removing the dock.
func _exit_tree():
	GodotDoctorNotifier.print_debug("Exiting tree...")
	_disconnect_signals()

	if _dock != null:
		await _remove_dock()
	GodotDoctorNotifier.push_toast("Plugin unloaded.", 0)
	GodotDoctorNotifier.print_debug("Exited tree")

	GodotDoctorNotifier.print_debug("Clearing plugin singleton")
	_instance = null


## Entry point for running the plugin in CLI mode when in headless display server.
func _run_cli():
	GodotDoctorNotifier.print_debug(
		(
			"Running in CLI mode. Starting validation after configured delay (%s seconds)..."
			% settings.delay_before_running_cli
		)
	)
	await get_tree().create_timer(settings.delay_before_running_cli).timeout

	for validation_suite in settings.validation_suites:
		_run_cli_for_suite(validation_suite)
	GodotDoctorNotifier.print_debug("Emitting validation complete signal...")
	validation_complete.emit()


## Runs validation for a given validation suite in CLI mode.
func _run_cli_for_suite(validation_suite: ValidationSuite) -> void:
	GodotDoctorNotifier.print_debug("Running validation suite: %s" % validation_suite.resource_path)
	_reporter.current_suite = validation_suite
	var cli_reporter := _reporter as CLIValidationReporter
	var editor_interface: EditorInterface = get_editor_interface()

	for scene_path: String in validation_suite.scenes:
		cli_reporter.current_scene_path = scene_path  # set before validating
		editor_interface.open_scene_from_path(scene_path)
		_validate_scene_root(editor_interface.get_edited_scene_root())

	for resource_path: String in validation_suite.resources:
		var resource := load(resource_path) as Resource
		editor_interface.get_inspector().edit(resource)
		_validate_resource(resource)
		editor_interface.get_inspector().edit(null)


# ============================================================================
# SIGNAL MANAGEMENT - Connection and disconnection of signals
# ============================================================================


## Connects all necessary signals for the plugin to function.
func _connect_signals():
	GodotDoctorNotifier.print_debug("Connecting signals...")
	scene_saved.connect(_on_scene_saved)

	validation_complete.connect(_reporter.on_validation_complete)


## Disconnects all connected signals to avoid dangling connections.
func _disconnect_signals():
	GodotDoctorNotifier.print_debug("Disconnecting signals...")
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)

	if validation_complete.is_connected(_reporter.on_validation_complete):
		validation_complete.disconnect(_reporter.on_validation_complete)


# ============================================================================
# UI AND DIALOG MANAGEMENT - Welcome dialog and dock management
# ============================================================================


## Shows a welcome dialog to the user on first plugin enable.
## Displays the welcome message and a link to the GitHub repository.
func _show_welcome_dialog():
	GodotDoctorNotifier.print_debug("Showing welcome dialog...")
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
	GodotDoctorNotifier.print_debug("Adding dock to editor...")
	_dock = preload(VALIDATOR_DOCK_SCENE_PATH).instantiate() as GodotDoctorDock
	add_control_to_dock(
		_setting_dock_slot_to_editor_dock_slot(settings.default_dock_position), _dock
	)


## Removes the validation warnings dock from the editor and frees it.
func _remove_dock():
	GodotDoctorNotifier.print_debug("Removing dock from editor...")
	remove_control_from_docks(_dock)
	_dock.free()
	await _dock.tree_exited
	_dock = null


# ============================================================================
# EVENT HANDLERS - Signal callbacks for scene saves and validation requests
# ============================================================================


## Called when a scene is saved by the user.
func _on_scene_saved(file_path: String) -> void:
	GodotDoctorNotifier.print_debug("Scene saved: %s" % file_path)
	if settings.validate_on_save:
		validate_scene_root_and_edited_resource()


## Validation entry point for both the current scene root and edited resource.
## NOTE: This should not be used in headless mode; use _run_cli instead.
func validate_scene_root_and_edited_resource() -> void:
	GodotDoctorNotifier.print_debug("Validating scene root and edited resource...")

	var editor_dock := _reporter as EditorValidationReporter
	if editor_dock == null:
		push_error("validate_scene_root_and_edited_resource called outside of editor mode.")
		return

	_dock.clear_errors()

	var current_edited_scene_root: Node = get_editor_interface().get_edited_scene_root()
	if current_edited_scene_root != null:
		_validate_scene_root(current_edited_scene_root)
	else:
		GodotDoctorNotifier.print_debug("No current edited scene root. Skipping scene validation.")

	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if edited_object is Resource:
		var resource_script: Script = edited_object.get_script()
		if resource_script != null:
			_validate_resource(edited_object as Resource)
		else:
			GodotDoctorNotifier.print_debug(
				"Edited resource %s has no script. Skipping resource validation." % edited_object
			)
	GodotDoctorNotifier.print_debug("Emitting validation complete signal...")
	validation_complete.emit()


# ============================================================================
# CORE VALIDATION - Pure validation entry points (reporter-agnostic)
# ============================================================================


## Validates all eligible nodes in a scene and reports results via the active reporter.
## [param scene_root] - The root node of the scene to validate.
## NOTE: The scene must be currently open in the editor for validation to work.
func _validate_scene_root(scene_root: Node) -> void:
	GodotDoctorNotifier.print_debug("Validating scene root: %s" % scene_root.name)
	assert(get_editor_interface().get_edited_scene_root() == scene_root)

	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(scene_root)
	GodotDoctorNotifier.print_debug("Found %d nodes to validate." % nodes_to_validate.size())

	for node: Node in nodes_to_validate:
		var messages: Array[ValidationMessage] = _collect_node_messages(node)
		if not messages.is_empty():
			_reporter.report_node_messages(node, messages)


## Validates a resource and reports results via the active reporter.
## [param resource] - The resource to validate.
func _validate_resource(resource: Resource) -> void:
	GodotDoctorNotifier.print_debug(
		"Resource validation requested for resource: %s" % resource.resource_path
	)

	var script: Script = resource.get_script()
	if script in settings.default_validation_ignore_list:
		return

	var messages: Array[ValidationMessage] = _collect_resource_messages(resource)
	if not messages.is_empty():
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

	if settings.use_default_validations:
		conditions.append_array(_get_default_validation_conditions(validation_target))

	if validation_target.has_method(VALIDATING_METHOD_NAME):
		GodotDoctorNotifier.print_debug(
			"Calling %s on %s" % [VALIDATING_METHOD_NAME, validation_target]
		)
		var generated: Array[ValidationCondition] = validation_target.call(VALIDATING_METHOD_NAME)
		GodotDoctorNotifier.print_debug("Generated validation conditions: %s" % [generated])
		conditions.append_array(generated)
	elif not settings.use_default_validations:
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

	if settings.use_default_validations:
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
	if script != null and not (script in settings.default_validation_ignore_list):
		if settings.use_default_validations or node.has_method(VALIDATING_METHOD_NAME):
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


# ============================================================================
# UTILITY METHODS - Debug printing, toasts, and configuration mapping
# ============================================================================


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
