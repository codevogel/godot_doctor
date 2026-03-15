## Exports CLI validation results as a JUnit-style XML report.
class_name GodotDoctorJUnitXmlReportExporter
extends RefCounted

const _DEFAULT_XML_REPORT_FILENAME: String = "godot_doctor_report.xml"


## Exports a JUnit-style XML report if enabled in [param settings].
func export_report(summary: GodotDoctorReportSummary) -> void:
	var settings: GodotDoctorSettings = GodotDoctorPlugin.instance.settings

	if settings.xml_report_output_dir.is_empty():
		push_error("XML report output directory is empty.")
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return

	var output_dir: String = settings.xml_report_output_dir
	if not output_dir.ends_with("/"):
		output_dir += "/"

	if not _ensure_directory_exists(output_dir):
		return

	var file_name: String = settings.xml_report_filename
	if file_name.is_empty():
		file_name = _DEFAULT_XML_REPORT_FILENAME

	var output_path: String = output_dir.path_join(file_name)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open XML report file for writing: %s" % output_path)
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return

	file.store_string(_build_junit_xml_report(summary))
	file.close()
	GodotDoctorNotifier.print_debug("Wrote XML report to: %s" % output_path)


func _ensure_directory_exists(dir_path: String) -> bool:
	var absolute_dir_path: String = ProjectSettings.globalize_path(dir_path)
	if DirAccess.dir_exists_absolute(absolute_dir_path):
		return true

	var err: Error = DirAccess.make_dir_recursive_absolute(absolute_dir_path)
	if err != OK:
		push_error("Failed to create XML report directory '%s' (%s)." % [dir_path, err])
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return false

	return true


func _build_junit_xml_report(summary: GodotDoctorReportSummary) -> String:
	var timestamp: String = Time.get_datetime_string_from_system(false, false)
	var lines: Array[String] = []

	lines.append('<?xml version="1.0" encoding="UTF-8"?>')
	(
		lines
		. append(
			(
				'<testsuites disabled="0" errors="%d" failures="%d" name="GodotDoctor" tests="%d">'
				% [
					summary.get_hard_error_messages_count(),
					summary.get_warnings_treated_as_errors_count(),
					_get_total_testcase_count(summary),
				]
			)
		)
	)

	var suite_reports: Array[GodotDoctorSuiteReport] = summary.get_suite_reports()
	for i: int in range(suite_reports.size()):
		lines.append(_build_testsuite_xml(suite_reports[i], i, timestamp))

	lines.append("</testsuites>")
	return "\n".join(lines)


func _build_testsuite_xml(
	suite_report: GodotDoctorSuiteReport, suite_id: int, timestamp: String
) -> String:
	var suite_name: String = _xml_escape(_resolve_uid_path(suite_report.get_suite().resource_path))
	var test_count: int = _get_suite_testcase_count(suite_report)
	var errors_count: int = suite_report.get_hard_error_messages_count()
	var failures_count: int = suite_report.get_warnings_treated_as_errors_count()
	var lines: Array[String] = []

	(
		lines
		. append(
			(
				'  <testsuite name="%s" tests="%d" disabled="0" errors="%d" failures="%d" hostname="localhost" id="%d" skipped="0" timestamp="%s">'
				% [
					suite_name,
					test_count,
					errors_count,
					failures_count,
					suite_id,
					_xml_escape(timestamp)
				]
			)
		)
	)

	for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
		for node_report: GodotDoctorNodeReport in scene_report.get_node_reports():
			lines.append(
				_build_testcase_xml(
					node_report.get_node_ancestor_path(),
					suite_name,
					node_report.get_messages(),
					suite_report.get_suite().treat_warnings_as_errors
				)
			)

	for resource_report: GodotDoctorResourceReport in suite_report.get_resource_reports():
		lines.append(
			_build_testcase_xml(
				_resolve_uid_path(resource_report.get_resource().resource_path),
				suite_name,
				resource_report.get_messages(),
				suite_report.get_suite().treat_warnings_as_errors
			)
		)

	lines.append("  </testsuite>")
	return "\n".join(lines)


func _build_testcase_xml(
	test_name: String,
	class_name_value: String,
	messages: Array[GodotDoctorValidationMessage],
	treat_warnings_as_errors: bool
) -> String:
	var safe_test_name: String = _xml_escape(test_name)
	var safe_class_name: String = _xml_escape(class_name_value)
	var test_case_open: String = (
		'    <testcase name="%s" classname="%s">' % [safe_test_name, safe_class_name]
	)

	var hard_errors: Array[GodotDoctorValidationMessage] = _filter_messages_by_severity(
		messages, ValidationCondition.Severity.ERROR
	)
	if not hard_errors.is_empty():
		var combined_error_text: String = _combine_message_texts(hard_errors)
		return (
			"\n"
			. join(
				[
					test_case_open,
					(
						'      <error message="%s" type="ValidationError">%s</error>'
						% [_xml_escape(combined_error_text), _xml_escape(combined_error_text)]
					),
					"    </testcase>",
				]
			)
		)

	if treat_warnings_as_errors:
		var warnings: Array[GodotDoctorValidationMessage] = _filter_messages_by_severity(
			messages, ValidationCondition.Severity.WARNING
		)
		if not warnings.is_empty():
			var combined_warning_text: String = _combine_message_texts(warnings)
			return (
				"\n"
				. join(
					[
						test_case_open,
						(
							'      <failure message="%s" type="WarningPromotedToError">%s</failure>'
							% [
								_xml_escape(combined_warning_text),
								_xml_escape(combined_warning_text)
							]
						),
						"    </testcase>",
					]
				)
			)

	return '    <testcase name="%s" classname="%s"/>' % [safe_test_name, safe_class_name]


func _filter_messages_by_severity(
	messages: Array[GodotDoctorValidationMessage], severity: ValidationCondition.Severity
) -> Array[GodotDoctorValidationMessage]:
	return messages.filter(
		func(msg: GodotDoctorValidationMessage) -> bool: return msg.severity_level == severity
	)


func _combine_message_texts(messages: Array[GodotDoctorValidationMessage]) -> String:
	var message_texts: Array[String] = []
	for message: GodotDoctorValidationMessage in messages:
		message_texts.append(message.message)
	return "\n".join(message_texts)


func _get_total_testcase_count(summary: GodotDoctorReportSummary) -> int:
	return summary.get_suite_reports().reduce(
		func(sum: int, suite_report: GodotDoctorSuiteReport):
			return sum + _get_suite_testcase_count(suite_report),
		0
	)


func _get_suite_testcase_count(suite_report: GodotDoctorSuiteReport) -> int:
	var node_count: int = 0
	for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
		node_count += scene_report.get_node_reports().size()

	return node_count + suite_report.get_resource_reports().size()


func _xml_escape(value: String) -> String:
	return (
		value
		. replace("&", "&amp;")
		. replace('"', "&quot;")
		. replace("'", "&apos;")
		. replace("<", "&lt;")
		. replace(">", "&gt;")
	)


func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path
