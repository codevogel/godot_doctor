## Godot Doctor - A plugin to validate node and resource configurations in the Godot Editor.
## Author: CodeVogel (https://codevogel.com/)
## Repository: https://github.com/codevogel/godot_doctor
## Report issues or feature requests at https://github.com/codevogel/godot_doctor/issues
## License: MIT
@tool
class_name GodotDoctorPlugin
extends EditorPlugin

## Emitted when validation is complete.
signal validation_complete

#gdlint: disable=max-line-length
## The path of the settings resource used to configure the plugin.
const VALIDATOR_SETTINGS_PATH: String = "res://addons/godot_doctor/settings/godot_doctor_settings.tres"
const PLUGIN_WELCOME_MESSAGE: String = "Godot Doctor is ready! 👨🏻‍⚕️🩺\nThe plugin has succesfully been enabled. You'll now see the Godot Doctor dock in your editor.\nYou can change its default position in the settings resource (addons/godot_doctor/settings).\nYou can also disable this dialog there.\nBasic usage instructions are available in the README or on the GitHub repository.\nPlease report any issues, bugs, or feature requests on GitHub.\nHappy developing!\n- CodeVogel 🐦"
const PLUGIN_REPOSITORY_URL: String = "https://github.com/codevogel/godot_doctor"
#gdlint: enable=max-line-length

## Singleton instance of the plugin for global access if needed.
## Avoid using this directly in most cases.
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

## Handles all editor-mode setup, dock management, and validation.
var _editor_runner: GodotDoctorEditorRunner

#region Plugin Lifecycle


## Called when the plugin enters the scene tree.
## Initializes the plugin by connecting signals and adding the dock to the editor.
func _enter_tree():
	_instance = self
	GodotDoctorNotifier.print_debug("Set plugin singleton")
	GodotDoctorNotifier.print_debug("Entering tree...")

	_editor_runner = GodotDoctorEditorRunner.new()
	_connect_signals()
	GodotDoctorNotifier.push_toast("Plugin loaded.", 0)
	GodotDoctorNotifier.print_debug("Entered tree")


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


## Called when the plugin exits the scene tree.
## Cleans up the plugin by disconnecting signals and removing the dock.
func _exit_tree():
	GodotDoctorNotifier.print_debug("Exiting tree...")
	_disconnect_signals()

	if _editor_runner != null:
		_editor_runner.teardown()
		_editor_runner = null
	GodotDoctorNotifier.push_toast("Plugin unloaded.", 0)
	GodotDoctorNotifier.print_debug("Exited tree")

	GodotDoctorNotifier.print_debug("Clearing plugin singleton")
	_instance = null


#endregion

#region Signal Management


## Connects all necessary signals for the plugin to function.
func _connect_signals():
	GodotDoctorNotifier.print_debug("Connecting signals...")
	scene_saved.connect(_on_scene_saved)
	validation_complete.connect(_editor_runner.reporter.on_validation_complete)


## Disconnects all connected signals to avoid dangling connections.
func _disconnect_signals():
	GodotDoctorNotifier.print_debug("Disconnecting signals...")
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)

	if _editor_runner and validation_complete.is_connected(_editor_runner.reporter.on_validation_complete):
		validation_complete.disconnect(_editor_runner.reporter.on_validation_complete)


#endregion

#region Event Handlers


## Called when a scene is saved by the user; triggers validation if
## [member GodotDoctorSettings.validate_on_save] is enabled.
func _on_scene_saved(file_path: String) -> void:
	GodotDoctorNotifier.print_debug("Scene saved: %s" % file_path)
	if settings.validate_on_save:
		validate_scene_root_and_edited_resource()


#endregion


## Validation entry point for both the current scene root and edited resource.
func validate_scene_root_and_edited_resource() -> void:
	if _editor_runner == null:
		push_error("validate_scene_root_and_edited_resource called outside of editor mode.")
		return
	_editor_runner.validate_scene_root_and_edited_resource()


#region UI


## Shows the welcome dialog on first plugin enable.
func _show_welcome_dialog() -> void:
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

	EditorInterface.get_base_control().add_child(dialog)
	dialog.exclusive = false
	dialog.popup_centered()

#endregion
