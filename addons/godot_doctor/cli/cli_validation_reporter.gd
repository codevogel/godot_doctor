## Validation reporter for headless / CLI mode.
## Prints results to stdout and exits the process when validation is complete.
## Each ValidationSuite controls whether warnings count as errors for that suite.
class_name CLIValidationReporter
extends ValidationReporter


class ReportColors:
	const INFO: Color = Color.WHITE
	const WARNING: Color = Color.ORANGE
	const ERROR: Color = Color.RED
	const HEADER: Color = Color.CORNFLOWER_BLUE
	const SCENE: Color = Color.STEEL_BLUE
	const NODE: Color = Color.GRAY
	const PASSED: Color = Color.GREEN
	const FAILED: Color = Color.RED


# Report helper classes moved to validation/reports/*.gd

var current_suite: ValidationSuite
var current_scene_path: String
var suite_reports: Dictionary[ValidationSuite, SuiteReport] = {}

## The SceneTree, used to quit the application when validation is complete.
var _scene_tree: SceneTree


func _init(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree


func report_node_messages(node: Node, messages: Array[ValidationMessage]) -> void:
	if not suite_reports.has(current_suite):
		suite_reports[current_suite] = SuiteReport.new(current_suite, [], [])

	var suite_report: SuiteReport = suite_reports[current_suite]
	var scene_report: SceneReport = null
	for r in suite_report.scene_reports:
		if r.scene_path == current_scene_path:
			scene_report = r
			break

	if scene_report == null:
		scene_report = SceneReport.new(current_scene_path, [])
		suite_report.scene_reports.append(scene_report)

	scene_report.node_reports.append(NodeReport.new(node, messages))


func report_resource_messages(resource: Resource, messages: Array[ValidationMessage]) -> void:
	if not suite_reports.has(current_suite):
		suite_reports[current_suite] = SuiteReport.new(current_suite, [], [])

	suite_reports[current_suite].resource_reports.append(ResourceReport.new(resource, messages))


func on_validation_complete() -> void:
	_print_validation_results()
	var error_count: int = suite_reports.values().reduce(
		func(acc: int, sr: SuiteReport) -> int: return acc + sr.get_error_count(), 0
	)
	_scene_tree.quit(0 if error_count == 0 else 1)


func _print_validation_results() -> void:
	_print_report_header()
	_print_suite_reports()
	_print_summary()


func _print_report_header() -> void:
	var divider := "═".repeat(52)
	_print_rich_text(divider, ReportColors.HEADER)
	_print_rich_text("  VALIDATION REPORT", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)


func _print_suite_reports() -> void:
	for suite_report in suite_reports.values():
		_print_suite_header(suite_report.suite)
		for scene_report in suite_report.scene_reports:
			_print_scene_header(scene_report.scene_path)
			_print_node_reports(
				scene_report.node_reports, suite_report.suite.treat_warnings_as_errors
			)
		_print_resource_reports(
			suite_report.resource_reports, suite_report.suite.treat_warnings_as_errors
		)


func _print_node_reports(node_reports: Array[NodeReport], treat_warnings_as_errors: bool) -> void:
	for node_report in node_reports:
		if node_report.messages.is_empty():
			continue
		_print_rich_text("    Node: %s" % _node_path_string(node_report.node), ReportColors.NODE)
		for msg in node_report.messages:
			_print_message(msg, treat_warnings_as_errors)


func _print_resource_reports(
	resource_reports: Array[ResourceReport], treat_warnings_as_errors: bool
) -> void:
	for resource_report in resource_reports:
		if resource_report.messages.is_empty():
			continue
		_print_resource_header(resource_report.resource.resource_path)
		for msg in resource_report.messages:
			_print_message(msg, treat_warnings_as_errors)


# _print_message
func _print_message(msg: ValidationMessage, treat_warnings_as_errors: bool) -> void:
	var is_warning_as_error := (
		treat_warnings_as_errors and msg.severity_level == ValidationCondition.Severity.WARNING
	)

	var label: String
	var color: Color
	if is_warning_as_error:
		label = "[WARNING→ERROR]"
		color = ReportColors.ERROR
	else:
		match msg.severity_level:
			ValidationCondition.Severity.INFO:
				label = "[INFO]   "
				color = ReportColors.INFO
			ValidationCondition.Severity.WARNING:
				label = "[WARNING]"
				color = ReportColors.WARNING
			ValidationCondition.Severity.ERROR:
				label = "[ERROR]  "
				color = ReportColors.ERROR
	_print_rich_text("      %s  %s" % [label, msg.message], color)


func _print_suite_header(suite: ValidationSuite) -> void:
	_print_rich_text("\n┌─ Suite: %s" % suite.resource_path, ReportColors.HEADER)
	if suite.treat_warnings_as_errors:
		_print_rich_text("│  ⚠ warnings are treated as errors", ReportColors.WARNING)
	_print_rich_text("└" + "─".repeat(40), ReportColors.HEADER)


func _print_scene_header(scene_path: String) -> void:
	_print_rich_text("Scene: %s" % scene_path, ReportColors.SCENE)


func _print_resource_header(resource_path: String) -> void:
	_print_rich_text("Resource: %s" % resource_path, ReportColors.SCENE)


func _get_total_validated_count() -> int:
	var count: int = 0
	for suite_report in suite_reports.values():
		for scene_report in suite_report.scene_reports:
			count += scene_report.node_reports.size()
		count += suite_report.resource_reports.size()
	return count


func _print_summary() -> void:
	var totals: MessageCounts = MessageCounts.new()
	for suite_report in suite_reports.values():
		totals.add(suite_report.get_message_counts())

	var passed: bool = totals.total_errors == 0
	var divider: String = "═".repeat(52)

	_print_rich_text("\n" + divider, ReportColors.HEADER)
	_print_rich_text("  SUMMARY", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)
	_print_rich_text("Total validated : %d" % _get_total_validated_count(), ReportColors.HEADER)  # new
	_print_rich_text("Total messages  : %d" % totals.total, ReportColors.HEADER)
	if passed:
		_print_rich_text("  ✔  PASSED", ReportColors.PASSED)
	else:
		_print_rich_text("  ✘  FAILED", ReportColors.FAILED)
	_print_rich_text(divider, ReportColors.HEADER)


## Returns true if this message should increment the error count.
static func counts_as_error(msg: ValidationMessage, treat_warnings_as_errors: bool) -> bool:
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


func _print_rich_text(text: String, color: Color) -> void:
	print_rich("[color=%s]%s[/color]" % [color.to_html(), text])
