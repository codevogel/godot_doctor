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
const INDENT_SIZE: int = 3

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
	return " ".repeat(INDENT_SIZE).repeat(level)


## Records the validation [param messages] for [param node]
## into the current suite report under the current scene.
func report_node_messages(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void:
	# If there is no report for the current suite yet,
	if not _suite_reports.has(current_suite):
		# create one to hold the node report we're about to add.
		var suite_report_new: GodotDoctorSuiteReport = GodotDoctorSuiteReport.new(
			current_suite, [], []
		)
		_suite_reports[current_suite] = suite_report_new

	# Get the suite report for the current suite, which we know exists because of the check above.
	var suite_report: GodotDoctorSuiteReport = _suite_reports[current_suite]

	# Find the scene report for the current scene in the suite report,
	var scene_report: GodotDoctorSceneReport = null
	for report: GodotDoctorSceneReport in suite_report.get_scene_reports():
		if report.get_scene_path() == current_scene_resource_path:
			scene_report = report
			break

	#or create one if it doesn't exist yet.
	if scene_report == null:
		scene_report = GodotDoctorSceneReport.new(current_scene_resource_path, [])
		suite_report.add_scene_report(scene_report)

	# Create a node report for the current node and add it to the scene report.
	var node_report: GodotDoctorNodeReport = GodotDoctorNodeReport.new(
		suite_report, messages, node.name, _get_node_ancestor_path(node)
	)
	scene_report.add_node_report(node_report)


## Records the validation [param messages] for [param resource] into the current suite report.
func report_resource_messages(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void:
	# If there is no report for the current suite yet,
	if not _suite_reports.has(current_suite):
		# create one to hold the resource report we're about to add.
		var suite_report_new: GodotDoctorSuiteReport = GodotDoctorSuiteReport.new(
			current_suite, [], []
		)
		_suite_reports[current_suite] = suite_report_new

	# Get the suite report for the current suite, which we know exists because of the check above.
	var suite_report: GodotDoctorSuiteReport = _suite_reports[current_suite]

	# Create a resource report for the current resource and add it to the suite report.
	var resource_report: GodotDoctorResourceReport = GodotDoctorResourceReport.new(
		suite_report, resource, messages
	)
	suite_report.add_resource_report(resource_report)


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
	var divider: String = "═".repeat(52)

	_print_rich_text(divider, ReportColors.HEADER)
	_print_rich_text(" GODOT DOCTOR VALIDATION REPORT", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)


## Prints each collected suite report to stdout.
func _print_suite_reports() -> void:
	for suite_report: GodotDoctorSuiteReport in _suite_reports.values():
		var suite: GodotDoctorValidationSuite = suite_report.get_suite()

		var passed: bool = suite_report.passed()

		var icon: String = "✘"
		var color: Color = ReportColors.FAILED

		if passed:
			icon = "✔"
			color = ReportColors.PASSED

		_print_rich_text("\nSuite %s" % icon, color)
		_print_rich_text("└─ %s" % _resolve_uid_path(suite.resource_path), ReportColors.HEADER)

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

	var icon: String = "✘"
	var color: Color = ReportColors.FAILED

	if passed:
		icon = "✔"
		color = ReportColors.PASSED

	_print_rich_text("\n%sScene %s" % [_indent(1), icon], color)

	_print_rich_text("%s└─ %s" % [_indent(1), scene_report.get_scene_path()], ReportColors.SCENE)

	var node_count: int = scene_report.get_node_reports().size()

	_print_rich_text("%snodes validated: %d" % [_indent(2), node_count], ReportColors.NODE)

	if passed and scene_report.get_node_reports().is_empty():
		_print_rich_text("%s✔ no issues found" % _indent(2), ReportColors.PASSED)
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

		_print_rich_text(
			"\n%s%s" % [_indent(2), node_report.get_node_ancestor_path()], ReportColors.NODE
		)

		var msg_count: int = node_report.get_messages().size()

		for i: int in range(msg_count):
			var msg: GodotDoctorValidationMessage = node_report.get_messages()[i]

			var branch: String = "├─"
			if i == msg_count - 1:
				branch = "└─"

			_print_message_tree(msg, branch, treat_warnings_as_errors)


## Prints the tree of [param resource_reports] to stdout.
## [param treat_warnings_as_errors] controls whether warnings are displayed as errors.
func _print_resource_reports_tree(
	resource_reports: Array[GodotDoctorResourceReport], treat_warnings_as_errors: bool
) -> void:
	for resource_report: GodotDoctorResourceReport in resource_reports:
		if resource_report.get_messages().is_empty():
			continue

		var passed: bool = resource_report.passed()

		var icon: String = "✘"
		var color: Color = ReportColors.FAILED

		if passed:
			icon = "✔"
			color = ReportColors.PASSED

		var path: String = _resolve_uid_path(resource_report.get_resource().resource_path)

		_print_rich_text("\n%sResource %s" % [_indent(1), icon], color)
		_print_rich_text("%s└─ %s" % [_indent(1), path], ReportColors.SCENE)

		var msg_count: int = resource_report.get_messages().size()

		for i: int in range(msg_count):
			var msg: GodotDoctorValidationMessage = resource_report.get_messages()[i]

			var branch: String = "├─"
			if i == msg_count - 1:
				branch = "└─"

			_print_message_tree(msg, branch, treat_warnings_as_errors)


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

	return str(msg.severity_level)


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
	var divider: String = "═".repeat(52)

	# Print the summary header with a divider line.
	_print_rich_text("\n" + divider, ReportColors.HEADER)
	_print_rich_text(" SUMMARY", ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)

	# Print the totals section of the summary.
	_print_rich_text("\nValidated", ReportColors.TOTALS)
	_print_rich_text(
		"%sSuites     %d" % [_indent(1), summary.get_suite_ran_count()], ReportColors.TOTALS
	)
	_print_rich_text(
		"%sScenes     %d" % [_indent(1), summary.get_scenes_validated_count()], ReportColors.TOTALS
	)
	_print_rich_text(
		"%sNodes      %d" % [_indent(1), summary.get_nodes_validated_count()], ReportColors.TOTALS
	)

	_print_rich_text("\nMessages", ReportColors.TOTALS)
	_print_rich_text(
		"%sInfo       %d" % [_indent(1), summary.get_info_messages_count()], ReportColors.INFO
	)
	_print_rich_text(
		"%sWarnings   %d" % [_indent(1), summary.get_warning_messages_count()], ReportColors.WARNING
	)
	_print_rich_text(
		"%sErrors     %d" % [_indent(1), summary.get_hard_error_messages_count()],
		ReportColors.ERROR
	)

	print("")

	var effective_errors_count: int = summary.get_effective_error_count()

	var passed: bool = summary.passed()

	if passed:
		_print_rich_text("Total Errors: %d" % effective_errors_count, ReportColors.PASSED)
	else:
		_print_rich_text("Total Errors: %d" % effective_errors_count, ReportColors.ERROR)

	_print_rich_text(
		"Warnings treated as errors: %d" % summary.get_warnings_treated_as_errors_count(),
		ReportColors.WARNING
	)

	print("")

	# Print the final validation result: PASSED if there are no errors,
	# or FAILED if there are one or more errors.
	if passed:
		_print_rich_text("✔ VALIDATION PASSED", ReportColors.PASSED)
	else:
		_print_rich_text("✘ VALIDATION FAILED", ReportColors.FAILED)

	# Print a closing divider line.
	_print_rich_text(divider, ReportColors.HEADER)


## Returns a human-readable path string for [param node] by walking up its ancestor chain.
static func _get_node_ancestor_path(node: Node) -> String:
	var names: Array[String] = []
	var current: Node = node

	while current != null:
		names.push_front(current.name)

		if current.owner == null:
			break

		current = current.get_parent()

	return " -> ".join(names)


## Resolves [param path] from a [code]uid://[/code] string to a filesystem path.
## Returns [param path] unchanged if it is already a filesystem path.
func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path


## Prints [param text] to stdout using [param color] as the rich-text foreground color.
func _print_rich_text(text: String, color: Color) -> void:
	print_rich("[color=%s]%s[/color]" % [color.to_html(), text])
