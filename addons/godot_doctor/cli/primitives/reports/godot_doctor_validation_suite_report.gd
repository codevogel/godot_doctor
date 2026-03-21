## Holds validation results for a single validation suite,
## including all scene and resource reports produced during its run.
class_name GodotDoctorValidationSuiteReport
extends GodotDoctorReport

## The validation suite that was run to produce this report.
var _suite: GodotDoctorValidationSuite
## The list of scene reports produced during this suite's validation run.
var _scene_reports: Array[GodotDoctorSceneReport] = []
## The list of resource reports produced during this suite's validation run.
var _resource_reports: Array[GodotDoctorResourceReport] = []


## Creates a new [GodotDoctorValidationSuiteReport] for [param suite]
## with the given [param scene_reports] and [param resource_reports].
func _init(
	suite: GodotDoctorValidationSuite,
	scene_reports: Array[GodotDoctorSceneReport],
	resource_reports: Array[GodotDoctorResourceReport]
) -> void:
	_suite = suite
	_scene_reports = scene_reports
	_resource_reports = resource_reports


## Returns the total number of [constant ValidationCondition.Severity.INFO]-level messages
## across all scenes and resources in this suite.
func get_num_infos() -> int:
	return (
		_scene_reports.reduce(
			func(total: int, scene_report: GodotDoctorSceneReport) -> int:
				return total + scene_report.get_num_infos(),
			0
		)
		+ _resource_reports.reduce(
			func(total: int, resource_report: GodotDoctorResourceReport) -> int:
				return total + resource_report.get_num_infos(),
			0
		)
	)


## Returns the total number of [constant ValidationCondition.Severity.WARNING]-level messages
## across all scenes and resources in this suite.
func get_num_warnings() -> int:
	return (
		_scene_reports.reduce(
			func(total: int, scene_report: GodotDoctorSceneReport) -> int:
				return total + scene_report.get_num_warnings(),
			0
		)
		+ _resource_reports.reduce(
			func(total: int, resource_report: GodotDoctorResourceReport) -> int:
				return total + resource_report.get_num_warnings(),
			0
		)
	)


## Returns the total number of [constant ValidationCondition.Severity.ERROR]-level messages
## across all scenes and resources in this suite.
func get_num_errors() -> int:
	return (
		_scene_reports.reduce(
			func(total: int, scene_report: GodotDoctorSceneReport) -> int:
				return total + scene_report.get_num_errors(),
			0
		)
		+ _resource_reports.reduce(
			func(total: int, resource_report: GodotDoctorResourceReport) -> int:
				return total + resource_report.get_num_errors(),
			0
		)
	)


## Returns the total number of nodes validated across all scenes in this suite.
func get_num_nodes() -> int:
	return _scene_reports.reduce(
		func(total: int, scene_report: GodotDoctorSceneReport) -> int:
			return total + scene_report.get_node_reports().size(),
		0
	)


## Returns the total number of resources validated in this suite.
func get_num_resources() -> int:
	return _resource_reports.size()


## Returns all validation messages across all scenes and resources in this suite.
func get_validation_messages() -> Array[GodotDoctorValidationMessage]:
	var validation_messages: Array[GodotDoctorValidationMessage] = []

	for scene_report in _scene_reports:
		validation_messages += scene_report.get_validation_messages()

	for resource_report in _resource_reports:
		validation_messages += resource_report.get_validation_messages()

	return validation_messages


## Returns the resource path of the validation suite script.
func get_suite_resource_path() -> String:
	return _suite.resource_path


## Returns the validation suite that was run to produce this report.
func get_suite() -> GodotDoctorValidationSuite:
	return _suite


## Returns all scene reports in this suite.
func get_scene_reports() -> Array[GodotDoctorSceneReport]:
	return _scene_reports


## Returns all resource reports in this suite.
func get_resource_reports() -> Array[GodotDoctorResourceReport]:
	return _resource_reports
