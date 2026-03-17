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

## Handles all editor-mode setup, dock management, and validation (editor mode only).
var _editor_runner: GodotDoctorEditorRunner

## Handles all CLI validation flow (headless mode only).
var _cli_runner: GodotDoctorCliRunner

#region Plugin Lifecycle


## Called when the plugin enters the scene scene_tree.
## Initializes the plugin by connecting signals and adding the dock to the editor,
## or running in CLI mode when headless.
func _enter_tree():
	_instance = self
	GodotDoctorNotifier.print_debug("Set plugin singleton")
	GodotDoctorNotifier.print_debug("Entering scene_tree...")

	if DisplayServer.get_name() == "headless":
		if not OS.get_cmdline_user_args().has("--run-godot-doctor"):
			GodotDoctorNotifier.print_debug(
				"Skipping validation as --run-godot-doctor was not provided"
			)
			return
		GodotDoctorNotifier.print_debug("Creating CLI Runner")
		_cli_runner = GodotDoctorCliRunner.new()
		_connect_signals()
		_cli_runner.run()
		return

	GodotDoctorNotifier.print_debug("Creating Editor Runner")
	_editor_runner = GodotDoctorEditorRunner.new()
	_connect_signals()
	GodotDoctorNotifier.push_toast("Plugin loaded.", 0)
	GodotDoctorNotifier.print_debug("Entered scene_tree")


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


## Called when the plugin exits the scene scene_tree.
## Cleans up the plugin by disconnecting signals and removing the dock.
func _exit_tree():
	GodotDoctorNotifier.print_debug("Exiting scene_tree...")
	_disconnect_signals()

	if _editor_runner != null:
		_editor_runner.teardown()
		_editor_runner = null
	GodotDoctorNotifier.push_toast("Plugin unloaded.", 0)
	GodotDoctorNotifier.print_debug("Exited scene_tree")

	GodotDoctorNotifier.print_debug("Clearing plugin singleton")
	_instance = null


#endregion

#region Signal Management


## Connects all necessary signals for the plugin to function.
func _connect_signals():
	GodotDoctorNotifier.print_debug("Connecting signals...")
	scene_saved.connect(_on_scene_saved)

	var active_reporter: GodotDoctorValidationReporter = (
		_cli_runner.reporter if _cli_runner else _editor_runner.reporter
	)
	validation_complete.connect(active_reporter.on_validation_complete)


## Disconnects all connected signals to avoid dangling connections.
func _disconnect_signals():
	GodotDoctorNotifier.print_debug("Disconnecting signals...")
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)

	var active_reporter: GodotDoctorValidationReporter = (
		_cli_runner.reporter if _cli_runner else _editor_runner.reporter if _editor_runner else null
	)
	if active_reporter and validation_complete.is_connected(active_reporter.on_validation_complete):
		validation_complete.disconnect(active_reporter.on_validation_complete)


#endregion

#region Event Handlers


## Called when a scene is saved by the user; triggers validation if
## [member GodotDoctorSettings.validate_on_save] is enabled.
func _on_scene_saved(file_path: String) -> void:
	GodotDoctorNotifier.print_debug("Scene saved: %s" % file_path)
	if settings.validate_on_save:
		validate_scene_root_and_edited_resource()


#endregion

#region Process Management


func quit_with_code(exit_code: int) -> void:
	if not DisplayServer.get_name() == "headless":
		push_error("quit_with_code called outside of headless mode.")
		return
	get_tree().quit(exit_code)


func quit_with_fail_early_if_headless() -> void:
	if not DisplayServer.get_name() == "headless":
		return
	push_error("Validation failed. Exiting with code 1.")
	quit_with_code(1)


#endregion

#region External Validation Entry Point


## Validation entry point for both the current scene root and edited resource.
## Useful when you want to validate from some external trigger like an [EditorScript]
## NOTE: This should only be used in editor mode, as it relies on the editor runner.
func validate_scene_root_and_edited_resource() -> void:
	if _editor_runner == null:
		push_error("validate_scene_root_and_edited_resource called outside of editor mode.")
		return
	_editor_runner.validate_scene_root_and_edited_resource()


#endregion

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
