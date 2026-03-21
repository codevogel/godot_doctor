## Holds validation results for a single scene, aggregated from its node reports.
class_name GodotDoctorSceneReport
extends GodotDoctorReport

## The resource path of the validated scene.
var _scene_path: String
## The list of node reports for all validated nodes within this scene.
var _node_reports: Array[GodotDoctorNodeReport] = []


## Creates a new [GodotDoctorSceneReport] for the scene at [param scene_path]
## with the given [param node_reports].
func _init(scene_path: String, node_reports: Array[GodotDoctorNodeReport]) -> void:
	_scene_path = scene_path
	_node_reports = node_reports


## Returns the total number of [constant ValidationCondition.Severity.INFO]-level validation
## messages across all nodes in this scene.
func get_num_infos() -> int:
	return _node_reports.reduce(
		func(total: int, node_report: GodotDoctorNodeReport) -> int:
			return total + node_report.get_num_infos(),
		0
	)


## Returns the total number of [constant ValidationCondition.Severity.WARNING]-level validation
## messages across all nodes in this scene.
func get_num_warnings() -> int:
	return _node_reports.reduce(
		func(total: int, node_report: GodotDoctorNodeReport) -> int:
			return total + node_report.get_num_warnings(),
		0
	)


## Returns the total number of [constant ValidationCondition.Severity.ERROR]-level validation
## messages across all nodes in this scene.
func get_num_errors() -> int:
	return _node_reports.reduce(
		func(total: int, node_report: GodotDoctorNodeReport) -> int:
			return total + node_report.get_num_errors(),
		0
	)


## Returns all validation messages across all nodes in this scene.
func get_validation_messages() -> Array[GodotDoctorValidationMessage]:
	var validation_messages: Array[GodotDoctorValidationMessage] = []
	for node_report in _node_reports:
		validation_messages += node_report.get_validation_messages()

	return validation_messages


## Returns all node reports within this scene.
func get_node_reports() -> Array[GodotDoctorNodeReport]:
	return _node_reports


## Returns the resource path of this scene.
func get_scene_path() -> String:
	return _scene_path
