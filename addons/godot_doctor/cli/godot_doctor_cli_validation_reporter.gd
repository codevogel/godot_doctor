## Validation reporter for headless / CLI mode.
## Prints results to stdout and exits the process when validation is complete.
## Each GodotDoctorValidationSuite controls whether warnings count as errors for that suite.
class_name GodotDoctorCLIValidationReporter
extends GodotDoctorValidationReporter


class ReportColors:
	const TOTALS: Color = Color.GRAY
	const INFO: Color = Color.WHITE
	const WARNING: Color = Color.ORANGE
	const ERROR: Color = Color.RED
	const HEADER: Color = Color.CORNFLOWER_BLUE
	const SCENE: Color = Color.STEEL_BLUE
	const NODE: Color = Color.GRAY
	const PASSED: Color = Color.GREEN
	const FAILED: Color = Color.RED


const INDENT: String = "   "

var current_suite: GodotDoctorValidationSuite
var current_scene_path: String
var suite_reports: Dictionary = {}

var _scene_tree: SceneTree


func _init(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree


func _indent(level: int) -> String:
	return INDENT.repeat(level)


func report_node_messages(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void:
	if not suite_reports.has(current_suite):
		var suite_report_new: GodotDoctorSuiteReport = GodotDoctorSuiteReport.new(
			current_suite, [], []
		)
		suite_reports[current_suite] = suite_report_new

	var suite_report: GodotDoctorSuiteReport = suite_reports[current_suite]

	var scene_report: GodotDoctorSceneReport = null
	for r: GodotDoctorSceneReport in suite_report.scene_reports:
		if r.scene_path == current_scene_path:
			scene_report = r
			break

	if scene_report == null:
		scene_report = GodotDoctorSceneReport.new(current_scene_path, [])
		suite_report.scene_reports.append(scene_report)

	var node_report: GodotDoctorNodeReport = GodotDoctorNodeReport.new(
		_node_path_string(node), messages
	)

	scene_report.node_reports.append(node_report)


func report_resource_messages(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void:
	if not suite_reports.has(current_suite):
		var suite_report_new: GodotDoctorSuiteReport = GodotDoctorSuiteReport.new(
			current_suite, [], []
		)
		suite_reports[current_suite] = suite_report_new

	var suite_report: GodotDoctorSuiteReport = suite_reports[current_suite]

	var resource_report: GodotDoctorResourceReport = GodotDoctorResourceReport.new(
		resource, messages
	)

	suite_report.resource_reports.append(resource_report)


func on_validation_complete() -> void:
	_print_validation_results()

	var error_count: int = 0

	for sr: GodotDoctorSuiteReport in suite_reports.values():
		error_count += sr.get_error_count()

	if error_count == 0:
		_scene_tree.quit(0)
	else:
		_scene_tree.quit(1)


func _print_validation_results() -> void:
	_print_report_header()
	_print_suite_reports()
	_print_summary()


func _print_report_header() -> void:
	var divider: String = "═".repeat(52)

	_print_rich_text(divider, ReportColors.HEADER)
	_print_rich_text(" GODOT DOCTOR VALIDATION REPORT", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)


func _print_suite_reports() -> void:
	for suite_report: GodotDoctorSuiteReport in suite_reports.values():
		var suite: GodotDoctorValidationSuite = suite_report.suite

		var failed: bool = suite_report.get_error_count() > 0

		var icon: String = "✔"
		var color: Color = ReportColors.PASSED

		if failed:
			icon = "✘"
			color = ReportColors.FAILED

		_print_rich_text("\nSuite %s" % icon, color)
		_print_rich_text("└─ %s" % _resolve_uid_path(suite.resource_path), ReportColors.HEADER)

		if suite.treat_warnings_as_errors:
			_print_rich_text(
				"%s⚠ warnings are treated as errors" % _indent(1), ReportColors.WARNING
			)

		for scene_report: GodotDoctorSceneReport in suite_report.scene_reports:
			_print_scene_tree(scene_report, suite.treat_warnings_as_errors)

		_print_resource_reports_tree(suite_report.resource_reports, suite.treat_warnings_as_errors)


func _print_scene_tree(
	scene_report: GodotDoctorSceneReport, treat_warnings_as_errors: bool
) -> void:
	var failed: bool = _scene_has_errors(scene_report, treat_warnings_as_errors)

	var icon: String = "✔"
	var color: Color = ReportColors.PASSED

	if failed:
		icon = "✘"
		color = ReportColors.FAILED

	_print_rich_text("\n%sScene %s" % [_indent(1), icon], color)

	_print_rich_text("%s└─ %s" % [_indent(1), scene_report.scene_path], ReportColors.SCENE)

	var node_count: int = scene_report.get_nodes_validated_count()

	_print_rich_text("%snodes validated: %d" % [_indent(2), node_count], ReportColors.NODE)

	if not failed and scene_report.node_reports.is_empty():
		_print_rich_text("%s✔ no issues found" % _indent(2), ReportColors.PASSED)
		return

	_print_node_reports_tree(scene_report.node_reports, treat_warnings_as_errors)


func _print_node_reports_tree(
	node_reports: Array[GodotDoctorNodeReport], treat_warnings_as_errors: bool
) -> void:
	for node_report: GodotDoctorNodeReport in node_reports:
		if node_report.messages.is_empty():
			continue

		_print_rich_text("\n%s%s" % [_indent(2), node_report.node_path], ReportColors.NODE)

		var msg_count: int = node_report.messages.size()

		for i: int in range(msg_count):
			var msg: GodotDoctorValidationMessage = node_report.messages[i]

			var branch: String = "├─"
			if i == msg_count - 1:
				branch = "└─"

			_print_message_tree(msg, branch, treat_warnings_as_errors)


func _print_resource_reports_tree(
	resource_reports: Array[GodotDoctorResourceReport], treat_warnings_as_errors: bool
) -> void:
	for resource_report: GodotDoctorResourceReport in resource_reports:
		if resource_report.messages.is_empty():
			continue

		var failed: bool = _resource_has_errors(resource_report, treat_warnings_as_errors)

		var icon: String = "✔"
		var color: Color = ReportColors.PASSED

		if failed:
			icon = "✘"
			color = ReportColors.FAILED

		var path: String = _resolve_uid_path(resource_report.resource.resource_path)

		_print_rich_text("\n%sResource %s" % [_indent(1), icon], color)
		_print_rich_text("%s└─ %s" % [_indent(1), path], ReportColors.SCENE)

		var msg_count: int = resource_report.messages.size()

		for i: int in range(msg_count):
			var msg: GodotDoctorValidationMessage = resource_report.messages[i]

			var branch: String = "├─"
			if i == msg_count - 1:
				branch = "└─"

			_print_message_tree(msg, branch, treat_warnings_as_errors)


func _print_message_tree(
	msg: GodotDoctorValidationMessage, branch: String, treat_warnings_as_errors: bool
) -> void:
	var label: String = _severity_label(msg, treat_warnings_as_errors)
	var padded: String = "%-14s" % label
	var color: Color = _severity_color(label)

	_print_rich_text("%s%s %s %s" % [_indent(3), branch, padded, msg.message], color)


func _severity_label(msg: GodotDoctorValidationMessage, treat_warnings_as_errors: bool) -> String:
	if treat_warnings_as_errors and msg.severity_level == ValidationCondition.Severity.WARNING:
		return "WARNING→ERROR"

	match msg.severity_level:
		ValidationCondition.Severity.INFO:
			return "INFO"
		ValidationCondition.Severity.WARNING:
			return "WARNING"
		ValidationCondition.Severity.ERROR:
			return "ERROR"

	return ""


func _severity_color(label: String) -> Color:
	match label:
		"INFO":
			return ReportColors.INFO
		"WARNING":
			return ReportColors.WARNING
		"ERROR", "WARNING→ERROR":
			return ReportColors.ERROR
	return ReportColors.INFO


func _scene_has_errors(
	scene_report: GodotDoctorSceneReport, treat_warnings_as_errors: bool
) -> bool:
	for node_report: GodotDoctorNodeReport in scene_report.node_reports:
		for msg: GodotDoctorValidationMessage in node_report.messages:
			if counts_as_error(msg, treat_warnings_as_errors):
				return true

	return false


func _resource_has_errors(
	resource_report: GodotDoctorResourceReport, treat_warnings_as_errors: bool
) -> bool:
	for msg: GodotDoctorValidationMessage in resource_report.messages:
		if counts_as_error(msg, treat_warnings_as_errors):
			return true

	return false


func _print_summary() -> void:
	var suite_reports_array: Array[GodotDoctorSuiteReport] = []
	for suite_report in suite_reports_array:
		suite_reports_array.append(suite_report)

	var summary: GodotDoctorReportSummary = GodotDoctorReportSummary.new(suite_reports_array)

	var passed: bool = summary.total_error_count == 0
	var divider: String = "═".repeat(52)

	_print_rich_text("\n" + divider, ReportColors.HEADER)
	_print_rich_text(" SUMMARY", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)

	_print_rich_text("\nValidated", ReportColors.TOTALS)
	_print_rich_text(
		"%sSuites     %d" % [_indent(1), summary.total_suite_count], ReportColors.TOTALS
	)
	_print_rich_text(
		"%sScenes     %d" % [_indent(1), summary.total_scenes_validated_count], ReportColors.TOTALS
	)
	_print_rich_text(
		"%sNodes      %d" % [_indent(1), summary.total_nodes_validated_count], ReportColors.TOTALS
	)

	_print_rich_text("\nMessages", ReportColors.TOTALS)
	_print_rich_text(
		"%sInfo       %d" % [_indent(1), summary.total_info_messages_reported_count],
		ReportColors.INFO
	)
	_print_rich_text(
		"%sWarnings   %d" % [_indent(1), summary.total_warning_messages_reported_count],
		ReportColors.WARNING
	)
	_print_rich_text(
		"%sErrors     %d" % [_indent(1), summary.total_hard_error_messages_reported_count],
		ReportColors.ERROR
	)

	print("")

	var total_errors: int = summary.total_error_count

	if passed:
		_print_rich_text("Total Errors: %d" % total_errors, ReportColors.PASSED)
	else:
		_print_rich_text("Total Errors: %d" % total_errors, ReportColors.ERROR)

	_print_rich_text(
		"Warnings treated as errors: %d" % summary.total_warning_messages_reported_as_errors_count,
		ReportColors.WARNING
	)

	print("")

	if passed:
		_print_rich_text("✔ VALIDATION PASSED", ReportColors.PASSED)
	else:
		_print_rich_text("✘ VALIDATION FAILED", ReportColors.FAILED)

	_print_rich_text(divider, ReportColors.HEADER)


static func counts_as_error(
	msg: GodotDoctorValidationMessage, treat_warnings_as_errors: bool
) -> bool:
	if msg.severity_level == ValidationCondition.Severity.ERROR:
		return true
	if treat_warnings_as_errors and msg.severity_level == ValidationCondition.Severity.WARNING:
		return true
	return false


static func _node_path_string(node: Node) -> String:
	var names: Array[String] = []
	var current: Node = node

	while current != null:
		names.push_front(current.name)

		if current.owner == null:
			break

		current = current.get_parent()

	return " -> ".join(names)


func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path


func _print_rich_text(text: String, color: Color) -> void:
	print_rich("[color=%s]%s[/color]" % [color.to_html(), text])
