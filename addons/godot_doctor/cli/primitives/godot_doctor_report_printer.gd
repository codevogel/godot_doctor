## Renders CLI validation results to stdout in rich-text format.
## Walks [GodotDoctorSummaryReport] and its nested report objects,
## computing pass/fail status and summary statistics inline.
class_name GodotDoctorReportPrinter
extends RefCounted

## The separator inserted between ancestor node names when rendering a node's path.
const _ANCESTOR_SEPARATOR_GLYPH: String = " -> "


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

## The repeated character used to draw horizontal divider lines in the report.
const _DIVIDER_GLYPH: String = "═"
## The number of times [constant _DIVIDER_GLYPH] is repeated to form a full divider line.
const _DIVIDER_SIZE: int = 52

## Glyph displayed next to a passing validation result.
const _PASSED_GLYPH: String = "✔"
## Glyph displayed next to a failing validation result.
const _FAILED_GLYPH: String = "✘"
## Vertical tree connector used to show that a branch continues below.
const _BRANCH_EXTEND_GLYPH: String = "│ "
## Tree connector used for an intermediate branch item.
const _BRANCH_MIDDLE_GLYPH: String = "├─"
## Tree connector used for the last item in a branch.
const _BRANCH_LAST_GLYPH: String = "└─"

## The column at which numeric totals are right-aligned in the summary section.
const _SUMMARY_COLUMN: int = 25
## Padding width for plain (non-parenthesized) count prefixes in the summary.
## Leaves one character for the digit itself, aligning it at [constant _SUMMARY_COLUMN].
const _SUMMARY_PLAIN_PREFIX_WIDTH: int = _SUMMARY_COLUMN - 1
## Padding width for parenthesized count prefixes in the summary.
## Accounts for the two extra characters in "(N)", aligning the digit at [constant _SUMMARY_COLUMN].
const _SUMMARY_PAREN_PREFIX_WIDTH: int = _SUMMARY_COLUMN - 2
## Label padding width for tree entries in [method _print_summary_tree_line].
## The branch glyph (2 chars) and trailing space (1 char) account for the remaining columns.
const _SUMMARY_TREE_LABEL_WIDTH: int = _SUMMARY_COLUMN - 4
## Padding width for the severity label column in [method _print_message_tree].
## [constant _SEVERITY_LABEL_WARNING_AS_ERROR]
## is the longest possible label (13 chars); padded to 14 for a trailing space.
const _SEVERITY_LABEL_WIDTH: int = 14
## Padding width for the label argument in [method _print_count_line].
const _COUNT_LABEL_WIDTH: int = 10

## Titles printed in the report section headers.
const _REPORT_HEADER_TITLE: String = " GODOT DOCTOR VALIDATION REPORT"
const _SUMMARY_TITLE: String = " SUMMARY"

## Labels for the section headings printed next to the pass/fail icon.
const _SECTION_LABEL_SUITE: String = "Suite"
const _SECTION_LABEL_SCENE: String = "Scene"
const _SECTION_LABEL_RESOURCE: String = "Resource"

## Severity label used when a warning is promoted to an error.
## This is also the longest possible label, which drives [constant _SEVERITY_LABEL_WIDTH].
const _SEVERITY_LABEL_WARNING_AS_ERROR: String = "WARNING→ERROR"

## Inline messages used during validation rendering.
const _COUNT_LABEL_NODES_VALIDATED: String = "nodes validated"
const _MSG_NO_ISSUES_FOUND: String = "no issues found"
const _MSG_WARNINGS_TREATED_AS_ERRORS: String = "⚠ warnings are treated as errors"

## Labels for the validation result line.
const _VALIDATION_PASSED_LABEL: String = "PASSED"
const _VALIDATION_FAILED_LABEL: String = "FAILED"

## Labels for the items and messages totals trees in the summary section.
const _SUMMARY_LABEL_ITEMS_VALIDATED: String = "Items Validated:"
const _SUMMARY_LABEL_SUITES: String = "Suites:"
const _SUMMARY_LABEL_SCENES: String = "Scenes:"
const _SUMMARY_LABEL_NODES: String = "Nodes:"
const _SUMMARY_LABEL_RESOURCES: String = "Resources:"
const _SUMMARY_LABEL_MESSAGES_REPORTED: String = "Messages reported:"
const _SUMMARY_LABEL_INFO: String = "Info:"
const _SUMMARY_LABEL_WARNINGS: String = "Warnings:"
const _SUMMARY_LABEL_HARD_ERRORS: String = "Hard Errors:"
const _SUMMARY_LABEL_TOTAL_ERRORS: String = "Total Errors:"
const _SUMMARY_LABEL_WARNINGS_AS_ERRORS: String = "Warning as errors:"

#region Public API


## Orchestrates printing of the full validation report from [param validation_suite_reports].
## Uses [param stats] (keyed by [enum GodotDoctorSummaryReport.Stat])
## to render the summary section without recalculating aggregate totals.
## Returns [param stats] for downstream consumers.
func print_validation_results(
	validation_suite_reports: Array[GodotDoctorValidationSuiteReport],
	stats: Dictionary,
) -> void:
	_print_report_header()
	_print_suite_reports(validation_suite_reports)
	_print_summary(stats)


#endregion

#region Report rendering


## Prints the decorative report header to stdout.
func _print_report_header() -> void:
	var divider: String = _DIVIDER_GLYPH.repeat(_DIVIDER_SIZE)

	_print_rich_text(divider, ReportColors.HEADER)
	_print_rich_text(_REPORT_HEADER_TITLE, ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)


## Prints all suites from [param suite_reports].
func _print_suite_reports(suite_reports: Array[GodotDoctorValidationSuiteReport]) -> void:
	for suite_report: GodotDoctorValidationSuiteReport in suite_reports:
		var suite: GodotDoctorValidationSuite = suite_report.get_suite()
		var treat_warnings_as_errors: bool = suite.treat_warnings_as_errors
		var suite_passed: bool = _messages_passed(
			suite_report.get_validation_messages(), treat_warnings_as_errors
		)

		_print_pass_fail_tree_section(
			0,
			_SECTION_LABEL_SUITE,
			suite_passed,
			_resolve_uid_path(suite_report.get_suite_resource_path()),
			ReportColors.HEADER
		)

		_print_warning_mode_if_needed(treat_warnings_as_errors)

		for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
			_print_scene_report(scene_report, treat_warnings_as_errors)

		for resource_report: GodotDoctorResourceReport in suite_report.get_resource_reports():
			_print_resource_report(resource_report, treat_warnings_as_errors)


## Prints a [param scene_report].
func _print_scene_report(
	scene_report: GodotDoctorSceneReport,
	treat_warnings_as_errors: bool,
) -> void:
	var scene_passed: bool = _messages_passed(
		scene_report.get_validation_messages(), treat_warnings_as_errors
	)

	_print_pass_fail_tree_section(
		1,
		_SECTION_LABEL_SCENE,
		scene_passed,
		_resolve_uid_path(scene_report.get_scene_path()),
		ReportColors.SCENE
	)

	var node_count: int = scene_report.get_node_reports().size()
	_print_count_line(2, _COUNT_LABEL_NODES_VALIDATED, node_count, ReportColors.NODE)

	if scene_passed and scene_report.get_node_reports().is_empty():
		_print_rich_text(
			"%s%s %s" % [_indent(2), _get_state_icon(scene_passed), _MSG_NO_ISSUES_FOUND],
			ReportColors.PASSED,
		)
		return

	for node_report: GodotDoctorNodeReport in scene_report.get_node_reports():
		var messages: Array[GodotDoctorValidationMessage] = node_report.get_validation_messages()
		if messages.is_empty():
			continue

		var ancestor_path: String = node_report.get_node_ancestor_path().replace(
			"/", _ANCESTOR_SEPARATOR_GLYPH
		)
		var node_passed: bool = _messages_passed(messages, treat_warnings_as_errors)

		_print_message_section(
			3,
			ancestor_path,
			node_passed,
			messages,
			treat_warnings_as_errors,
		)


## Prints a [param resource_report].
func _print_resource_report(
	resource_report: GodotDoctorResourceReport,
	treat_warnings_as_errors: bool,
) -> void:
	var messages: Array[GodotDoctorValidationMessage] = resource_report.get_validation_messages()
	if messages.is_empty():
		return

	var resource_path: String = _resolve_uid_path(resource_report.get_resource_path())
	var resource_passed: bool = _messages_passed(messages, treat_warnings_as_errors)

	_print_message_section(
		1,
		_SECTION_LABEL_RESOURCE,
		resource_passed,
		messages,
		treat_warnings_as_errors,
		resource_path,
		ReportColors.SCENE,
	)


## Prints a summary of totals across all suites to stdout using the accumulated [param stats].
func _print_summary(stats: Dictionary) -> void:
	var divider: String = _DIVIDER_GLYPH.repeat(_DIVIDER_SIZE)

	# Print the summary header with a divider line.
	_print_rich_text("\n" + divider, ReportColors.HEADER)
	_print_rich_text(_SUMMARY_TITLE, ReportColors.HEADER)
	_print_rich_text(divider, ReportColors.HEADER)

	# Print the validated items tree.
	# Numbers are right-aligned at column [constant _SUMMARY_COLUMN].
	# Plain counts: prefix padded to [constant _SUMMARY_PLAIN_PREFIX_WIDTH] chars,
	# digit at col [constant _SUMMARY_COLUMN].
	# Parenthesized counts: prefix padded to [constant _SUMMARY_PAREN_PREFIX_WIDTH] chars,
	# "(N)" so digit lands at col [constant _SUMMARY_COLUMN].
	var validated_items: int = (
		stats[GodotDoctorSummaryReport.Stat.NODES_VALIDATED]
		+ stats[GodotDoctorSummaryReport.Stat.RESOURCES_VALIDATED]
	)
	_print_rich_text(
		(
			"\n%s%d"
			% [_SUMMARY_LABEL_ITEMS_VALIDATED.rpad(_SUMMARY_PLAIN_PREFIX_WIDTH), validated_items]
		),
		ReportColors.TOTALS
	)
	_print_rich_text(_BRANCH_EXTEND_GLYPH, ReportColors.TOTALS)
	_print_rich_text(
		(
			"%s(%d)"
			% [
				("%s %s" % [_BRANCH_LAST_GLYPH, _SUMMARY_LABEL_SUITES]).rpad(
					_SUMMARY_PAREN_PREFIX_WIDTH
				),
				stats[GodotDoctorSummaryReport.Stat.SUITE_COUNT]
			]
		),
		ReportColors.TOTALS
	)
	_print_rich_text(
		(
			"%s(%d)"
			% [
				("   %s %s" % [_BRANCH_MIDDLE_GLYPH, _SUMMARY_LABEL_SCENES]).rpad(
					_SUMMARY_PAREN_PREFIX_WIDTH
				),
				stats[GodotDoctorSummaryReport.Stat.SCENES_VALIDATED]
			]
		),
		ReportColors.TOTALS
	)
	_print_rich_text(
		(
			"%s%d"
			% [
				(
					(
						"   %s  %s %s"
						% [_BRANCH_EXTEND_GLYPH, _BRANCH_LAST_GLYPH, _SUMMARY_LABEL_NODES]
					)
					. rpad(_SUMMARY_PLAIN_PREFIX_WIDTH)
				),
				stats[GodotDoctorSummaryReport.Stat.NODES_VALIDATED]
			]
		),
		ReportColors.TOTALS
	)
	_print_rich_text(
		(
			"%s%d"
			% [
				("   %s %s" % [_BRANCH_LAST_GLYPH, _SUMMARY_LABEL_RESOURCES]).rpad(
					_SUMMARY_PLAIN_PREFIX_WIDTH
				),
				stats[GodotDoctorSummaryReport.Stat.RESOURCES_VALIDATED]
			]
		),
		ReportColors.TOTALS
	)

	# Print the messages tree.
	var total_messages: int = (
		stats[GodotDoctorSummaryReport.Stat.INFO_COUNT]
		+ stats[GodotDoctorSummaryReport.Stat.WARNING_COUNT]
		+ stats[GodotDoctorSummaryReport.Stat.HARD_ERROR_COUNT]
	)
	_print_rich_text(
		(
			"\n%s%d"
			% [_SUMMARY_LABEL_MESSAGES_REPORTED.rpad(_SUMMARY_PLAIN_PREFIX_WIDTH), total_messages]
		),
		ReportColors.TOTALS
	)
	_print_rich_text(_BRANCH_EXTEND_GLYPH, ReportColors.TOTALS)
	_print_summary_tree_line(
		_BRANCH_MIDDLE_GLYPH,
		_SUMMARY_LABEL_INFO,
		stats[GodotDoctorSummaryReport.Stat.INFO_COUNT],
		ReportColors.INFO
	)
	_print_summary_tree_line(
		_BRANCH_MIDDLE_GLYPH,
		_SUMMARY_LABEL_WARNINGS,
		stats[GodotDoctorSummaryReport.Stat.WARNING_COUNT],
		ReportColors.WARNING
	)
	_print_summary_tree_line(
		_BRANCH_LAST_GLYPH,
		_SUMMARY_LABEL_HARD_ERRORS,
		stats[GodotDoctorSummaryReport.Stat.HARD_ERROR_COUNT],
		ReportColors.ERROR
	)

	# Print the errors section.
	var effective_errors_count: int = stats[GodotDoctorSummaryReport.Stat.EFFECTIVE_ERROR_COUNT]
	var passed: bool = stats[GodotDoctorSummaryReport.Stat.PASSED]

	_print_rich_text(
		(
			"\n%s%d"
			% [
				_SUMMARY_LABEL_TOTAL_ERRORS.rpad(_SUMMARY_PLAIN_PREFIX_WIDTH),
				effective_errors_count
			]
		),
		_get_state_color(passed)
	)
	_print_rich_text("│", ReportColors.TOTALS)
	_print_summary_tree_line(
		_BRANCH_LAST_GLYPH,
		_SUMMARY_LABEL_WARNINGS_AS_ERRORS,
		stats[GodotDoctorSummaryReport.Stat.WARNINGS_AS_ERRORS_COUNT],
		ReportColors.WARNING,
	)

	print("")

	# Print the final validation result: PASSED if there are no errors,
	# or FAILED if there are one or more errors.
	_print_rich_text(
		(
			"%s VALIDATION %s"
			% [
				_get_state_icon(passed),
				_VALIDATION_PASSED_LABEL if passed else _VALIDATION_FAILED_LABEL
			]
		),
		_get_state_color(passed)
	)

	# Print a closing divider line.
	_print_rich_text(divider, ReportColors.HEADER)


#endregion

#region Message helpers


## Returns [code]true[/code] if [param messages] contain no effective errors.
static func _messages_passed(
	messages: Array[GodotDoctorValidationMessage], treat_warnings_as_errors: bool
) -> bool:
	return _get_effective_error_count(messages, treat_warnings_as_errors) == 0


## Returns the number of messages that count as errors, including
## warnings promoted to errors when [param treat_warnings_as_errors] is [code]true[/code].
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


#endregion

#region Message rendering


## Returns the branch glyph to use for a message at [param index] in a list of [param count] items.
func _get_message_branch(index: int, count: int) -> String:
	return _BRANCH_LAST_GLYPH if index == count - 1 else _BRANCH_MIDDLE_GLYPH


## Prints [param messages] as a branch list, selecting the last branch glyph for the final item.
func _print_messages_tree(
	messages: Array[GodotDoctorValidationMessage], treat_warnings_as_errors: bool
) -> void:
	var msg_count: int = messages.size()

	for i: int in range(msg_count):
		var branch: String = _get_message_branch(i, msg_count)
		_print_message_tree(messages[i], branch, treat_warnings_as_errors)


## Prints a single [param msg] using [param branch] as the tree connector character.
## [param treat_warnings_as_errors] controls whether warnings are displayed as errors.
func _print_message_tree(
	msg: GodotDoctorValidationMessage, branch: String, treat_warnings_as_errors: bool
) -> void:
	var label: String = _severity_label(msg, treat_warnings_as_errors)
	var padded: String = label.rpad(_SEVERITY_LABEL_WIDTH)
	# Check by label here as it may differ from the message's
	# actual severity level if warnings are treated as errors.
	var color: Color = _severity_color(label)

	_print_rich_text("%s%s %s %s" % [_indent(3), branch, padded, msg.message], color)


## Returns a human-readable severity label for [param msg].
## If [param treat_warnings_as_errors] is [code]true[/code], warnings are labelled "WARNING→ERROR".
func _severity_label(msg: GodotDoctorValidationMessage, treat_warnings_as_errors: bool) -> String:
	if treat_warnings_as_errors and msg.severity_level == ValidationCondition.Severity.WARNING:
		return _SEVERITY_LABEL_WARNING_AS_ERROR

	return ValidationCondition.Severity.keys()[msg.severity_level]


## Returns the display [Color] associated with [param label].
func _severity_color(label: String) -> Color:
	match label:
		"INFO":
			return ReportColors.INFO
		"WARNING":
			return ReportColors.WARNING
		"ERROR", _SEVERITY_LABEL_WARNING_AS_ERROR:
			return ReportColors.ERROR
	return ReportColors.INFO


#endregion

#region Print primitives


## Prints a pass/fail tree section at [param indent_level] with [param heading_label]
## and a glyph representing [param passed], followed by a tree item with [param tree_text] in
## [param tree_color].
func _print_pass_fail_tree_section(
	indent_level: int, heading_label: String, passed: bool, tree_text: String, tree_color: Color
) -> void:
	_print_state_heading(indent_level, heading_label, passed)
	_print_tree_item(indent_level, tree_text, tree_color)


## Prints an optional warning mode note if [param treat_warnings_as_errors] is [code]true[/code].
func _print_warning_mode_if_needed(treat_warnings_as_errors: bool) -> void:
	if not treat_warnings_as_errors:
		return

	_print_rich_text("%s%s" % [_indent(1), _MSG_WARNINGS_TREATED_AS_ERRORS], ReportColors.WARNING)


## Prints a message section with [param heading_label] at [param heading_indent_level] which
## indicates pass/fail status with [param passed],
## followed by a tree item with [param tree_text] in [param tree_color],
## and then a branch list of [param messages] with severity colors
## determined by [param treat_warnings_as_errors].
func _print_message_section(
	heading_indent_level: int,
	heading_label: String,
	passed: bool,
	messages: Array[GodotDoctorValidationMessage],
	treat_warnings_as_errors: bool,
	tree_text: String = "",
	tree_color: Color = ReportColors.INFO
) -> void:
	_print_state_heading(heading_indent_level, heading_label, passed)

	if not tree_text.is_empty():
		_print_tree_item(heading_indent_level, tree_text, tree_color)

	_print_messages_tree(messages, treat_warnings_as_errors)


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
	_print_rich_text(
		"%s%s %d" % [_indent(indent_level), label.rpad(_COUNT_LABEL_WIDTH), count], color
	)


## Prints [param text] to stdout using [param color] as the rich-text foreground color.
func _print_rich_text(text: String, color: Color) -> void:
	print_rich("[color=%s]%s[/color]" % [color.to_html(), text])


## Prints a summary tree entry with [param branch] in [constant ReportColors.TOTALS] and
## [param label] + [param count] right-aligned at
## [constant _SUMMARY_COLUMN] in [param content_color].
func _print_summary_tree_line(
	branch: String, label: String, count: int, content_color: Color
) -> void:
	var content: String = "%s%d" % [label.rpad(_SUMMARY_TREE_LABEL_WIDTH), count]
	print_rich(
		(
			"[color=%s]%s [/color][color=%s]%s[/color]"
			% [ReportColors.TOTALS.to_html(), branch, content_color.to_html(), content]
		)
	)


## Returns an indentation string repeated [param level] times.
func _indent(level: int) -> String:
	return " ".repeat(_INDENT_SIZE).repeat(level)


## Returns a checkmark icon if [param passed] is [code]true[/code],
## or a cross icon if [param passed] is [code]false[/code].
func _get_state_icon(passed: bool) -> String:
	return _PASSED_GLYPH if passed else _FAILED_GLYPH


## Returns a display color for the pass/fail state represented by [param passed].
func _get_state_color(passed: bool) -> Color:
	return ReportColors.PASSED if passed else ReportColors.FAILED


#endregion

#region Path utilities


## Resolves [param path] from a [code]uid://[/code] string to a filesystem path.
## Returns [param path] unchanged if it is already a filesystem path.
func _resolve_uid_path(path: String) -> String:
	if path.begins_with("uid://"):
		return ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	return path

#endregion
