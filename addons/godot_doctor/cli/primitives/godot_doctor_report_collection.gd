## Accumulates [GodotDoctorSuiteReport]s during a CLI validation run.
## Receives raw node and resource messages from the validator and organises them
## into a hierarchy of suite → scene → node / resource reports.
class_name GodotDoctorReportCollection
extends RefCounted

const _ANCESTOR_SEPARATOR_GLYPH: String = " -> "

## The currently active validation suite.
## Set by [GodotDoctorCLIValidationReporter] before validating each suite.
var _current_suite: GodotDoctorValidationSuite

## The filesystem path of the scene currently being validated.
## Set by [GodotDoctorCLIValidationReporter] before validating each scene.
var _current_scene_resource_path: String

## A mapping of [GodotDoctorValidationSuite] to their collected [GodotDoctorSuiteReport]s,
## kept in insertion order so suite output is deterministic.
var _suite_reports: Dictionary = {}


## Sets the active suite for subsequent [method report_node_messages] /
## [method report_resource_messages] calls.
func set_current_suite(suite: GodotDoctorValidationSuite) -> void:
	_current_suite = suite


## Sets the active scene path for subsequent [method report_node_messages] calls.
func set_current_scene_path(path: String) -> void:
	_current_scene_resource_path = path


## Records the validation [param messages] for [param node]
## into the current suite report under the current scene.
func report_node_messages(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void:
	var suite_report: GodotDoctorSuiteReport = _get_or_create_current_suite_report()
	var scene_report: GodotDoctorSceneReport = _get_or_create_scene_report(suite_report)

	var node_report: GodotDoctorNodeReport = GodotDoctorNodeReport.new(
		suite_report, messages, node.name, _get_node_ancestor_path(node)
	)
	scene_report.add_node_report(node_report)


## Records the validation [param messages] for [param resource]
## into the current suite report.
func report_resource_messages(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void:
	var suite_report: GodotDoctorSuiteReport = _get_or_create_current_suite_report()

	var resource_report: GodotDoctorResourceReport = GodotDoctorResourceReport.new(
		suite_report, resource, messages
	)
	suite_report.add_resource_report(resource_report)


## Returns all collected [GodotDoctorSuiteReport]s as an ordered array.
func get_suite_reports_array() -> Array[GodotDoctorSuiteReport]:
	var result: Array[GodotDoctorSuiteReport] = []
	for suite_report in _suite_reports.values():
		result.append(suite_report)
	return result


## Releases all collected reports and resets state, preventing memory leaks.
func teardown() -> void:
	for suite_report: GodotDoctorSuiteReport in _suite_reports.values():
		suite_report.teardown()
	_suite_reports.clear()
	_current_suite = null
	_current_scene_resource_path = ""


## Returns the report for the current suite, creating and storing it if needed.
func _get_or_create_current_suite_report() -> GodotDoctorSuiteReport:
	if _suite_reports.has(_current_suite):
		return _suite_reports[_current_suite]

	var suite_report: GodotDoctorSuiteReport = GodotDoctorSuiteReport.new(_current_suite, [], [])
	_suite_reports[_current_suite] = suite_report
	return suite_report


## Returns the scene report for [member _current_scene_resource_path] inside
## [param suite_report], creating and registering it when absent.
func _get_or_create_scene_report(
	suite_report: GodotDoctorSuiteReport,
) -> GodotDoctorSceneReport:
	for scene_report: GodotDoctorSceneReport in suite_report.get_scene_reports():
		if scene_report.get_scene_path() == _current_scene_resource_path:
			return scene_report

	var scene_report_new: GodotDoctorSceneReport = GodotDoctorSceneReport.new(
		_current_scene_resource_path, []
	)
	suite_report.add_scene_report(scene_report_new)
	return scene_report_new


## Returns a human-readable path string for [param node] by walking up its ancestor chain.
static func _get_node_ancestor_path(node: Node) -> String:
	var names: Array[String] = []
	var current: Node = node

	while current != null:
		names.push_front(current.name)

		if current.owner == null:
			break

		current = current.get_parent()

	return _ANCESTOR_SEPARATOR_GLYPH.join(names)
