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

## The path of the dock scene used to display validation warnings.
const VALIDATOR_DOCK_SCENE_PATH: String = "res://addons/godot_doctor/dock/godot_doctor_dock.tscn"

const PLUGIN_WELCOME_MESSAGE: String = "Godot Doctor is ready! 👨🏻‍⚕️🩺\nThe plugin has succesfully been enabled. You'll now see the Godot Doctor dock in your editor.\nYou can change its default position in the settings resource (addons/godot_doctor/settings).\nYou can also disable this dialog there.\nBasic usage instructions are available in the README or on the GitHub repository.\nPlease report any issues, bugs, or feature requests on GitHub.\nHappy developing!\n- CodeVogel 🐦"
const PLUGIN_REPOSITORY_URL: String = "https://github.com/codevogel/godot_doctor"
#gdlint: enable=max-line-length

## A Resource that holds the settings for the Godot Doctor plugin.
var settings: GodotDoctorSettings:
	get:
		# This may be used before @onready
		# so we lazy load it here if needed.
		if not settings:
			settings = load(SceneValidator.VALIDATOR_SETTINGS_PATH) as GodotDoctorSettings
		return settings

## The dock for displaying validation results.
var _dock: GodotDoctorDock

var _output : ValidatorUIOutputWrapper
var _validator : SceneValidator

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
		
	_dock = preload(VALIDATOR_DOCK_SCENE_PATH).instantiate() as GodotDoctorDock
	_output = ValidatorUIOutputWrapper.new(_dock, settings)
	_validator = SceneValidator.new(_output)
	
	add_control_to_dock(
		_setting_dock_slot_to_editor_dock_slot(settings.default_dock_position), _dock
	)
	
	_connect_signals()
	
	_output.push_toast("Plugin loaded.", 0)


## Called when the plugin exits the scene tree.
## Cleans up the plugin by disconnecting signals and removing the dock.
func _exit_tree():
	_print_debug("Exiting tree...")
	
	_disconnect_signals()
	_remove_dock()
	
	_output.push_toast("Plugin unloaded.", 0)


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
			_validator.validate_resource(edited_object as Resource)

	# Find all nodes to validate
	var nodes_to_validate: Array = _validator.find_nodes_to_validate_in_tree(scene_root)
	_print_debug("Found %d nodes to validate." % nodes_to_validate.size())

	# Validate each node
	for node: Node in nodes_to_validate:
		_validator.validate_node(node)

# ============================================================================
# UTILITY METHODS - Debug printing, configuration mapping
# ============================================================================

## Prints a debug message to the console if debug printing is enabled in settings.
func _print_debug(message: String) -> void:
	if settings.show_debug_prints:
		print("[GODOT DOCTOR] %s" % message)

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
