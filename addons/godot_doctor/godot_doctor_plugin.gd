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

## Defines the mode in which the plugin is running: Editor or CLI (headless).
enum RunMode { NONE, EDITOR, CLI }

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

## Internal backing field for the singleton instance of the plugin.
## Use [member instance] for global access instead of using this field directly.
static var _instance: GodotDoctorPlugin = null

## A Resource that holds the settings for the Godot Doctor plugin.
var settings: GodotDoctorSettings:
	get:
		# This may be used before @onready
		# so we lazy load it here if needed.
		if not settings:
			settings = load(VALIDATOR_SETTINGS_PATH) as GodotDoctorSettings
		return settings

## The current mode in which the plugin is running, determined at runtime based on the environment.
var mode: RunMode:
	get:
		return _run_mode

## The validator responsible for executing validation logic on nodes and resources.
var _validator: GodotDoctorValidator

## The runner responsible for executing validation in the editor environment.
var _active_runner: GodotDoctorRunner
## The collector responsible for gathering validation results during a run.
var _active_collector: GodotDoctorValidationCollector
## The reporter responsible for generating reports from collected validation results.
var _active_reporter: GodotDoctorValidationReporter

## Thread that the CLI runner runs on.
var _cli_thread: Thread
## Semaphore used to signal the CLI runner thread that the editor is ready.
var _editor_ready_semaphore: Semaphore

## Internal backing field for the current mode in which the plugin is running.
var _run_mode: RunMode = RunMode.NONE

## Stores all active signal connections as [Signal, Callable] pairs for later disconnection.
var _signal_connections: Array = []

#region Plugin Lifecycle


## Called when the plugin enters the scene scene_tree.
## Initializes the plugin by connecting signals and adding the dock to the editor,
## or running in CLI mode when headless.
func _enter_tree():
	# Set the instance before any GodotDoctorNotifier calls,
	# as it needs the instance to function properly.
	_instance = self
	GodotDoctorNotifier.print_debug("Set plugin singleton", self)

	GodotDoctorNotifier.print_debug("Entering scene_tree...", self)

	# Shared initialization for any mode
	_initialize_for_any_mode()

	# Check if we're running in headless mode (CLI) and initialize accordingly.
	if DisplayServer.get_name() == "headless":
		# In headless mode, we only run if the appropriate command line argument is provided.
		if not OS.get_cmdline_user_args().has("--run-godot-doctor"):
			GodotDoctorNotifier.print_debug(
				"Skipping validation as --run-godot-doctor was not provided", self
			)
			return
		# If the argument is provided, we initialize for CLI mode and start the validation process.
		_initialize_for_cli_mode()
		# In CLI mode, we run the validation right away.
		# We run the validation in a separate thread to allow waiting for the editor to be ready.
		_cli_thread = Thread.new()
		_cli_thread.start(_active_runner.run)
		return

	# If not headless, initialize for editor mode.
	_initialize_for_editor_mode()
	# In headless mode, the runner is called through the _on_scene_saved event or
	# through validate_scene_root_and_edited_resource, so no need to call it here.
	GodotDoctorNotifier.push_toast("Plugin loaded.", 0)


## Shared initialization for any [enum RunMode].
func _initialize_for_any_mode():
	GodotDoctorNotifier.print_debug("Performing shared initialization for any mode...", self)
	GodotDoctorNotifier.print_debug("Creating Validator", self)
	_validator = GodotDoctorValidator.new()
	GodotDoctorNotifier.print_debug("Shared initialization complete.", self)


## Initialization specific to [enum RunMode.EDITOR].
func _initialize_for_editor_mode():
	_run_mode = RunMode.EDITOR
	GodotDoctorNotifier.print_debug("Running in editor mode, initializing Editor mode...", self)
	GodotDoctorNotifier.print_debug("Creating Editor Runner", self)
	_active_runner = GodotDoctorEditorRunner.new(_validator)
	GodotDoctorNotifier.print_debug("Creating Editor Reporter", self)
	_active_reporter = GodotDoctorEditorValidationReporter.new()
	GodotDoctorNotifier.print_debug("Creating Editor Collector", self)
	_active_collector = GodotDoctorEditorValidationCollector.new()
	_connect_signals()
	GodotDoctorNotifier.print_debug("Editor initialization complete.", self)


## Initialization specific to [enum RunMode.CLI].
func _initialize_for_cli_mode():
	_run_mode = RunMode.CLI
	GodotDoctorNotifier.print_debug("Running in headless, initializing CLI mode...", self)
	GodotDoctorNotifier.print_debug("Creating 'editor ready' semaphore", self)
	_editor_ready_semaphore = Semaphore.new()
	GodotDoctorNotifier.print_debug("Creating CLI Runner", self)
	_active_runner = GodotDoctorCLIRunner.new(_validator, _editor_ready_semaphore)
	GodotDoctorNotifier.print_debug("Creating CLI Reporter", self)
	_active_reporter = GodotDoctorCLIValidationReporter.new()
	GodotDoctorNotifier.print_debug("Creating CLI Collector", self)
	_active_collector = GodotDoctorCLIValidationCollector.new()
	_connect_signals()
	GodotDoctorNotifier.print_debug("CLI initialization complete.", self)


## Called when the plugin is enabled by the user through Project Settings > Plugins.
## Displays a welcome dialog if configured in settings.
func _enable_plugin() -> void:
	GodotDoctorNotifier.print_debug("Enabling plugin...", self)
	if settings.show_welcome_dialog:
		_show_welcome_dialog()
	GodotDoctorNotifier.print_debug("Plugin enabled", self)


## Called when the plugin is disabled by the user through Project Settings > Plugins.
func _disable_plugin() -> void:
	GodotDoctorNotifier.print_debug("Disabling plugin...", self)
	GodotDoctorNotifier.print_debug("Plugin disabled", self)


## Called when the plugin exits the scene scene_tree.
## Cleans up the plugin by disconnecting signals and removing the dock.
func _exit_tree():
	GodotDoctorNotifier.print_debug("Exiting scene_tree...", self)
	_teardown()

	# Clear the singleton instance as the very last action,
	# because debug prints rely on it.
	GodotDoctorNotifier.print_debug("Clearing plugin singleton", self)
	_instance = null


## Tears down the plugin by cleaning up threads, semaphores, and signal connections.
func _teardown() -> void:
	GodotDoctorNotifier.print_debug("Tearing down plugin...", self)
	if _editor_ready_semaphore != null:
		# Post in case the CLI runner was never posted.
		_editor_ready_semaphore.post()
		_editor_ready_semaphore = null
	if _cli_thread != null:
		_cli_thread.wait_to_finish()
		_cli_thread = null
	_disconnect_signals()


#endregion

#region Signal Management

#region Signal Management


## Connect a [param signal_to_connect_to] to a [param callable_to_execute]
## and track the connection for later disconnection.
func _connect_and_track(signal_to_connect_to: Signal, callable_to_execute: Callable) -> void:
	signal_to_connect_to.connect(callable_to_execute)
	_signal_connections.append([signal_to_connect_to, callable_to_execute])


## Disconnects all tracked signals in [member _signal_connections] and clears the list.
func _disconnect_all_tracked_signals() -> void:
	for conn in _signal_connections:
		var signal_to_disconnect: Signal = conn[0]
		var callable_executed_on_signal: Callable = conn[1]
		if signal_to_disconnect.is_connected(callable_executed_on_signal):
			signal_to_disconnect.disconnect(callable_executed_on_signal)
	_signal_connections.clear()


## Connects all necessary signals for the plugin to function.
func _connect_signals():
	GodotDoctorNotifier.print_debug("Connecting signals...", self)
	_connect_and_track(scene_saved, _on_scene_saved)
	_connect_runner_signals()
	_connect_validator_signals()


## Connects signals specific to the active runner.
func _connect_runner_signals():
	if _active_runner == null:
		push_error("Attempted to connect runner signals before runner was initialized.")
		quit_with_fail_early_if_headless()
		return

	GodotDoctorNotifier.print_debug("Connecting runner signals...", self)
	_connect_and_track(
		_active_runner.started_scene_collection, _active_collector.on_started_scene_collection
	)
	_connect_and_track(
		_active_runner.finished_scene_collection, _active_collector.on_finished_scene_collection
	)
	_connect_and_track(
		_active_runner.started_run_for_scene_res_path,
		_active_collector.on_started_run_for_scene_res_path
	)
	_connect_and_track(
		_active_runner.finished_run_for_scene_res_path,
		_active_collector.on_finished_run_for_scene_res_path
	)
	_connect_and_track(
		_active_runner.started_resource_collection, _active_collector.on_started_resource_collection
	)
	_connect_and_track(
		_active_runner.finished_resource_collection,
		_active_collector.on_finished_resource_collection
	)
	_connect_and_track(
		_active_runner.started_node_collection, _active_collector.on_started_node_collection
	)
	_connect_and_track(
		_active_runner.finished_node_collection, _active_collector.on_finished_node_collection
	)
	_connect_and_track(
		_active_runner.started_run_for_resource, _active_collector.on_started_run_for_resource
	)
	_connect_and_track(
		_active_runner.finished_run_for_resource, _active_collector.on_finished_run_for_resource
	)
	_connect_and_track(_active_runner.run_complete, _on_run_complete)

	match _run_mode:
		RunMode.EDITOR:
			GodotDoctorNotifier.print_debug(
				"Detected Editor Runner, connecting editor-specific signals...", self
			)
			_connect_editor_runner_signals()
		RunMode.CLI:
			GodotDoctorNotifier.print_debug(
				"Detected CLI Runner, connecting CLI-specific signals...", self
			)
			_connect_cli_runner_signals()
		_:
			push_error("Attempted to connect runner signals with unsupported run mode.")
			quit_with_fail_early_if_headless()


## Connects signals specific to the editor runner (for [RunMode.EDITOR]).
func _connect_editor_runner_signals():
	if _active_runner == null:
		push_error("Attempted to connect editor runner signals before runner was initialized.")
		return
	if not _active_runner is GodotDoctorEditorRunner:
		push_error("Attempted to connect editor runner signals with a non-editor runner.")
		return
	if not _active_reporter is GodotDoctorEditorValidationReporter:
		push_error("Attempted to connect editor runner signals with a non-editor reporter.")
		return

	var editor_runner: GodotDoctorEditorRunner = _active_runner as GodotDoctorEditorRunner
	var editor_reporter: GodotDoctorEditorValidationReporter = (
		_active_reporter as GodotDoctorEditorValidationReporter
	)
	_connect_and_track(
		editor_runner.run_for_edited_scene_root_requested,
		editor_reporter.on_run_for_edited_scene_root_requested
	)
	_connect_and_track(
		editor_runner.started_run_for_edited_scene_root,
		editor_reporter.on_started_run_for_edited_scene_root
	)
	_connect_and_track(
		editor_runner.finished_run_for_edited_scene_root,
		editor_reporter.on_finished_run_for_edited_scene_root
	)
	_connect_and_track(
		editor_runner.started_run_for_edited_resource,
		editor_reporter.on_started_run_for_edited_resource
	)
	_connect_and_track(
		editor_runner.finished_run_for_edited_resource,
		editor_reporter.on_finished_run_for_edited_resource
	)


## Connects signals specific to the CLI runner (for [RunMode.CLI]).
func _connect_cli_runner_signals():
	if _active_runner == null:
		push_error("Attempted to connect CLI runner signals before runner was initialized.")
		return
	if not _active_runner is GodotDoctorCLIRunner:
		push_error("Attempted to connect CLI runner signals with a non-CLI runner.")
		return
	if not _active_collector is GodotDoctorCLIValidationCollector:
		push_error("Attempted to connect CLI runner signals with a non-CLI collector.")
		return
	var cli_runner: GodotDoctorCLIRunner = _active_runner as GodotDoctorCLIRunner
	var cli_collector: GodotDoctorCLIValidationCollector = (
		_active_collector as GodotDoctorCLIValidationCollector
	)
	_connect_and_track(
		cli_runner.started_validation_suite_collection,
		cli_collector.on_started_validation_suite_collection
	)
	_connect_and_track(
		cli_runner.finished_validation_suite_collection,
		cli_collector.on_finished_validation_suite_collection
	)
	_connect_and_track(
		cli_runner.started_run_for_validation_suite,
		cli_collector.on_started_run_for_validation_suite
	)
	_connect_and_track(
		cli_runner.finished_run_for_validation_suite,
		cli_collector.on_finished_run_for_validation_suite
	)


## Connects signals emitted by the validator during validation runs.
func _connect_validator_signals():
	if _validator == null:
		push_error("Attempted to connect validator signals before validator was initialized.")
		quit_with_fail_early_if_headless()
		return

	GodotDoctorNotifier.print_debug("Connecting validator signals...", self)
	_connect_and_track(_validator.validated_node, _active_collector.on_validated_node)
	_connect_and_track(_validator.validated_resource, _active_collector.on_validated_resource)


## Disconnects all connected signals to avoid dangling connections.
func _disconnect_signals():
	GodotDoctorNotifier.print_debug("Disconnecting signals...", self)
	_disconnect_all_tracked_signals()


#endregion

#region Event Handlers


## Called when a scene is saved by the user; triggers validation if
## [member GodotDoctorSettings.validate_on_save] is enabled.
func _on_scene_saved(file_path: String) -> void:
	GodotDoctorNotifier.print_debug("Scene saved: %s" % file_path, self)
	if settings.validate_on_save:
		_active_runner.run()


## Called when the runner signals that the entire validation run is complete.
func _on_run_complete() -> void:
	GodotDoctorNotifier.print_debug("Validation run complete.", self)

	match _run_mode:
		RunMode.EDITOR:
			GodotDoctorNotifier.print_debug(
				"Detected editor mode, reporting results for editor...", self
			)
			_report_on_collected_results_for_editor()
		RunMode.CLI:
			GodotDoctorNotifier.print_debug("Detected CLI mode, reporting results for CLI...", self)
			var passed: bool = _report_on_collected_results_for_cli()
			quit_with_code(0 if passed else 1)
		_:
			push_error("Attempted to handle run complete with unsupported run mode.")
			quit_with_fail_early_if_headless()


## Processes the collected validation results and generates reports for editor mode.
func _report_on_collected_results_for_editor() -> void:
	if _run_mode != RunMode.EDITOR:
		push_error("Attempted to report on collected results for editor while not in editor mode.")
		quit_with_fail_early_if_headless()
		return
	GodotDoctorNotifier.print_debug("Reporting on collected results for editor...", self)

	# Assert that the active reporter and collector are
	# of the expected types for editor mode before proceeding.
	if (
		not _active_reporter is GodotDoctorEditorValidationReporter
		or not _active_collector is GodotDoctorEditorValidationCollector
	):
		push_error(
			"Attempted to report on collected results with incompatible reporter or collector types."
		)
		quit_with_fail_early_if_headless()
		return

	# Cast the active reporter and collector to their expected types for editor mode.
	var editor_reporter: GodotDoctorEditorValidationReporter = (
		_active_reporter as GodotDoctorEditorValidationReporter
	)
	var editor_collector: GodotDoctorEditorValidationCollector = (
		_active_collector as GodotDoctorEditorValidationCollector
	)

	# Report on scene validation results
	var scene_validation_collection: GodotDoctorSceneValidationCollection = (
		editor_collector.get_scene_validation_collection()
	)
	# If no scene validation collection was created,
	# the user probably didn't have a scene open, or there were no messages reported,
	# so we skip reporting on scene validation results and continue.
	if scene_validation_collection == null:
		GodotDoctorNotifier.print_debug(
			"Skipping scene validation reporting as no scene validation collection was created.",
			self
		)
	else:
		# Report on scene validation results using the editor reporter.
		editor_reporter.report_on_scene_validation_collection(scene_validation_collection)

	# Report on resource validation results
	var resource_validation_collection: GodotDoctorResourceValidationCollection = (
		editor_collector.get_resource_validation_collection()
	)
	# If no resource validation collection was created,
	# the user probably didn't have any resources open, or there were no messages reported,
	# so we skip reporting on resource validation results and continue.
	if resource_validation_collection == null:
		(
			GodotDoctorNotifier
			. print_debug(
				"Skipping resource validation reporting as no resource validation collection was created.",
				self
			)
		)
	else:
		# Report on resource validation results using the editor reporter.
		editor_reporter.report_on_resource_validation_collection(resource_validation_collection)

	# After reporting, we clear the collections to prevent duplicate collection on next run.
	editor_collector.clear_collections()


## Processes the collected validation results and generates reports for CLI mode.
## Returns [code]true[/code] if validation passed, [code]false[/code] if validation failed.
func _report_on_collected_results_for_cli() -> bool:
	if _run_mode != RunMode.CLI:
		push_error("Attempted to report on collected results for CLI while not in CLI mode.")
		quit_with_fail_early_if_headless()
		# Should already have quit here, but just in case, we
		# return false to indicate failure
		return false

	# Assert that the active reporter and collector are
	# of the expected types for CLI mode before proceeding.
	GodotDoctorNotifier.print_debug("Reporting on collected results for CLI...", self)
	if (
		not _active_reporter is GodotDoctorCLIValidationReporter
		or not _active_collector is GodotDoctorCLIValidationCollector
	):
		push_error(
			"Attempted to report on collected results with incompatible reporter or collector types."
		)
		quit_with_fail_early_if_headless()
		# Should already have quit here, but just in case, we
		# return false to indicate failure
		return false

	# Cast the active reporter and collector to their expected types for CLI mode.
	var cli_reporter: GodotDoctorCLIValidationReporter = (
		_active_reporter as GodotDoctorCLIValidationReporter
	)
	var cli_collector: GodotDoctorCLIValidationCollector = (
		_active_collector as GodotDoctorCLIValidationCollector
	)

	# Report on validation suite results using the CLI reporter.
	# This will generate a console report and an optional XML report,
	# and return whether validation passed.
	var passed: bool = cli_reporter.report_on_validation_suite_collection(
		cli_collector.get_validation_suite_collection()
	)
	# Return the result of whether validation passed,
	# which will be used to determine the process exit code.
	return passed


#endregion

#region Process Management


## Called by the editor on startup.
## We use this hook to allow the CLI runner thread
## to wait until the editor is ready before starting validation.
func _set_window_layout(_configuration: ConfigFile) -> void:
	# This is called by the editor when it's ready,
	# so we can assume that the editor is ready at this point.
	# NOTE: This is a bit of a hack;
	# This should be replaced once Godot provides a proper hook for editor startup.
	# (see: https://github.com/godotengine/godot-proposals/issues/14502 )
	if _run_mode == RunMode.CLI:
		_editor_ready_semaphore.post()


## Quits the editor with the given [param exit_code].
func quit_with_code(exit_code: int) -> void:
	if not DisplayServer.get_name() == "headless":
		push_error("quit_with_code called outside of headless mode.")
		return
	get_tree().quit(exit_code)


## Quits the editor with a failure code if running in headless mode.
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
	if _run_mode != RunMode.EDITOR:
		push_error("validate_scene_root_and_edited_resource called while not in editor mode.")
		return
	if _active_runner == null:
		push_error("validate_scene_root_and_edited_resource called outside of editor mode.")
		return
	if _active_runner is not GodotDoctorEditorRunner:
		push_error("validate_scene_root_and_edited_resource called with incompatible runner type.")
		return
	_active_runner.run()


#endregion

#region UI


## Shows the welcome dialog on first plugin enable.
func _show_welcome_dialog() -> void:
	GodotDoctorNotifier.print_debug("Showing welcome dialog...", self)
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
