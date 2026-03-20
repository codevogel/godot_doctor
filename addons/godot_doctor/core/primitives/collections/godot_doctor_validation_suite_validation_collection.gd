## A collection mapping [GodotDoctorValidationSuite] instances to their scene and resource
## validation collections. Used by [GodotDoctorCLIValidationCollector] to aggregate
## results across all suites during a CLI validation run.
class_name GodotDoctorValidationSuiteValidationCollection
extends GodotDoctorValidationCollection

## A dictionary mapping each [GodotDoctorValidationSuite] to its
## [GodotDoctorSceneValidationCollection].
var _validation_suite_to_scene_validation_collection_map: Dictionary = {}

## A dictionary mapping each [GodotDoctorValidationSuite] to its
## [GodotDoctorResourceValidationCollection].
var _validation_suite_to_resource_validation_collection_map: Dictionary = {}


## Adds [param scene_validation_collection] for [param validation_suite] to this collection.
## Fails if [param validation_suite] already has a scene validation collection.
func add_scene_validations_collection(
	validation_suite: GodotDoctorValidationSuite,
	scene_validation_collection: GodotDoctorSceneValidationCollection
) -> void:
	_add_and_fail_if_already_has(
		validation_suite,
		scene_validation_collection,
		_validation_suite_to_scene_validation_collection_map
	)


## Adds [param resource_validation_collection] for [param validation_suite] to this collection.
## Fails if [param validation_suite] already has a resource validation collection.
func add_resource_validations_collection(
	validation_suite: GodotDoctorValidationSuite,
	resource_validation_collection: GodotDoctorResourceValidationCollection
) -> void:
	_add_and_fail_if_already_has(
		validation_suite,
		resource_validation_collection,
		_validation_suite_to_resource_validation_collection_map
	)


## Returns the map of [GodotDoctorValidationSuite] instances to their
## [GodotDoctorSceneValidationCollection]s.
func get_validation_suite_to_scene_validation_collection_map() -> Dictionary:
	return _validation_suite_to_scene_validation_collection_map


## Returns the map of [GodotDoctorValidationSuite] instances to their
## [GodotDoctorResourceValidationCollection]s.
func get_validation_suite_to_resource_validation_collection_map() -> Dictionary:
	return _validation_suite_to_resource_validation_collection_map
