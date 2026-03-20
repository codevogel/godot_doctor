#gdlint: disable=max-line-length

## Validation reporter for headless / CLI mode.
## Delegates rendering to [GodotDoctorReportPrinter] using report objects
## built from validation collections.
## Exits the process with an appropriate code when validation is complete.
class_name GodotDoctorCLIValidationReporter
extends GodotDoctorValidationReporter


## No-op override; scene results are reported through [method report_on_validation_suite_collection].
func report_on_scene_validation_collection(
	_scene_validation_collection: GodotDoctorSceneValidationCollection
) -> void:
	pass


## No-op override; resource results are reported through [method report_on_validation_suite_collection].
func report_on_resource_validation_collection(
	_resource_validation_collection: GodotDoctorResourceValidationCollection
) -> void:
	pass


## Generates and prints a full validation report from [param validation_suite_collection].
## Also exports a JUnit XML report if configured in settings.
## Returns [code]true[/code] if all validation passed, [code]false[/code] otherwise.
func report_on_validation_suite_collection(
	validation_suite_collection: GodotDoctorValidationSuiteValidationCollection
) -> bool:
	var validation_suite_reports: Array[GodotDoctorValidationSuiteReport] = _create_validation_suite_reports_from_validation_suite_validation_collection(
		validation_suite_collection
	)
	var summary_report: GodotDoctorSummaryReport = _create_summary_report_from_validation_suite_reports(
		validation_suite_reports
	)
	var summary_stats: Dictionary = summary_report.get_stats()

	var printer: GodotDoctorReportPrinter = GodotDoctorReportPrinter.new()
	printer.print_validation_results(validation_suite_reports, summary_stats)

	var settings: GodotDoctorSettings = GodotDoctorPlugin.instance.settings
	if settings.export_xml_report:
		var xml_exporter: GodotDoctorJUnitXmlReportExporter = (
			GodotDoctorJUnitXmlReportExporter.new()
		)
		xml_exporter.export_report_from_suite_reports(validation_suite_reports, summary_stats)

	return summary_stats[GodotDoctorSummaryReport.Stat.PASSED]


## Creates a [GodotDoctorSummaryReport] from [param validation_suite_reports].
func _create_summary_report_from_validation_suite_reports(
	validation_suite_reports: Array[GodotDoctorValidationSuiteReport]
) -> GodotDoctorSummaryReport:
	return GodotDoctorSummaryReport.new(validation_suite_reports)


## Builds an array of [GodotDoctorValidationSuiteReport] instances
## from [param validation_suite_validation_collection].
func _create_validation_suite_reports_from_validation_suite_validation_collection(
	validation_suite_validation_collection: GodotDoctorValidationSuiteValidationCollection
) -> Array[GodotDoctorValidationSuiteReport]:
	var validation_suite_to_scene_validation_collection_map: Dictionary = (
		validation_suite_validation_collection
		. get_validation_suite_to_scene_validation_collection_map()
	)
	var validation_suite_to_resource_validation_collection_map: Dictionary = (
		validation_suite_validation_collection
		. get_validation_suite_to_resource_validation_collection_map()
	)
	var validation_suites: Array = []
	for validation_suite in validation_suite_to_scene_validation_collection_map.keys():
		if not validation_suites.has(validation_suite):
			validation_suites.append(validation_suite)
	for validation_suite in validation_suite_to_resource_validation_collection_map.keys():
		if not validation_suites.has(validation_suite):
			validation_suites.append(validation_suite)

	var validation_suite_reports: Array[GodotDoctorValidationSuiteReport] = []
	for validation_suite in validation_suites:
		var scene_validation_collection: GodotDoctorSceneValidationCollection = null
		if validation_suite_to_scene_validation_collection_map.has(validation_suite):
			scene_validation_collection = validation_suite_to_scene_validation_collection_map[validation_suite]

		var resource_validation_collection: GodotDoctorResourceValidationCollection = null
		if validation_suite_to_resource_validation_collection_map.has(validation_suite):
			resource_validation_collection = validation_suite_to_resource_validation_collection_map[validation_suite]

		var scene_reports: Array[GodotDoctorSceneReport] = []
		if scene_validation_collection != null:
			scene_reports = _create_scene_reports_from_scene_validation_collection(
				scene_validation_collection
			)

		var resource_reports: Array[GodotDoctorResourceReport] = []
		if resource_validation_collection != null:
			resource_reports = _create_resource_reports_from_resource_validation_collection(
				resource_validation_collection
			)

		validation_suite_reports.append(
			_create_validation_suite_report(validation_suite, scene_reports, resource_reports)
		)

	return validation_suite_reports


## Builds an array of [GodotDoctorSceneReport] instances from [param scene_validation_collection].
func _create_scene_reports_from_scene_validation_collection(
	scene_validation_collection: GodotDoctorSceneValidationCollection
) -> Array[GodotDoctorSceneReport]:
	var scene_path_to_node_validation_collection_map: Dictionary = (
		scene_validation_collection.get_scene_path_to_node_validation_collection_map()
	)
	var scene_reports: Array[GodotDoctorSceneReport] = []
	for scene_path in scene_path_to_node_validation_collection_map.keys():
		var node_validation_collection: GodotDoctorNodeValidationCollection = scene_path_to_node_validation_collection_map[scene_path]
		var node_reports: Array[GodotDoctorNodeReport] = _create_node_reports_from_node_validation_collection(
			node_validation_collection
		)
		scene_reports.append(_create_scene_report(scene_path, node_reports))

	return scene_reports


## Builds an array of [GodotDoctorResourceReport] instances from [param resource_validation_collection].
func _create_resource_reports_from_resource_validation_collection(
	resource_validation_collection: GodotDoctorResourceValidationCollection
) -> Array[GodotDoctorResourceReport]:
	var resource_path_to_validation_messages_map: Dictionary = (
		resource_validation_collection.get_resource_path_to_validation_messages_map()
	)
	var resource_reports: Array[GodotDoctorResourceReport] = []
	for resource in resource_path_to_validation_messages_map.keys():
		var validation_messages: Array[GodotDoctorValidationMessage] = resource_path_to_validation_messages_map[resource]
		resource_reports.append(_create_resource_report(resource, validation_messages))

	return resource_reports


## Builds an array of [GodotDoctorNodeReport] instances from [param node_validation_collection].
func _create_node_reports_from_node_validation_collection(
	node_validation_collection: GodotDoctorNodeValidationCollection
) -> Array[GodotDoctorNodeReport]:
	var node_ancestor_path_to_validation_messages_map: Dictionary = (
		node_validation_collection.get_node_ancestor_path_to_validation_messages_map()
	)
	var node_reports: Array[GodotDoctorNodeReport] = []
	for node in node_ancestor_path_to_validation_messages_map.keys():
		var validation_messages: Array[GodotDoctorValidationMessage] = node_ancestor_path_to_validation_messages_map[node]
		node_reports.append(_create_node_report(node, validation_messages))

	return node_reports


## Creates a [GodotDoctorValidationSuiteReport] from [param validation_suite],
## [param scene_reports], and [param resource_reports].
func _create_validation_suite_report(
	validation_suite: GodotDoctorValidationSuite,
	scene_reports: Array[GodotDoctorSceneReport],
	resource_reports: Array[GodotDoctorResourceReport]
) -> GodotDoctorValidationSuiteReport:
	return GodotDoctorValidationSuiteReport.new(validation_suite, scene_reports, resource_reports)


## Creates a [GodotDoctorSceneReport] for [param scene_path] with [param node_reports].
func _create_scene_report(
	scene_path: String, node_reports: Array[GodotDoctorNodeReport]
) -> GodotDoctorSceneReport:
	return GodotDoctorSceneReport.new(scene_path, node_reports)


## Creates a [GodotDoctorNodeReport] for [param node_ancestor_path] with [param validation_messages].
func _create_node_report(
	node_ancestor_path: String, validation_messages: Array[GodotDoctorValidationMessage]
) -> GodotDoctorNodeReport:
	return GodotDoctorNodeReport.new(node_ancestor_path, validation_messages)


## Creates a [GodotDoctorResourceReport] for [param resource_path] with [param validation_messages].
func _create_resource_report(
	resource_path: String, validation_messages: Array[GodotDoctorValidationMessage]
) -> GodotDoctorResourceReport:
	return GodotDoctorResourceReport.new(resource_path, validation_messages)


## Unused override; scene results are handled at suite level. No-op.
func _report_on_scene_validation_collection(
	_scene_validation_collection: GodotDoctorSceneValidationCollection
) -> void:
	pass


## Unused override; resource results are handled at suite level. No-op.
func _report_on_resource_validation_collection(
	_resource_validation_collection: GodotDoctorResourceValidationCollection
) -> void:
	pass
