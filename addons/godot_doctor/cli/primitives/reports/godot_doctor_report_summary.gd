## Aggregates validation statistics across all [GodotDoctorSuiteReport]s from a CLI run.
## Computed once from the suite reports provided to [method _init].
class_name GodotDoctorReportSummary
extends GodotDoctorReportWithChildReports

var _suite_reports: Array[GodotDoctorSuiteReport]


func _init(suite_reports: Array[GodotDoctorSuiteReport]) -> void:
	_suite_reports = suite_reports


#region Abstract Method Implementations


func get_child_reports() -> Array[GodotDoctorReport]:
	var child_reports: Array[GodotDoctorReport] = []
	for suite_report: GodotDoctorSuiteReport in _suite_reports:
		child_reports.append(suite_report)
	return child_reports


#endregion


func get_suite_ran_count() -> int:
	return _suite_reports.size()


func get_scenes_validated_count() -> int:
	return _suite_reports.reduce(
		func(sum: int, suite_report: GodotDoctorSuiteReport):
			return sum + suite_report.get_scene_reports().size(),
		0
	)


func get_nodes_validated_count() -> int:
	var node_reports: Array[GodotDoctorNodeReport] = []
	for suite_report: GodotDoctorSuiteReport in _suite_reports:
		for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
			node_reports += scene_report.get_node_reports()
	return node_reports.size()
