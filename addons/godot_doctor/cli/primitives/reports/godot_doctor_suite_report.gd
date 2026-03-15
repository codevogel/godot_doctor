## Holds all [GodotDoctorSceneReport] and [GodotDoctorResourceReport] collected for
## a single validation _suite during a CLI validation run.
class_name GodotDoctorSuiteReport
extends GodotDoctorReportWithChildReports

## The [GodotDoctorValidationSuite] this report belongs to.
var _suite: GodotDoctorValidationSuite
## The [GodotDoctorSceneReport]s collected during validation of this _suite.
var _scene_reports: Array[GodotDoctorSceneReport]
## The [GodotDoctorResourceReport]s collected during validation of this _suite.
var _resource_reports: Array[GodotDoctorResourceReport]


## Initializes the report with [param suite], [param scene_reports], and [param resource_reports].
func _init(
	suite: GodotDoctorValidationSuite,
	scene_reports: Array[GodotDoctorSceneReport],
	resource_reports: Array[GodotDoctorResourceReport]
) -> void:
	self._suite = suite
	self._scene_reports = scene_reports
	self._resource_reports = resource_reports


func get_suite() -> GodotDoctorValidationSuite:
	return _suite


#region Abstract Method Implementations


func get_child_reports() -> Array[GodotDoctorReport]:
	var combined: Array = []
	combined.append_array(_scene_reports)
	combined.append_array(_resource_reports)
	return _collect_child_reports_from(combined)


#endregion


func add_scene_report(scene_report: GodotDoctorSceneReport) -> void:
	_scene_reports.append(scene_report)


func add_resource_report(resource_report: GodotDoctorResourceReport) -> void:
	_resource_reports.append(resource_report)


func get_scene_reports() -> Array[GodotDoctorSceneReport]:
	return _scene_reports


func get_resource_reports() -> Array[GodotDoctorResourceReport]:
	return _resource_reports


## Gets the total number of node reports validated in this suite.
func get_nodes_validated_count() -> int:
	return _scene_reports.reduce(
		func(sum: int, scene_report: GodotDoctorSceneReport):
			return sum + scene_report.get_node_reports().size(),
		0
	)


## Gets the total number of resource reports validated in this suite.
func get_resources_validated_count() -> int:
	return _resource_reports.size()


## Gets the total number of validated items (nodes + resources) in this suite.
func get_validated_items_count() -> int:
	return get_nodes_validated_count() + get_resources_validated_count()


func teardown() -> void:
	super.teardown()
	_scene_reports.clear()
	_resource_reports.clear()
	_suite = null
