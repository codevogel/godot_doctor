## Validation reporter for headless / CLI mode.
## Delegates report data collection to [GodotDoctorReportCollection] and
## rendering to [GodotDoctorReportPrinter].
## Exits the process with an appropriate code when validation is complete.
class_name GodotDoctorCLIValidationReporter
extends GodotDoctorValidationReporter

## The currently active validation suite.
## This is set externally by the [GodotDoctorCliRunner] before validating each suite.
var current_suite: GodotDoctorValidationSuite:
	set(value):
		_collection.set_current_suite(value)

## The currently active scene path.
## This is set externally by the [GodotDoctorCliRunner] before validating each scene.
var current_scene_resource_path: String:
	set(value):
		_collection.set_current_scene_path(value)

var _collection: GodotDoctorReportCollection = GodotDoctorReportCollection.new()
var _printer: GodotDoctorReportPrinter = GodotDoctorReportPrinter.new()


## Records the validation [param messages] for [param node]
## into the current suite report under the current scene.
func report_node_messages(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void:
	_collection.report_node_messages(node, messages)


## Records the validation [param messages] for [param resource] into the current suite report.
func report_resource_messages(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void:
	_collection.report_resource_messages(resource, messages)


## Prints all collected validation results to stdout and exits the process.
## Exits with code [code]0[/code] if there are no errors, or [code]1[/code] if there are errors.
func on_validation_complete() -> void:
	var suite_reports: Array[GodotDoctorSuiteReport] = _collection.get_suite_reports_array()
	var summary: GodotDoctorReportSummary = GodotDoctorReportSummary.new(suite_reports)

	_printer.print_validation_results(summary, suite_reports)

	if GodotDoctorPlugin.instance.settings.export_xml_report:
		GodotDoctorJUnitXmlReportExporter.new().export_report(summary)

	var exit_code: int = 0 if summary.passed() else 1

	_collection.teardown()

	GodotDoctorPlugin.instance.quit_with_code(exit_code)
