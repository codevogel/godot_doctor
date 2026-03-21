## Exports CLI validation results as a JUnit-style XML report.
class_name GodotDoctorJUnitXmlReportExporter
extends RefCounted

## The default filename used for the XML report when none is specified in settings.
const _DEFAULT_XML_REPORT_FILENAME: String = "godot_doctor_report.xml"
## The number of spaces per indent level in the XML output.
const _INDENT_SIZE: int = 2
## Indent level for [code]<testsuite>[/code] elements.
const _INDENT_LEVEL_TESTSUITE: int = 1
## Indent level for [code]<testcase>[/code] elements.
const _INDENT_LEVEL_TESTCASE: int = 2
## Indent level for [code]<node>[/code] and [code]<resource>[/code] elements.
const _INDENT_LEVEL_TEST_ITEM: int = 3
## Indent level for [code]<harderror>[/code], [code]<warning>[/code],
## and [code]<info>[/code] elements.
const _INDENT_LEVEL_MESSAGE: int = 4
## The number of test items counted per resource (always 1, since each resource is a single item).
const _RESOURCE_TESTS_COUNT: int = 1


## Returns an indentation string for the given [param level].
func _indent(level: int) -> String:
	return " ".repeat(_INDENT_SIZE).repeat(level)


## Exports a JUnit-style XML report from [param suite_reports] if enabled in settings.
## [param summary_stats] is the [Dictionary] from the [GodotDoctorSummaryReport] stats
## used to populate top-level report attributes.
func export_report_from_suite_reports(
	suite_reports: Array[GodotDoctorValidationSuiteReport], summary_stats: Dictionary
) -> void:
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

	file.store_string(_build_junit_xml_report(suite_reports, summary_stats))
	file.close()
	GodotDoctorNotifier.print_debug("Wrote XML report to: %s" % output_path, self)


## Ensures the directory at [param dir_path] exists, creating it recursively if needed.
## Returns [code]true[/code] on success, [code]false[/code] on failure.
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


## Builds and returns the full JUnit XML report string from [param suite_reports].
func _build_junit_xml_report(
	suite_reports: Array[GodotDoctorValidationSuiteReport], summary_stats: Dictionary
) -> String:
	var timestamp: String = Time.get_datetime_string_from_system(false, false)

	var total_validated_items: int = (
		summary_stats[GodotDoctorSummaryReport.Stat.RESOURCES_VALIDATED]
		+ summary_stats[GodotDoctorSummaryReport.Stat.NODES_VALIDATED]
	)
	var total_messages: int = (
		summary_stats[GodotDoctorSummaryReport.Stat.INFO_COUNT]
		+ summary_stats[GodotDoctorSummaryReport.Stat.WARNING_COUNT]
		+ summary_stats[GodotDoctorSummaryReport.Stat.HARD_ERROR_COUNT]
	)

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
					total_validated_items,
					total_messages,
					summary_stats[GodotDoctorSummaryReport.Stat.EFFECTIVE_ERROR_COUNT],
					summary_stats[GodotDoctorSummaryReport.Stat.HARD_ERROR_COUNT],
					summary_stats[GodotDoctorSummaryReport.Stat.WARNING_COUNT],
					summary_stats[GodotDoctorSummaryReport.Stat.INFO_COUNT],
					_xml_escape(timestamp),
				]
			)
		)
	)

	for suite_report: GodotDoctorValidationSuiteReport in suite_reports:
		lines.append(_build_testsuite_xml(suite_report))

	lines.append("</testsuites>")
	return "\n".join(lines)


## Builds and returns the XML string for a single [param suite_report].
func _build_testsuite_xml(suite_report: GodotDoctorValidationSuiteReport) -> String:
	var suite: GodotDoctorValidationSuite = suite_report.get_suite()
	var suite_path: String = _resolve_uid_path(suite_report.get_suite_resource_path())
	var suite_name: String = _xml_escape(_basename(suite_path))
	var suite_path_escaped: String = _xml_escape(suite_path)
	var treat: bool = suite.treat_warnings_as_errors

	var suite_messages: Array[GodotDoctorValidationMessage] = suite_report.get_validation_messages()
	var suite_validated_items: int = suite_report.get_num_nodes() + suite_report.get_num_resources()

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
					suite_validated_items,
					suite_messages.size(),
					_get_effective_error_count(suite_messages, treat),
					suite_report.get_num_errors(),
					suite_report.get_num_warnings(),
					suite_report.get_num_infos(),
				]
			)
		)
	)

	for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
		lines.append(_build_scene_testcase_xml(scene_report, treat))

	for resource_report: GodotDoctorResourceReport in suite_report.get_resource_reports():
		lines.append(_build_resource_testcase_xml(resource_report, treat))

	lines.append("%s</testsuite>" % _indent(_INDENT_LEVEL_TESTSUITE))
	return "\n".join(lines)


## Builds and returns the XML string for a single [param scene_report] testcase.
## Uses [param treat_warnings_as_errors] to calculate effective failure counts.
func _build_scene_testcase_xml(
	scene_report: GodotDoctorSceneReport,
	treat_warnings_as_errors: bool,
) -> String:
	var scene_path: String = scene_report.get_scene_path()
	var scene_messages: Array[GodotDoctorValidationMessage] = scene_report.get_validation_messages()
	var testcase_name: String = _xml_escape(_basename(scene_path))
	var testcase_path: String = _xml_escape(scene_path)

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
					scene_messages.size(),
					_get_effective_error_count(scene_messages, treat_warnings_as_errors),
					scene_report.get_num_errors(),
					scene_report.get_num_warnings(),
					scene_report.get_num_infos(),
				]
			)
		)
	)

	for node_report: GodotDoctorNodeReport in scene_report.get_node_reports():
		var messages: Array[GodotDoctorValidationMessage] = node_report.get_validation_messages()
		if messages.is_empty():
			continue
		lines.append(_build_node_xml(node_report, treat_warnings_as_errors))

	lines.append("%s</testcase>" % _indent(_INDENT_LEVEL_TESTCASE))
	return "\n".join(lines)


## Builds and returns the XML string for a single [param resource_report] testcase.
## Uses [param treat_warnings_as_errors] to calculate effective failure counts.
func _build_resource_testcase_xml(
	resource_report: GodotDoctorResourceReport,
	treat_warnings_as_errors: bool,
) -> String:
	var resource_path: String = _resolve_uid_path(resource_report.get_resource_path())
	var messages: Array[GodotDoctorValidationMessage] = resource_report.get_validation_messages()
	var testcase_name: String = _xml_escape(_basename(resource_path))
	var testcase_path: String = _xml_escape(resource_path)

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
					messages.size(),
					_get_effective_error_count(messages, treat_warnings_as_errors),
					resource_report.get_num_errors(),
					resource_report.get_num_warnings(),
					resource_report.get_num_infos(),
				]
			)
		)
	)

	lines.append(_build_resource_item_xml(resource_report, treat_warnings_as_errors))
	lines.append("%s</testcase>" % _indent(_INDENT_LEVEL_TESTCASE))
	return "\n".join(lines)


## Builds and returns the XML string for a single [param node_report].
## Uses [param treat_warnings_as_errors] to calculate effective failure counts.
func _build_node_xml(
	node_report: GodotDoctorNodeReport,
	treat_warnings_as_errors: bool,
) -> String:
	var node_name: String = _xml_escape(node_report.get_node_name())
	var node_path: String = _xml_escape(node_report.get_node_ancestor_path())
	var messages: Array[GodotDoctorValidationMessage] = node_report.get_validation_messages()
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
					messages.size(),
					_get_effective_error_count(messages, treat_warnings_as_errors),
					node_report.get_num_errors(),
					node_report.get_num_warnings(),
					node_report.get_num_infos(),
				]
			)
		)
	)

	for message: GodotDoctorValidationMessage in messages:
		lines.append(_build_message_xml(message, treat_warnings_as_errors))

	lines.append("%s</node>" % _indent(_INDENT_LEVEL_TEST_ITEM))
	return "\n".join(lines)


## Builds and returns the XML string for the resource item element within a resource testcase.
## Uses [param treat_warnings_as_errors] to calculate effective failure counts.
func _build_resource_item_xml(
	resource_report: GodotDoctorResourceReport,
	treat_warnings_as_errors: bool,
) -> String:
	var resource_path: String = _resolve_uid_path(resource_report.get_resource_path())
	var resource_name: String = _xml_escape(_basename(resource_path))
	var resource_path_escaped: String = _xml_escape(resource_path)
	var messages: Array[GodotDoctorValidationMessage] = resource_report.get_validation_messages()
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
					messages.size(),
					_get_effective_error_count(messages, treat_warnings_as_errors),
					resource_report.get_num_errors(),
					resource_report.get_num_warnings(),
					resource_report.get_num_infos(),
				]
			)
		)
	)

	for message: GodotDoctorValidationMessage in messages:
		lines.append(_build_message_xml(message, treat_warnings_as_errors))

	lines.append("%s</resource>" % _indent(_INDENT_LEVEL_TEST_ITEM))
	return "\n".join(lines)


## Builds and returns the XML string for a single validation [param message].
## Uses [param treat_warnings_as_errors] to annotate promoted warnings.
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


#region Helpers


## Returns the effective error count from [param messages],
## counting warnings as errors when [param treat_warnings_as_errors] is [code]true[/code].
static func _get_effective_error_count(
	messages: Array[GodotDoctorValidationMessage], treat_warnings_as_errors: bool
) -> int:
	var count: int = 0
	for msg: GodotDoctorValidationMessage in messages:
		if msg.severity_level == ValidationCondition.Severity.ERROR:
			count += 1
		elif (
			treat_warnings_as_errors and msg.severity_level == ValidationCondition.Severity.WARNING
		):
			count += 1
	return count


## Returns the filename portion of [param path], without any leading directory components.
func _basename(path: String) -> String:
	return path.get_file()


## Returns [param value] with XML special characters escaped.
func _xml_escape(value: String) -> String:
	return (
		value
		. replace("&", "&amp;")
		. replace('"', "&quot;")
		. replace("'", "&apos;")
		. replace("<", "&lt;")
		. replace(">", "&gt;")
	)


## Resolves a [code]uid://[/code] path to its corresponding resource file path.
## Returns [param path] unchanged if it is not a UID.
func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path

#endregion
