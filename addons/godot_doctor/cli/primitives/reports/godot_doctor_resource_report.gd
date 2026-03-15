## Holds the validation _messages collected for a single _resource during a CLI validation run.
class_name GodotDoctorResourceReport
extends GodotDoctorReport

## The [GodotDoctorSuiteReport] this report belongs to.
var _suite_report: GodotDoctorSuiteReport
## The validated [Resource].
var _resource: Resource


## Initializes the report with [param _resource] and [param _messages].
func _init(
	suite_report: GodotDoctorSuiteReport,
	resource: Resource,
	messages: Array[GodotDoctorValidationMessage]
) -> void:
	_suite_report = suite_report
	_resource = resource
	_messages = messages


#region Abstract Method Implementations


func _collect_messages() -> Array[GodotDoctorValidationMessage]:
	return _messages


func get_effective_error_count() -> int:
	return _get_effective_error_count(_suite_report.get_suite().treat_warnings_as_errors)


func get_warnings_treated_as_errors_count() -> int:
	return _get_warnings_treated_as_errors_count(_suite_report.get_suite().treat_warnings_as_errors)


#endregion


func get_suite_report() -> GodotDoctorSuiteReport:
	return _suite_report


func get_resource() -> Resource:
	return _resource


func teardown() -> void:
	super.teardown()
	_suite_report = null
	_resource = null
