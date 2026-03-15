@abstract class_name GodotDoctorReportWithChildReports
extends GodotDoctorReport

## Gets all reports that are contained in this report.
@abstract func get_child_reports() -> Array[GodotDoctorReport]


func teardown() -> void:
	for child_report: GodotDoctorReport in get_child_reports():
		child_report.teardown()
	super.teardown()


#region Abstract Method Implementations


func _collect_messages() -> Array[GodotDoctorValidationMessage]:
	var messages: Array[GodotDoctorValidationMessage] = []
	for child_report: GodotDoctorReport in get_child_reports():
		messages += child_report.get_messages()
	return messages


func get_effective_error_count() -> int:
	return get_child_reports().reduce(
		func(sum: int, child_report: GodotDoctorReport):
			return sum + child_report.get_effective_error_count(),
		0
	)


func get_warnings_treated_as_errors_count() -> int:
	return get_child_reports().reduce(
		func(sum: int, child_report: GodotDoctorReport):
			return sum + child_report.get_warnings_treated_as_errors_count(),
		0
	)

#endregion
