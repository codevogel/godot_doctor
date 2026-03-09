## Validation reporter for headless / CLI mode.
## Prints results to stdout and exits the process when validation is complete.
## Each ValidationSuite controls whether warnings count as errors for that suite.
class_name CLIValidationReporter
extends ValidationReporter

enum ReportPart {
	WELCOME_HEADER,
	SUITE_HEADER,
	REPORT_HEADER,
}

const _SEVERITY_TO_COLOR: Dictionary[ValidationCondition.Severity, Color] = {
	ValidationCondition.Severity.INFO: Color.WHITE,
	ValidationCondition.Severity.WARNING: Color.ORANGE_RED,
	ValidationCondition.Severity.ERROR: Color.RED,
}

const _REPORT_PART_TO_COLOR: Dictionary[ReportPart, Color] = {
	ReportPart.REPORT_HEADER: Color.YELLOW,
	ReportPart.SUITE_HEADER: Color.CORNFLOWER_BLUE,
}


class NodeReport:
	var node: Node
	var messages: Array[ValidationMessage]

	func _init(node: Node, messages: Array[ValidationMessage]) -> void:
		self.node = node
		self.messages = messages


class ResourceReport:
	var resource: Resource
	var messages: Array[ValidationMessage]

	func _init(resource: Resource, messages: Array[ValidationMessage]) -> void:
		self.resource = resource
		self.messages = messages


class SceneReport:
	var scene_path: String
	var node_reports: Array[NodeReport]

	func _init(scene_path: String, node_reports: Array[NodeReport]) -> void:
		self.scene_path = scene_path
		self.node_reports = node_reports


class SuiteReport:
	var suite: ValidationSuite
	var scene_reports: Array[SceneReport]
	var resource_reports: Array[ResourceReport]

	func _init(
		suite: ValidationSuite,
		scene_reports: Array[SceneReport],
		resource_reports: Array[ResourceReport],
	) -> void:
		self.suite = suite
		self.scene_reports = scene_reports
		self.resource_reports = resource_reports

	func get_message_counts() -> CLIValidationReporter.MessageCounts:
		var counts: CLIValidationReporter.MessageCounts = CLIValidationReporter.MessageCounts.new()
		var messages: Array[ValidationMessage] = _collect_messages()
		counts.info = get_message_count(messages, ValidationCondition.Severity.INFO)
		counts.warning = get_message_count(messages, ValidationCondition.Severity.WARNING)
		counts.hard_error = get_message_count(messages, ValidationCondition.Severity.ERROR)
		if suite.treat_warnings_as_errors:
			counts.warnings_as_errors = counts.warning
		return counts

	func get_error_count() -> int:
		return _collect_messages().reduce(
			func(acc: int, msg: ValidationMessage) -> int:
				return acc + (1 if counts_as_error(msg) else 0),
			0
		)

	func counts_as_error(msg: ValidationMessage) -> bool:
		return (
			msg.severity_level == ValidationCondition.Severity.ERROR
			or (
				suite.treat_warnings_as_errors
				and msg.severity_level == ValidationCondition.Severity.WARNING
			)
		)

	static func get_message_count(
		messages: Array[ValidationMessage], severity: ValidationCondition.Severity
	) -> int:
		return messages.reduce(
			func(acc: int, msg: ValidationMessage) -> int:
				return acc + (1 if msg.severity_level == severity else 0),
			0
		)

	func _collect_messages() -> Array[ValidationMessage]:
		var messages: Array[ValidationMessage] = []
		for scene_report in scene_reports:
			for node_report in scene_report.node_reports:
				messages.append_array(node_report.messages)
		for resource_report in resource_reports:
			messages.append_array(resource_report.messages)
		return messages


class MessageCounts:
	var info: int = 0
	var warning: int = 0
	var hard_error: int = 0
	var warnings_as_errors: int = 0

	var total: int:
		get:
			return info + warning + hard_error

	var total_errors: int:
		get:
			return hard_error + warnings_as_errors

	func add(other: CLIValidationReporter.MessageCounts) -> void:
		info += other.info
		warning += other.warning
		hard_error += other.hard_error
		warnings_as_errors += other.warnings_as_errors


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
		_print_rich_text("    Node: %s" % _node_path_string(node_report.node), Color.LIGHT_GRAY)
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


func _print_resource_header(resource_path: String) -> void:
	_print_rich_text("Resource: %s" % resource_path, Color.STEEL_BLUE)


func _print_message(msg: ValidationMessage, treat_warnings_as_errors: bool) -> void:
	var is_warning_as_error: bool = (
		treat_warnings_as_errors and msg.severity_level == ValidationCondition.Severity.WARNING
	)

	var label: String
	var color: Color
	if is_warning_as_error:
		label = "[WARNING→ERROR]"
		color = _SEVERITY_TO_COLOR[ValidationCondition.Severity.ERROR]
	else:
		color = _SEVERITY_TO_COLOR[msg.severity_level]
		match msg.severity_level:
			ValidationCondition.Severity.INFO:
				label = "[INFO]   "
			ValidationCondition.Severity.WARNING:
				label = "[WARNING]"
			ValidationCondition.Severity.ERROR:
				label = "[ERROR]  "

	_print_rich_text("      %s  %s" % [label, msg.message], color)


func _print_report_header() -> void:
	var divider: String = "═".repeat(52)
	_print_rich_text(divider, _REPORT_PART_TO_COLOR[ReportPart.REPORT_HEADER])
	_print_rich_text("  VALIDATION REPORT", _REPORT_PART_TO_COLOR[ReportPart.REPORT_HEADER])
	_print_rich_text(divider, _REPORT_PART_TO_COLOR[ReportPart.REPORT_HEADER])


func _print_suite_header(suite: ValidationSuite) -> void:
	_print_rich_text(
		"\n┌─ Suite: %s" % suite.resource_path, _REPORT_PART_TO_COLOR[ReportPart.SUITE_HEADER]
	)
	if suite.treat_warnings_as_errors:
		_print_rich_text(
			"│  ⚠ warnings are treated as errors",
			_SEVERITY_TO_COLOR[ValidationCondition.Severity.WARNING]
		)
	_print_rich_text("└" + "─".repeat(40), _REPORT_PART_TO_COLOR[ReportPart.SUITE_HEADER])


func _print_scene_header(scene_path: String) -> void:
	_print_rich_text("Scene: %s" % scene_path, Color.STEEL_BLUE)


func _print_summary() -> void:
	var totals: MessageCounts = MessageCounts.new()
	for suite_report in suite_reports.values():
		totals.add(suite_report.get_message_counts())

	var passed: bool = totals.total_errors == 0
	var divider: String = "═".repeat(52)

	_print_rich_text("\n" + divider, _REPORT_PART_TO_COLOR[ReportPart.REPORT_HEADER])
	_print_rich_text("  SUMMARY", _REPORT_PART_TO_COLOR[ReportPart.REPORT_HEADER])
	_print_rich_text(divider, _REPORT_PART_TO_COLOR[ReportPart.REPORT_HEADER])
	_print_rich_text("Total messages : %d" % totals.total, Color.WHITE)
	_print_rich_text(
		"  INFO         : %d" % totals.info, _SEVERITY_TO_COLOR[ValidationCondition.Severity.INFO]
	)
	_print_rich_text(
		"  WARNING      : %d" % totals.warning,
		_SEVERITY_TO_COLOR[ValidationCondition.Severity.WARNING]
	)
	_print_rich_text(
		"  ERROR        : %d" % totals.hard_error,
		_SEVERITY_TO_COLOR[ValidationCondition.Severity.ERROR]
	)
	if totals.warnings_as_errors > 0:
		_print_rich_text(
			"  (+ %d warning(s) promoted to errors)" % totals.warnings_as_errors,
			_SEVERITY_TO_COLOR[ValidationCondition.Severity.WARNING],
		)
	_print_rich_text("Total errors   : %d" % totals.total_errors, Color.WHITE)
	_print_rich_text(divider, _REPORT_PART_TO_COLOR[ReportPart.REPORT_HEADER])
	if passed:
		_print_rich_text("  ✔  PASSED", Color.GREEN)
	else:
		_print_rich_text("  ✘  FAILED", Color.RED)
	_print_rich_text(divider, _REPORT_PART_TO_COLOR[ReportPart.REPORT_HEADER])


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
