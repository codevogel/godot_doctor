## Handles the CLI (headless) validation flow.
## Creates a GodotDoctorCLIValidationReporter and GodotDoctorValidator, then runs validation
## for all suites configured in GodotDoctorSettings.
class_name GodotDoctorCliRunner

var reporter: GodotDoctorCLIValidationReporter
var validator: GodotDoctorValidator

var _scene_tree: SceneTree


func _init(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree
	reporter = GodotDoctorCLIValidationReporter.new(scene_tree)
	validator = GodotDoctorValidator.new(reporter)


# ============================================================================
# CLI FLOW - Entry point and per-suite execution
# ============================================================================


## Main entry point for CLI validation.
## Awaits the configured delay, validates all suites, then emits validation_complete.
## NOTE: This method uses await; call without awaiting to fire-and-forget.
func run() -> void:
	var settings: GodotDoctorSettings = GodotDoctorPlugin.instance.settings
	GodotDoctorNotifier.print_debug(
		(
			"Running in CLI mode. Starting validation after configured delay (%s seconds)..."
			% settings.delay_before_running_cli
		)
	)
	await _scene_tree.create_timer(settings.delay_before_running_cli).timeout

	for validation_suite: GodotDoctorValidationSuite in settings.validation_suites:
		_run_for_suite(validation_suite)

	GodotDoctorNotifier.print_debug("Emitting validation complete signal...")
	GodotDoctorPlugin.instance.validation_complete.emit()


## Runs validation for a given validation suite.
## Loads and instantiates each scene directly without opening it in the editor.
func _run_for_suite(validation_suite: GodotDoctorValidationSuite) -> void:
	GodotDoctorNotifier.print_debug("Running validation suite: %s" % validation_suite.resource_path)
	reporter.current_suite = validation_suite

	for scene_path: String in validation_suite.scenes:
		var uid_resolved_path: String = _resolve_uid_path(scene_path)
		reporter.current_scene_path = uid_resolved_path
		GodotDoctorNotifier.print_debug("Validating scene: %s" % uid_resolved_path)

		var packed_scene := load(uid_resolved_path) as PackedScene
		if packed_scene == null:
			push_error("Failed to load scene: %s" % uid_resolved_path)
			continue

		var scene_root := packed_scene.instantiate()
		validator.validate_scene_root(scene_root)
		scene_root.free()

	for resource_path: String in validation_suite.resources:
		var resource := load(resource_path) as Resource
		validator.validate_resource(resource)


func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path
