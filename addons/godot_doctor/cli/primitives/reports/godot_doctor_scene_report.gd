## Holds all [GodotDoctorNodeReport] collected for a single scene during a CLI validation run.
class_name GodotDoctorSceneReport
extends GodotDoctorReportWithChildReports

## The filesystem path of the scene that the node reports in this scene report correspond to.
var _scene_path: String
## The [GodotDoctorNodeReport]s collected during validation of this scene.
var _node_reports: Array[GodotDoctorNodeReport]


## Initializes the report with [param _scene_path] and [param _node_reports].
func _init(scene_path: String, node_reports: Array[GodotDoctorNodeReport]) -> void:
	_scene_path = scene_path
	_node_reports = node_reports


#region Abstract Method Implementations


func get_child_reports() -> Array[GodotDoctorReport]:
	var child_reports: Array[GodotDoctorReport] = []
	for node_report: GodotDoctorNodeReport in _node_reports:
		child_reports.append(node_report)
	return child_reports


#endregion


func get_scene_path() -> String:
	return _scene_path


func get_node_reports() -> Array[GodotDoctorNodeReport]:
	return _node_reports


func add_node_report(node_report: GodotDoctorNodeReport) -> void:
	_node_reports.append(node_report)


func teardown() -> void:
	super.teardown()
	_node_reports.clear()
	_scene_path = ""
