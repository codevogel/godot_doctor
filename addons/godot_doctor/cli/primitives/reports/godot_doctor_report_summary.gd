## Aggregates validation statistics across all [GodotDoctorSuiteReport]s from a CLI run.
## Computed once from the suite reports provided to [method _init].
class_name GodotDoctorReportSummary

## The total number of suites that were validated.
var total_suite_count: int = 0
## The total number of scenes validated across all suites.
var total_scenes_validated_count: int = 0
## The total number of nodes validated across all suites.
var total_nodes_validated_count: int = 0
## The total number of messages reported with severity level
## [constant ValidationCondition.Severity.INFO] across all suites.
var total_info_messages_reported_count: int = 0
## The total number of messages reported with severity level
## [constant ValidationCondition.Severity.WARNING] across all suites.
var total_warning_messages_reported_count: int = 0
## The total number of messages reported with severity level
## [constant ValidationCondition.Severity.ERROR] across all suites.
var total_hard_error_messages_reported_count: int = 0
## The total number of messages that were originally reported with severity level
## [constant ValidationCondition.Severity.WARNING] but were promoted to errors across all suites.
var total_warning_messages_reported_as_errors_count: int = 0
## The total number of messages reported that count as errors across all suites.
var total_error_count: int = 0


## Initializes the summary by aggregating statistics from [param suite_reports].
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
