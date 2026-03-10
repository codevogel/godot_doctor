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

# ============================================================================
# LIFECYCLE METHODS - Plugin initialization and cleanup
# ============================================================================


## Called when the plugin enters the scene tree.
## Initializes the plugin by connecting signals and adding the dock to the editor,
## or running in CLI mode when headless.
func _enter_tree():
	_instance = self
	GodotDoctorNotifier.print_debug("Set plugin singleton")
	GodotDoctorNotifier.print_debug("Entering tree...")

	if DisplayServer.get_name() == "headless":
		if settings.run_cli_in_headless_mode:
			_cli_runner = GodotDoctorCliRunner.new(get_tree())
			_connect_signals()
			_cli_runner.run()
		return

	_editor_runner = GodotDoctorEditorRunner.new()
	_connect_signals()
	GodotDoctorNotifier.push_toast("Plugin loaded.", 0)
	GodotDoctorNotifier.print_debug("Entered tree")


## Called when the plugin is enabled by the user through Project Settings > Plugins.
## Displays a welcome dialog if configured in settings.
func _enable_plugin() -> void:
	GodotDoctorNotifier.print_debug("Enabling plugin...")

	if _editor_runner and settings.show_welcome_dialog:
		_editor_runner.show_welcome_dialog()
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


# ============================================================================
# SIGNAL MANAGEMENT - Connection and disconnection of signals
# ============================================================================


## Connects all necessary signals for the plugin to function.
func _connect_signals():
	GodotDoctorNotifier.print_debug("Connecting signals...")
	scene_saved.connect(_on_scene_saved)

	var active_reporter: ValidationReporter = (
		_cli_runner.reporter if _cli_runner else _editor_runner.reporter
	)
	validation_complete.connect(active_reporter.on_validation_complete)


## Disconnects all connected signals to avoid dangling connections.
func _disconnect_signals():
	GodotDoctorNotifier.print_debug("Disconnecting signals...")
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)

	var active_reporter: ValidationReporter = (
		_cli_runner.reporter if _cli_runner else _editor_runner.reporter if _editor_runner else null
	)
	if active_reporter and validation_complete.is_connected(active_reporter.on_validation_complete):
		validation_complete.disconnect(active_reporter.on_validation_complete)


# ============================================================================
# EVENT HANDLERS - Signal callbacks for scene saves and validation requests (editor mode only)
# ============================================================================


## Called when a scene is saved by the user.
func _on_scene_saved(file_path: String) -> void:
	GodotDoctorNotifier.print_debug("Scene saved: %s" % file_path)
	if settings.validate_on_save:
		validate_scene_root_and_edited_resource()


## Validation entry point for both the current scene root and edited resource.
## NOTE: This should not be used in headless mode; use GodotDoctorCliRunner instead.
func validate_scene_root_and_edited_resource() -> void:
	if _editor_runner == null:
		push_error("validate_scene_root_and_edited_resource called outside of editor mode.")
		return
	_editor_runner.validate_scene_root_and_edited_resource()
