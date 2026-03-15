## Abstract base class for reports that belong to a [GodotDoctorSuiteReport].
## Concrete subclasses, such as [GodotDoctorNodeReport] and [GodotDoctorResourceReport],
## represent individual items validated within a [GodotDoctorValidationSuite].
## Delegates error-counting behaviour to the suite's [member GodotDoctorValidationSuite.treat_warnings_as_errors] flag.
@abstract class_name GodotDoctorSuiteItemReport
extends GodotDoctorReport

## The [GodotDoctorSuiteReport] this report belongs to.
var _suite_report: GodotDoctorSuiteReport


## Initializes suite-scoped state shared by concrete report types.
func _init(
	suite_report: GodotDoctorSuiteReport, messages: Array[GodotDoctorValidationMessage]
) -> void:
	_suite_report = suite_report
	_messages = messages


## Returns the [GodotDoctorSuiteReport] this item report belongs to.
func get_suite_report() -> GodotDoctorSuiteReport:
	return _suite_report

func teardown() -> void:
	super.teardown()
	_suite_report = null


#region Abstract Method Implementations


func _collect_messages() -> Array[GodotDoctorValidationMessage]:
	return _messages


func get_effective_error_count() -> int:
	return _get_effective_error_count(_suite_report.get_suite().treat_warnings_as_errors)


func get_warnings_treated_as_errors_count() -> int:
	return _get_warnings_treated_as_errors_count(_suite_report.get_suite().treat_warnings_as_errors)


#endregion



