## Validation reporter for headless / CLI mode.
## Prints results to stdout and exits the process when validation is complete.
## Each GodotDoctorValidationSuite controls whether warnings count as errors for that suite.
class_name GodotDoctorCLIValidationReporter
extends GodotDoctorValidationReporter


## Defines the display colors used for different parts of the report.
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


## Defines the number of spaces to use for each indentation level in the report.
const _INDENT_SIZE: int = 3

const _DIVIDER_GLYPH: String = "═"
const _DIVIDER_SIZE: int = 52

const _PASSED_GLYPH: String = "✔"
const _FAILED_GLYPH: String = "✘"
const _ANCESTOR_SEPRATOR_GLYPH: String = " -> "
const _BRANCH_MIDDLE_GLYPH: String = "├─"
const _BRANCH_LAST_GLYPH: String = "└─"

## The currently active validation suite.
## This is set externally by the [GodotDoctorCliRunner] before validating each suite,
## and is used by the reporter to associate reported messages with the correct suite.
var current_suite: GodotDoctorValidationSuite

## The currently active scene path.
## This is set externally by the [GodotDoctorCliRunner] before validating each scene,
## and is used for associating node messages with the correct scene in the report.
var current_scene_resource_path: String

## A mapping of suite resource paths to their collected [GodotDoctorSuiteReport]s.
var _suite_reports: Dictionary = {}


## Returns an indentation string repeated [param level] times.
func _indent(level: int) -> String:
	return " ".repeat(_INDENT_SIZE).repeat(level)


## Records the validation [param messages] for [param node]
## into the current suite report under the current scene.
func report_node_messages(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void:
	var suite_report: GodotDoctorSuiteReport = _get_or_create_current_suite_report()
	var scene_report: GodotDoctorSceneReport = _get_or_create_scene_report(suite_report)

	# Create a node report for the current node and add it to the scene report.
	var node_report: GodotDoctorNodeReport = GodotDoctorNodeReport.new(
		suite_report, messages, node.name, _get_node_ancestor_path(node)
	)
	scene_report.add_node_report(node_report)


## Records the validation [param messages] for [param resource] into the current suite report.
func report_resource_messages(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void:
	var suite_report: GodotDoctorSuiteReport = _get_or_create_current_suite_report()

	# Create a resource report for the current resource and add it to the suite report.
	var resource_report: GodotDoctorResourceReport = GodotDoctorResourceReport.new(
		suite_report, resource, messages
	)
	suite_report.add_resource_report(resource_report)


## Returns the report for [member current_suite], creating and storing it if needed.
func _get_or_create_current_suite_report() -> GodotDoctorSuiteReport:
	if _suite_reports.has(current_suite):
		return _suite_reports[current_suite]

	var suite_report: GodotDoctorSuiteReport = GodotDoctorSuiteReport.new(current_suite, [], [])
	_suite_reports[current_suite] = suite_report
	return suite_report


## Returns the scene report for [member current_scene_resource_path] inside [param suite_report],
## creating and registering it when absent.
func _get_or_create_scene_report(suite_report: GodotDoctorSuiteReport) -> GodotDoctorSceneReport:
	for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
		if scene_report.get_scene_path() == current_scene_resource_path:
			return scene_report

	var scene_report_new: GodotDoctorSceneReport = GodotDoctorSceneReport.new(
		current_scene_resource_path, []
	)
	suite_report.add_scene_report(scene_report_new)
	return scene_report_new


## Prints all collected validation results to stdout and exits the process.
## Exits with code [code]0[/code] if there are no errors, or [code]1[/code] if there are errors.
func on_validation_complete() -> void:
	# Convert the suite reports from the dictionary into an array for summary computation.
	var suite_reports_array: Array[GodotDoctorSuiteReport] = []
	for suite_report in _suite_reports.values():
		suite_reports_array.append(suite_report)

	# Compute the summary from the collected suite reports.
	var summary: GodotDoctorReportSummary = GodotDoctorReportSummary.new(suite_reports_array)

	_print_validation_results(summary)
	var exit_code: int = 0 if summary.passed() else 1

	_teardown()

	GodotDoctorPlugin.instance.quit_with_code(exit_code)


## Cleans up all collected reports and resets state, preventing memory leaks
func _teardown() -> void:
	for suite_report: GodotDoctorSuiteReport in _suite_reports.values():
		suite_report.teardown()
	_suite_reports.clear()
	current_suite = null
	current_scene_resource_path = ""


## Orchestrates printing of the full validation report: header, suite reports, and summary.
func _print_validation_results(summary: GodotDoctorReportSummary) -> void:
	_print_report_header()
	_print_suite_reports()
	_print_summary(summary)


## Prints the decorative report header to stdout.
func _print_report_header() -> void:
	var divider: String = _DIVIDER_GLYPH.repeat(_DIVIDER_SIZE)

	_print_rich_text(divider, ReportColors.HEADER)
	_print_rich_text(" GODOT DOCTOR VALIDATION REPORT", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)


## Prints each collected suite report to stdout.
func _print_suite_reports() -> void:
	for suite_report: GodotDoctorSuiteReport in _suite_reports.values():
		var suite: GodotDoctorValidationSuite = suite_report.get_suite()
		_print_state_heading(0, "Suite", suite_report.passed())
		_print_tree_item(0, _resolve_uid_path(suite.resource_path), ReportColors.HEADER)

		if suite.treat_warnings_as_errors:
			_print_rich_text(
				"%s⚠ warnings are treated as errors" % _indent(1), ReportColors.WARNING
			)

		for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
			_print_scene_tree(scene_report, suite.treat_warnings_as_errors)

		_print_resource_reports_tree(
			suite_report.get_resource_reports(), suite.treat_warnings_as_errors
		)


## Prints the tree of node reports contained in [param scene_report] to stdout.
## [param treat_warnings_as_errors] controls whether warnings are displayed as errors.
func _print_scene_tree(
	scene_report: GodotDoctorSceneReport, treat_warnings_as_errors: bool
) -> void:
	var passed: bool = scene_report.passed()
	_print_state_heading(1, "Scene", passed)
	_print_tree_item(1, scene_report.get_scene_path(), ReportColors.SCENE)

	var node_count: int = scene_report.get_node_reports().size()

	_print_count_line(2, "nodes validated", node_count, ReportColors.NODE)

	if passed and scene_report.get_node_reports().is_empty():
		_print_rich_text(
			"%s%s no issues found" % [_indent(2), _get_state_icon(passed)], ReportColors.PASSED
		)
		return

	_print_node_reports_tree(scene_report.get_node_reports(), treat_warnings_as_errors)


## Prints the tree of [param node_reports] to stdout.
## [param treat_warnings_as_errors] controls whether warnings are displayed as errors.
func _print_node_reports_tree(
	node_reports: Array[GodotDoctorNodeReport], treat_warnings_as_errors: bool
) -> void:
	for node_report: GodotDoctorNodeReport in node_reports:
		if node_report.get_messages().is_empty():
			continue
		_print_state_heading(3, node_report.get_node_ancestor_path(), node_report.passed())

		_print_messages_tree(node_report.get_messages(), treat_warnings_as_errors)


## Prints the tree of [param resource_reports] to stdout.
## [param treat_warnings_as_errors] controls whether warnings are displayed as errors.
func _print_resource_reports_tree(
	resource_reports: Array[GodotDoctorResourceReport], treat_warnings_as_errors: bool
) -> void:
	for resource_report: GodotDoctorResourceReport in resource_reports:
		if resource_report.get_messages().is_empty():
			continue
		var path: String = _resolve_uid_path(resource_report.get_resource().resource_path)
		_print_state_heading(1, "Resource", resource_report.passed())
		_print_tree_item(1, path, ReportColors.SCENE)

		_print_messages_tree(resource_report.get_messages(), treat_warnings_as_errors)


## Prints [param messages] as a branch list, selecting the last branch glyph for the final item.
func _print_messages_tree(
	messages: Array[GodotDoctorValidationMessage], treat_warnings_as_errors: bool
) -> void:
	var msg_count: int = messages.size()

	for i: int in range(msg_count):
		var branch: String = _BRANCH_MIDDLE_GLYPH
		if i == msg_count - 1:
			branch = _BRANCH_LAST_GLYPH

		_print_message_tree(messages[i], branch, treat_warnings_as_errors)


## Prints a single [param msg] using [param branch] as the tree connector character.
## [param treat_warnings_as_errors] controls whether warnings are displayed as errors.
func _print_message_tree(
	msg: GodotDoctorValidationMessage, branch: String, treat_warnings_as_errors: bool
) -> void:
	var label: String = _severity_label(msg, treat_warnings_as_errors)
	var padded: String = "%-14s" % label
	## Check by label here as it may differ from the message's
	## actual severity level if warnings are treated as errors.
	var color: Color = _severity_color(label)

	_print_rich_text("%s%s %s %s" % [_indent(3), branch, padded, msg.message], color)


## Returns a human-readable severity label for [param msg].
## If [param treat_warnings_as_errors] is [code]true[/code], warnings are labelled "WARNING→ERROR".
func _severity_label(msg: GodotDoctorValidationMessage, treat_warnings_as_errors: bool) -> String:
	if treat_warnings_as_errors and msg.severity_level == ValidationCondition.Severity.WARNING:
		return "WARNING→ERROR"

	return ValidationCondition.Severity.keys()[msg.severity_level]


## Returns the display [Color] associated with [param label].
func _severity_color(label: String) -> Color:
	match label:
		"INFO":
			return ReportColors.INFO
		"WARNING":
			return ReportColors.WARNING
		"ERROR", "WARNING→ERROR":
			return ReportColors.ERROR
	return ReportColors.INFO


## Prints a summary of totals across all suites to stdout.
func _print_summary(summary: GodotDoctorReportSummary) -> void:
	var divider: String = _DIVIDER_GLYPH.repeat(_DIVIDER_SIZE)

	# Print the summary header with a divider line.
	_print_rich_text("\n" + divider, ReportColors.HEADER)
	_print_rich_text(" SUMMARY", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)

	# Print the totals section of the summary.
	_print_rich_text("\nValidated", ReportColors.TOTALS)
	_print_count_line(1, "Suites", summary.get_suite_ran_count(), ReportColors.TOTALS)
	_print_count_line(1, "Scenes", summary.get_scenes_validated_count(), ReportColors.TOTALS)
	_print_count_line(1, "Nodes", summary.get_nodes_validated_count(), ReportColors.TOTALS)

	_print_rich_text("\nMessages", ReportColors.TOTALS)
	_print_count_line(1, "Info", summary.get_info_messages_count(), ReportColors.INFO)
	_print_count_line(1, "Warnings", summary.get_warning_messages_count(), ReportColors.WARNING)
	_print_count_line(1, "Errors", summary.get_hard_error_messages_count(), ReportColors.ERROR)

	print("")

	var effective_errors_count: int = summary.get_effective_error_count()

	var passed: bool = summary.passed()

	_print_rich_text("Total Errors: %d" % effective_errors_count, _get_state_color(passed))

	_print_rich_text(
		"Warnings treated as errors: %d" % summary.get_warnings_treated_as_errors_count(),
		ReportColors.WARNING
	)

	print("")

	# Print the final validation result: PASSED if there are no errors,
	# or FAILED if there are one or more errors.
	_print_rich_text(
		"%s VALIDATION %s" % [_get_state_icon(passed), "PASSED" if passed else "FAILED"],
		_get_state_color(passed)
	)

	# Print a closing divider line.
	_print_rich_text(divider, ReportColors.HEADER)


## Prints a pass/fail heading line at [param indent_level] with [param label]
## and an icon representing [param passed].
func _print_state_heading(indent_level: int, label: String, passed: bool) -> void:
	_print_rich_text(
		"\n%s%s %s" % [_indent(indent_level), _get_state_icon(passed), label],
		_get_state_color(passed)
	)


## Prints a tree item line at [param indent_level] with [param text] and a branch glyph.
func _print_tree_item(indent_level: int, text: String, color: Color) -> void:
	_print_rich_text("%s%s %s" % [_indent(indent_level), _BRANCH_LAST_GLYPH, text], color)


## Prints an aligned [code]label: count[/code] line at the given indentation level.
func _print_count_line(indent_level: int, label: String, count: int, color: Color) -> void:
	_print_rich_text("%s%-10s %d" % [_indent(indent_level), label, count], color)


## Returns a human-readable path string for [param node] by walking up its ancestor chain.
static func _get_node_ancestor_path(node: Node) -> String:
	var names: Array[String] = []
	var current: Node = node

	while current != null:
		names.push_front(current.name)

		if current.owner == null:
			break

		current = current.get_parent()

	return _ANCESTOR_SEPRATOR_GLYPH.join(names)


## Resolves [param path] from a [code]uid://[/code] string to a filesystem path.
## Returns [param path] unchanged if it is already a filesystem path.
func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path


## Prints [param text] to stdout using [param color] as the rich-text foreground color.
func _print_rich_text(text: String, color: Color) -> void:
	print_rich("[color=%s]%s[/color]" % [color.to_html(), text])


## Returns a checkmark icon if [param passed] is [code]true[/code],
## or a cross icon if [param passed] is [code]false[/code].
func _get_state_icon(passed: bool) -> String:
	return _PASSED_GLYPH if passed else _FAILED_GLYPH


## Returns a display color for the pass/fail state represented by [param passed].
func _get_state_color(passed: bool) -> Color:
	return ReportColors.PASSED if passed else ReportColors.FAILED
