## Handles the CLI (headless) validation flow.
## Creates a [GodotDoctorCLIValidationReporter] and [GodotDoctorValidator], then runs validation
## for all suites configured in [GodotDoctorSettings].
class_name GodotDoctorCliRunner

## Public getter for the [GodotDoctorValidationReporter] for this runner.
var reporter: GodotDoctorCLIValidationReporter:
	get:
		assert(_reporter != null, "GodotDoctorCLIValidationReporter is not initialized yet.")
		return _reporter

var _reporter: GodotDoctorCLIValidationReporter
var _validator: GodotDoctorValidator


func _init() -> void:
	_reporter = GodotDoctorCLIValidationReporter.new()
	_validator = GodotDoctorValidator.new(_reporter)


## Main entry point for CLI validation.
## Awaits the configured delay, validates all suites, then emits
## [GodotDoctorPlugin.validation_complete].
func run() -> void:
	var settings: GodotDoctorSettings = GodotDoctorPlugin.instance.settings
	GodotDoctorNotifier.print_debug(
		(
			"Running in CLI mode. Starting validation after configured delay (%s seconds)..."
			% settings.delay_before_running_cli
		)
	)

	# Await delay to allow the editor to
	## finish any pending operations before we start loading scenes and resources.
	await (
		GodotDoctorPlugin
		. instance
		. get_tree()
		. create_timer(settings.delay_before_running_cli)
		. timeout
	)

	for validation_suite: GodotDoctorValidationSuite in settings.validation_suites:
		_run_for_suite(validation_suite)

	GodotDoctorNotifier.print_debug("Emitting validation complete signal...")
	GodotDoctorPlugin.instance.validation_complete.emit()


## Runs validation for all scenes and resources listed in [param validation_suite].
func _run_for_suite(validation_suite: GodotDoctorValidationSuite) -> void:
	GodotDoctorNotifier.print_debug("Running validation suite: %s" % validation_suite.resource_path)
	_reporter.current_suite = validation_suite

	# For each scene path in the suite,
	for scene_path: String in validation_suite.get_scenes():
		# Resolve the scene path from a uid:// string to a filesystem path if needed,
		var uid_resolved_path: String = _resolve_uid_path(scene_path)
		_reporter.current_scene_resource_path = uid_resolved_path
		GodotDoctorNotifier.print_debug("Validating scene: %s" % uid_resolved_path)

		# Load the scene as a PackedScene and validate its root node.
		var packed_scene := load(uid_resolved_path) as PackedScene
		if packed_scene == null:
			push_error("Failed to load scene: %s" % uid_resolved_path)
			GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
			continue

		## Instantiate the scene to validate the root node
		var scene_root := packed_scene.instantiate()
		_validator.validate_scene_root(scene_root)
		## Free the instantiated scene to avoid memory leaks
		## since we're not adding it to the active scene tree.
		scene_root.free()

	# For each resource path in the suite,
	for resource_path: String in validation_suite.get_resources():
		# Load the resource and validate it.
		var resource := load(resource_path) as Resource
		_validator.validate_resource(resource)
		# Don't need to free the resource since it's RefCounted


## Resolves [param path] from a [code]uid://[/code] string to a filesystem path.
## Returns [param path] unchanged if it is already a filesystem path.
func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path
