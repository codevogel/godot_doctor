## A [GodotDoctorValidationCollector] for CLI mode.
## Extends the base collector with support for [GodotDoctorValidationSuite] grouping,
## aggregating scene and resource results per suite into a
## [GodotDoctorValidationSuiteValidationCollection].
class_name GodotDoctorCLIValidationCollector
extends GodotDoctorValidationCollector

## The validation suite currently being processed.
var _current_validation_suite: GodotDoctorValidationSuite

## The collection aggregating results from all processed suites.
var _current_validation_suite_validation_collection: GodotDoctorValidationSuiteValidationCollection


## Called when suite collection begins; creates a new
## [GodotDoctorValidationSuiteValidationCollection].
func on_started_validation_suite_collection() -> void:
	GodotDoctorNotifier.print_debug("Creating new validation suite validation collection", self)
	_current_validation_suite_validation_collection = (
		GodotDoctorValidationSuiteValidationCollection.new()
	)


## Called when suite collection ends.
func on_finished_validation_suite_collection() -> void:
	pass


## Called when validation starts for [param validation_suite]; tracks it as the current suite.
func on_started_run_for_validation_suite(validation_suite: GodotDoctorValidationSuite) -> void:
	GodotDoctorNotifier.print_debug(
		"Setting current validation suite to %s" % validation_suite, self
	)
	_current_validation_suite = validation_suite


## Called when validation finishes for [param _validation_suite].
## Adds the accumulated scene and resource collections to the suite collection,
## then clears the per-suite intermediate collections.
func on_finished_run_for_validation_suite(_validation_suite: GodotDoctorValidationSuite) -> void:
	GodotDoctorNotifier.print_debug(
		(
			"Adding scene validation collection %s to validation suite validation collection %s"
			% [
				_current_scene_validation_collection,
				_current_validation_suite_validation_collection
			]
		),
		self
	)
	_current_validation_suite_validation_collection.add_scene_validations_collection(
		_current_validation_suite, _current_scene_validation_collection
	)

	GodotDoctorNotifier.print_debug(
		(
			"Adding resource validation collection %s to validation suite validation collection %s"
			% [
				_current_resource_validation_collection,
				_current_validation_suite_validation_collection
			]
		),
		self
	)
	_current_validation_suite_validation_collection.add_resource_validations_collection(
		_current_validation_suite, _current_resource_validation_collection
	)
	GodotDoctorNotifier.print_debug(
		(
			"Clearing current scene validation collection (was %s)"
			% _current_scene_validation_collection
		),
		self
	)
	_current_scene_validation_collection = null
	GodotDoctorNotifier.print_debug(
		(
			"Clearing current resource validation collection (was %s)"
			% _current_resource_validation_collection
		),
		self
	)
	_current_resource_validation_collection = null


## Returns the fully accumulated [GodotDoctorValidationSuiteValidationCollection].
func get_validation_suite_collection() -> GodotDoctorValidationSuiteValidationCollection:
	return _current_validation_suite_validation_collection


## Clears all collections, including the suite-level collection.
func clear_collections() -> void:
	super.clear_collections()
	GodotDoctorNotifier.print_debug("Clearing validation suite collections", self)
	_current_validation_suite = null
	_current_validation_suite_validation_collection = null
