## A [GodotDoctorRunner] for headless / CLI mode.
## Iterates over all [GodotDoctorValidationSuite] instances defined in
## [member GodotDoctorSettings.validation_suites] and validates their scenes and resources.
class_name GodotDoctorCLIRunner
extends GodotDoctorRunner

## Emitted when starting collection of results across all validation suites.
signal started_validation_suite_collection
## Emitted when finishing collection of results across all validation suites.
signal finished_validation_suite_collection

## Emitted when starting validation for [param suite].
signal started_run_for_validation_suite(suite: GodotDoctorValidationSuite)
## Emitted when finishing validation for [param suite].
signal finished_run_for_validation_suite(suite: GodotDoctorValidationSuite)


## Runs all validation suites.
func _run() -> void:
	_run_for_suites()


## Iterates over all configured validation suites and runs each one.
func _run_for_suites() -> void:
	var settings: GodotDoctorSettings = GodotDoctorPlugin.instance.settings
	var suites_to_validate: Array[GodotDoctorValidationSuite] = settings.validation_suites

	GodotDoctorNotifier.print_debug("Found %d suites to run." % suites_to_validate.size(), self)
	started_validation_suite_collection.emit()
	for validation_suite: GodotDoctorValidationSuite in suites_to_validate:
		_run_for_suite(validation_suite)
	finished_validation_suite_collection.emit()
	GodotDoctorNotifier.print_debug("Ran all suites.", self)


## Runs validation for all scenes and resources listed in [param validation_suite].
func _run_for_suite(validation_suite: GodotDoctorValidationSuite) -> void:
	GodotDoctorNotifier.print_debug(
		"Running validation suite: %s" % validation_suite.resource_path, self
	)
	started_run_for_validation_suite.emit(validation_suite)

	started_scene_collection.emit()
	_run_for_scenes_in_suite(validation_suite)
	finished_scene_collection.emit()
	started_resource_collection.emit()
	_run_for_resources_in_suite(validation_suite)
	finished_resource_collection.emit()

	finished_run_for_validation_suite.emit(validation_suite)


## Runs validation for all scenes listed in [param validation_suite].
func _run_for_scenes_in_suite(validation_suite: GodotDoctorValidationSuite) -> void:
	for scene_path: String in validation_suite.get_scenes():
		_run_for_scene_path(scene_path)


## Runs validation for the scene at [param res_or_uid_scene_path].
func _run_for_scene_path(res_or_uid_scene_path: String) -> void:
	GodotDoctorNotifier.print_debug("Attempting to load scene: %s" % res_or_uid_scene_path, self)
	# Load the scene as a PackedScene and validate its root node.
	var packed_scene := load(res_or_uid_scene_path) as PackedScene
	if packed_scene == null:
		push_error("Failed to load scene: %s" % res_or_uid_scene_path)
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return
	GodotDoctorNotifier.print_debug("Successfully loaded scene: %s" % res_or_uid_scene_path, self)

	## Instantiate it so we can run for the root node of the scene.
	var scene_root: Node = packed_scene.instantiate()

	var scene_res_path: String = GodotDoctorResourceHelper.to_res_path(scene_root.scene_file_path)

	# Now that the scene is Successfully loaded, we can emit the started signal.
	started_run_for_scene_res_path.emit(scene_res_path)

	started_node_collection.emit()

	_validator.validate_scene_root(scene_root)

	finished_node_collection.emit()
	## Free the instantiated scene to avoid memory leaks
	## since we're not adding it to the active scene tree.
	scene_root.free()

	finished_run_for_scene_res_path.emit(scene_res_path)


## Runs validation for all resources listed in [param validation_suite].
func _run_for_resources_in_suite(validation_suite: GodotDoctorValidationSuite) -> void:
	for resource_path: String in validation_suite.get_resources():
		_run_for_resource_path(resource_path)


## Runs validation for the resource at [param resource_res_or_uid_path].
func _run_for_resource_path(resource_res_or_uid_path: String) -> void:
	# Load the resource and validate it.
	var resource := load(resource_res_or_uid_path) as Resource
	if resource == null:
		push_error("Failed to load resource: %s" % resource_res_or_uid_path)
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return
	GodotDoctorNotifier.print_debug(
		"Successfully loaded resource: %s" % resource_res_or_uid_path, self
	)

	# Now that the resource is Successfully loaded, we can emit the started signal.
	var resource_res_path: String = GodotDoctorResourceHelper.to_res_path(resource_res_or_uid_path)
	started_run_for_resource.emit(resource)

	_validator.validate_resource(resource)
	# Don't need to free the resource since it's RefCounted

	finished_run_for_resource.emit(resource)
