class_name GodotDoctorReportSummary

var total_suite_count: int = 0
var total_scenes_validated_count: int = 0
var total_nodes_validated_count: int = 0
var total_info_messages_reported_count: int = 0
var total_warning_messages_reported_count: int = 0
var total_hard_error_messages_reported_count: int = 0
var total_warning_messages_reported_as_errors_count: int = 0
var total_error_count: int = 0


func _init(suite_reports: Array[GodotDoctorSuiteReport]) -> void:
	total_suite_count = suite_reports.size()

	for suite_report: GodotDoctorSuiteReport in suite_reports:
		total_scenes_validated_count += suite_report.get_scenes_validated_count()
		total_nodes_validated_count += suite_report.get_nodes_validated_count()
		total_info_messages_reported_count += suite_report.get_info_messages_count()
		total_warning_messages_reported_count += suite_report.get_warning_messages_count()
		total_hard_error_messages_reported_count += suite_report.get_hard_error_messages_count()
		total_warning_messages_reported_as_errors_count += (
			suite_report.get_warning_messages_as_errors_count()
		)
		total_error_count += suite_report.get_error_count()
