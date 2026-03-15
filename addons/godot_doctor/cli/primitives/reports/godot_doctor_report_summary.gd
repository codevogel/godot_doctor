## Aggregates validation statistics across all [GodotDoctorSuiteReport]s from a CLI run.
## Computed once from the suite reports provided to [method _init].
class_name GodotDoctorReportSummary
extends GodotDoctorReportWithChildReports

var _suite_reports: Array[GodotDoctorSuiteReport]


func _init(suite_reports: Array[GodotDoctorSuiteReport]) -> void:
	_suite_reports = suite_reports


#region Abstract Method Implementations


func get_child_reports() -> Array[GodotDoctorReport]:
	return _collect_child_reports_from(_suite_reports)


#endregion


## Gets all suite reports included in this summary.
func get_suite_reports() -> Array[GodotDoctorSuiteReport]:
	return _suite_reports


## Gets the total number of validation suites that were run during the CLI validation run.
func get_suite_ran_count() -> int:
	return _suite_reports.size()


## Gets the total number of scenes that were validated during the CLI validation run.
func get_scenes_validated_count() -> int:
	return _suite_reports.reduce(
		func(sum: int, suite_report: GodotDoctorSuiteReport):
			return sum + suite_report.get_scene_reports().size(),
		0
	)


## Gets the total number of nodes that were validated during the CLI validation run.
func get_nodes_validated_count() -> int:
	return _suite_reports.reduce(
		func(sum: int, suite_report: GodotDoctorSuiteReport):
			return sum + suite_report.get_nodes_validated_count(),
		0
	)


## Gets the total number of resources that were validated during the CLI validation run.
func get_resources_validated_count() -> int:
	return _suite_reports.reduce(
		func(sum: int, suite_report: GodotDoctorSuiteReport):
			return sum + suite_report.get_resources_validated_count(),
		0
	)


## Gets the total number of validated items (nodes + resources) in this run.
func get_validated_items_count() -> int:
	return get_nodes_validated_count() + get_resources_validated_count()
