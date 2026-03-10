## Validation reporter for headless / CLI mode.
## Prints results to stdout and exits the process when validation is complete.
## Each GodotDoctorValidationSuite controls whether warnings count as errors for that suite.
class_name GodotDoctorCLIValidationReporter
extends GodotDoctorValidationReporter


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

var current_suite: GodotDoctorValidationSuite
var current_scene_path: String
var suite_reports: Dictionary[GodotDoctorValidationSuite, GodotDoctorSuiteReport] = {}

## The SceneTree, used to quit the application when validation is complete.
var _scene_tree: SceneTree


func _init(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree


func report_node_messages(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void:
	if not suite_reports.has(current_suite):
		suite_reports[current_suite] = GodotDoctorSuiteReport.new(current_suite, [], [])

	var suite_report: GodotDoctorSuiteReport = suite_reports[current_suite]
	var scene_report: GodotDoctorSceneReport = null
	for r in suite_report.scene_reports:
		if r.scene_path == current_scene_path:
			scene_report = r
			break

	if scene_report == null:
		scene_report = GodotDoctorSceneReport.new(current_scene_path, [])
		suite_report.scene_reports.append(scene_report)

	scene_report.node_reports.append(GodotDoctorNodeReport.new(_node_path_string(node), messages))


func report_resource_messages(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void:
	if not suite_reports.has(current_suite):
		suite_reports[current_suite] = GodotDoctorSuiteReport.new(current_suite, [], [])

	suite_reports[current_suite].resource_reports.append(
		GodotDoctorResourceReport.new(resource, messages)
	)


func on_validation_complete() -> void:
	_print_validation_results()
	var error_count: int = suite_reports.values().reduce(
		func(acc: int, sr: GodotDoctorSuiteReport) -> int: return acc + sr.get_error_count(), 0
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
			_print_scene_header(scene_report)
			_print_node_reports(
				scene_report.node_reports, suite_report.suite.treat_warnings_as_errors
			)
		_print_resource_reports(
			suite_report.resource_reports, suite_report.suite.treat_warnings_as_errors
		)


func _print_node_reports(
	node_reports: Array[GodotDoctorNodeReport], treat_warnings_as_errors: bool
) -> void:
	for node_report in node_reports:
		if node_report.messages.is_empty():
			continue
		_print_rich_text("    Node: %s" % node_report.node_path, ReportColors.NODE)
		for msg in node_report.messages:
			_print_message(msg, treat_warnings_as_errors)


func _print_resource_reports(
	resource_reports: Array[GodotDoctorResourceReport], treat_warnings_as_errors: bool
) -> void:
	for resource_report in resource_reports:
		if resource_report.messages.is_empty():
			continue
		_print_resource_header(resource_report.resource.resource_path)
		for msg in resource_report.messages:
			_print_message(msg, treat_warnings_as_errors)


# _print_message
func _print_message(msg: GodotDoctorValidationMessage, treat_warnings_as_errors: bool) -> void:
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


func _print_suite_header(suite: GodotDoctorValidationSuite) -> void:
	_print_rich_text("\n┌─ Suite: %s" % _resolve_uid_path(suite.resource_path), ReportColors.HEADER)
	if suite.treat_warnings_as_errors:
		_print_rich_text("│  ⚠ warnings are treated as errors", ReportColors.WARNING)
	_print_rich_text("└" + "─".repeat(40), ReportColors.HEADER)


func _print_scene_header(scene_report: GodotDoctorSceneReport) -> void:
	_print_rich_text("Scene: %s" % scene_report.scene_path, ReportColors.SCENE)
	_print_rich_text(
		"Found %d nodes to validate" % scene_report.get_node_count(), ReportColors.NODE
	)


func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path


func _print_resource_header(resource_path: String) -> void:
	_print_rich_text("Resource: %s" % _resolve_uid_path(resource_path), ReportColors.SCENE)


func _print_summary() -> void:
	var totals: GodotDoctorMessageCounts = GodotDoctorMessageCounts.new()
	var total_scenes: int = 0
	var total_nodes: int = 0
	var total_resources: int = 0
	for suite_report in suite_reports.values():
		totals.add(suite_report.get_message_counts())
		total_scenes += suite_report.get_scene_count()
		total_nodes += suite_report.get_node_count()
		total_resources += suite_report.get_resource_count()

	var passed: bool = totals.total_errors == 0
	var divider: String = "═".repeat(52)

	_print_rich_text("\n" + divider, ReportColors.HEADER)
	_print_rich_text("  SUMMARY", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)
	_print_rich_text("Total Suites ran           : %d" % suite_reports.size(), ReportColors.HEADER)
	_print_rich_text("Total Scenes validated     : %d" % total_scenes, ReportColors.HEADER)
	_print_rich_text("Total Nodes found to validate: %d" % total_nodes, ReportColors.HEADER)
	_print_rich_text("Total Resources validated  : %d" % total_resources, ReportColors.HEADER)
	_print_rich_text("Total Messages reported    : %d" % totals.total, ReportColors.HEADER)
	_print_rich_text("\nStatus:", ReportColors.HEADER)
	if passed:
		_print_rich_text("  ✔  PASSED", ReportColors.PASSED)
	else:
		_print_rich_text("  ✘  FAILED", ReportColors.FAILED)
	_print_rich_text(divider, ReportColors.HEADER)


## Returns true if this message should increment the error count.
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


func _print_rich_text(text: String, color: Color) -> void:
	print_rich("[color=%s]%s[/color]" % [color.to_html(), text])
