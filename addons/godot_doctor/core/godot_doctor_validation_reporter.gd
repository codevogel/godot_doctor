## Base class for reporting validation results.
## Subclass this to implement different output strategies (editor UI, CLI, JSON, etc.)
@abstract class_name GodotDoctorValidationReporter

## Reports validation results from [param scene_validation_collection].
@abstract func report_on_scene_validation_collection(
	scene_validation_collection: GodotDoctorSceneValidationCollection
) -> void

## Reports validation results from [param resource_validation_collection].
@abstract func report_on_resource_validation_collection(
	resource_validation_collection: GodotDoctorResourceValidationCollection
) -> void
