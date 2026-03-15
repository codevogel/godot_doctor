## Exports CLI validation results as a JUnit-style XML report.
class_name GodotDoctorJUnitXmlReportExporter
extends RefCounted

const _DEFAULT_XML_REPORT_FILENAME: String = "godot_doctor_report.xml"
const _INDENT_SIZE: int = 2
const _INDENT_LEVEL_TESTSUITE: int = 1
const _INDENT_LEVEL_TESTCASE: int = 2
const _INDENT_LEVEL_TEST_ITEM: int = 3
const _INDENT_LEVEL_MESSAGE: int = 4
const _RESOURCE_TESTS_COUNT: int = 1


func _indent(level: int) -> String:
	return " ".repeat(_INDENT_SIZE).repeat(level)


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
				(
					'<testsuites tests="%d" messages="%d" failures="%d" harderrors="%d" '
					+ 'warnings="%d" infos="%d" timestamp="%s">'
				)
				% [
					summary.get_validated_items_count(),
					summary.get_messages().size(),
					summary.get_effective_error_count(),
					summary.get_hard_error_messages_count(),
					summary.get_warning_messages_count(),
					summary.get_info_messages_count(),
					_xml_escape(timestamp),
				]
			)
		)
	)

	var suite_reports: Array[GodotDoctorSuiteReport] = summary.get_suite_reports()
	for i: int in range(suite_reports.size()):
		lines.append(_build_testsuite_xml(suite_reports[i]))

	lines.append("</testsuites>")
	return "\n".join(lines)


func _build_testsuite_xml(suite_report: GodotDoctorSuiteReport) -> String:
	var suite_path: String = _resolve_uid_path(suite_report.get_suite().resource_path)
	var suite_name: String = _xml_escape(_basename(suite_path))
	var suite_path_escaped: String = _xml_escape(suite_path)
	var lines: Array[String] = []

	(
		lines
		. append(
			(
				(
					'%s<testsuite name="%s" path="%s" tests="%d" messages="%d" '
					+ 'failures="%d" harderrors="%d" warnings="%d" infos="%d">'
				)
				% [
					_indent(_INDENT_LEVEL_TESTSUITE),
					suite_name,
					suite_path_escaped,
					suite_report.get_validated_items_count(),
					suite_report.get_messages().size(),
					suite_report.get_effective_error_count(),
					suite_report.get_hard_error_messages_count(),
					suite_report.get_warning_messages_count(),
					suite_report.get_info_messages_count(),
				]
			)
		)
	)

	for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
		lines.append(_build_scene_testcase_xml(scene_report, suite_report))

	for resource_report: GodotDoctorResourceReport in suite_report.get_resource_reports():
		lines.append(_build_resource_testcase_xml(resource_report, suite_report))

	lines.append("%s</testsuite>" % _indent(_INDENT_LEVEL_TESTSUITE))
	return "\n".join(lines)


func _build_scene_testcase_xml(
	scene_report: GodotDoctorSceneReport, suite_report: GodotDoctorSuiteReport
) -> String:
	var scene_path: String = scene_report.get_scene_path()
	var testcase_name: String = _xml_escape(_basename(scene_path))
	var testcase_path: String = _xml_escape(scene_path)
	var treat_warnings_as_errors: bool = suite_report.get_suite().treat_warnings_as_errors
	var node_reports: Array[GodotDoctorNodeReport] = scene_report.get_node_reports()
	var lines: Array[String] = []

	(
		lines
		. append(
			(
				(
					'%s<testcase name="%s" path="%s" type="scene" tests="%d" '
					+ 'messages="%d" failures="%d" harderrors="%d" warnings="%d" infos="%d">'
				)
				% [
					_indent(_INDENT_LEVEL_TESTCASE),
					testcase_name,
					testcase_path,
					scene_report.get_node_reports().size(),
					scene_report.get_messages().size(),
					scene_report.get_effective_error_count(),
					scene_report.get_hard_error_messages_count(),
					scene_report.get_warning_messages_count(),
					scene_report.get_info_messages_count(),
				]
			)
		)
	)

	for node_report: GodotDoctorNodeReport in node_reports:
		if node_report.get_messages().is_empty():
			continue
		lines.append(_build_node_xml(node_report, treat_warnings_as_errors))

	lines.append("%s</testcase>" % _indent(_INDENT_LEVEL_TESTCASE))
	return "\n".join(lines)


func _build_resource_testcase_xml(
	resource_report: GodotDoctorResourceReport, suite_report: GodotDoctorSuiteReport
) -> String:
	var resource_path: String = _resolve_uid_path(resource_report.get_resource().resource_path)
	var testcase_name: String = _xml_escape(_basename(resource_path))
	var testcase_path: String = _xml_escape(resource_path)
	var treat_warnings_as_errors: bool = suite_report.get_suite().treat_warnings_as_errors
	var lines: Array[String] = []

	(
		lines
		. append(
			(
				(
					'%s<testcase name="%s" path="%s" type="resource" tests="%d" '
					+ 'messages="%d" failures="%d" harderrors="%d" warnings="%d" infos="%d">'
				)
				% [
					_indent(_INDENT_LEVEL_TESTCASE),
					testcase_name,
					testcase_path,
					_RESOURCE_TESTS_COUNT,
					resource_report.get_messages().size(),
					resource_report.get_effective_error_count(),
					resource_report.get_hard_error_messages_count(),
					resource_report.get_warning_messages_count(),
					resource_report.get_info_messages_count(),
				]
			)
		)
	)

	lines.append(_build_resource_xml(resource_report, treat_warnings_as_errors, resource_path))

	lines.append("%s</testcase>" % _indent(_INDENT_LEVEL_TESTCASE))
	return "\n".join(lines)


func _build_node_xml(node_report: GodotDoctorNodeReport, treat_warnings_as_errors: bool) -> String:
	var node_name: String = _xml_escape(node_report.get_node_name())
	var node_path: String = _xml_escape(node_report.get_node_ancestor_path())
	var lines: Array[String] = []

	(
		lines
		. append(
			(
				(
					'%s<node name="%s" path="%s" messages="%d" failures="%d" '
					+ 'harderrors="%d" warnings="%d" infos="%d">'
				)
				% [
					_indent(_INDENT_LEVEL_TEST_ITEM),
					node_name,
					node_path,
					node_report.get_messages().size(),
					node_report.get_effective_error_count(),
					node_report.get_hard_error_messages_count(),
					node_report.get_warning_messages_count(),
					node_report.get_info_messages_count(),
				]
			)
		)
	)

	for message: GodotDoctorValidationMessage in node_report.get_messages():
		lines.append(_build_message_xml(message, treat_warnings_as_errors))

	lines.append("%s</node>" % _indent(_INDENT_LEVEL_TEST_ITEM))
	return "\n".join(lines)


func _build_resource_xml(
	resource_report: GodotDoctorResourceReport,
	treat_warnings_as_errors: bool,
	resource_path: String
) -> String:
	var resource_name: String = _xml_escape(_basename(resource_path))
	var resource_path_escaped: String = _xml_escape(resource_path)
	var lines: Array[String] = []

	(
		lines
		. append(
			(
				(
					'%s<resource name="%s" path="%s" messages="%d" failures="%d" '
					+ 'harderrors="%d" warnings="%d" infos="%d">'
				)
				% [
					_indent(_INDENT_LEVEL_TEST_ITEM),
					resource_name,
					resource_path_escaped,
					resource_report.get_messages().size(),
					resource_report.get_effective_error_count(),
					resource_report.get_hard_error_messages_count(),
					resource_report.get_warning_messages_count(),
					resource_report.get_info_messages_count(),
				]
			)
		)
	)

	for message: GodotDoctorValidationMessage in resource_report.get_messages():
		lines.append(_build_message_xml(message, treat_warnings_as_errors))

	lines.append("%s</resource>" % _indent(_INDENT_LEVEL_TEST_ITEM))
	return "\n".join(lines)


func _build_message_xml(
	message: GodotDoctorValidationMessage, treat_warnings_as_errors: bool
) -> String:
	var safe_message: String = _xml_escape(message.message)

	match message.severity_level:
		ValidationCondition.Severity.ERROR:
			return "%s<harderror>%s</harderror>" % [_indent(_INDENT_LEVEL_MESSAGE), safe_message]
		ValidationCondition.Severity.WARNING:
			var promoted_attribute: String = (
				' type="promoted_to_error"' if treat_warnings_as_errors else ""
			)
			return (
				"%s<warning%s>%s</warning>"
				% [_indent(_INDENT_LEVEL_MESSAGE), promoted_attribute, safe_message]
			)
		ValidationCondition.Severity.INFO:
			return "%s<info>%s</info>" % [_indent(_INDENT_LEVEL_MESSAGE), safe_message]

	return "%s<info>%s</info>" % [_indent(_INDENT_LEVEL_MESSAGE), safe_message]


func _basename(path: String) -> String:
	return path.get_file()


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
