## A base class for a runner that executes a set of validations for Godot Doctor.
@abstract class_name GodotDoctorRunner

## Emitted when starting collection of validation results for a set of scenes.
signal started_scene_collection

## Emitted when finishing collection of validation results for a set of scenes.
signal finished_scene_collection

## Emitted when starting collection of validation results for a set of nodes.
signal started_node_collection

## Emitted when finishing collection of validation results for a set of nodes.
signal finished_node_collection

## Emitted when starting collection of validation results for a set of resources.
signal started_resource_collection

## Emitted when finishing collection of validation results for a set of resources.
signal finished_resource_collection

## Emitted when starting validation for a scene at [param scene_res_path].
## This runs just before [GodotDoctorValidator] runs validation for a scene.
## Will [b]not[/b] be emitted if the scene fails to load, so listeners can rely
## on this signal to only receive paths of scenes that were successfully loaded.
signal started_run_for_scene_res_path(scene_res_path: String)

## Emitted when finishing validation for a scene at [param scene_res_path].
signal finished_run_for_scene_res_path(scene_res_path: String)

## Emitted when starting validation for [param resource].
signal started_run_for_resource(resource: Resource)

## Emitted when finishing validation for a resource at [param resource_res_path].
signal finished_run_for_resource(resource: Resource)

## Emitted when the entire run is complete, after all scenes and resources have been validated.
signal run_complete

## The validator responsible for running validations and collecting results for this runner.
var _validator: GodotDoctorValidator


## Initializes the runner with [param validator].
## Exits with failure if [param validator] is [code]null[/code].
func _init(validator: GodotDoctorValidator) -> void:
	if validator == null:
		push_error("Validator cannot be null.")
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return
	_validator = validator


## Kicks off the validation run for this runner.
func run() -> void:
	_run()
	run_complete.emit()


## Implements the logic for running validations for this runner.
@abstract func _run() -> void
