@abstract class_name GodotDoctorReport
extends RefCounted

## The [GodotDoctorValidationMessage]s produced for this node.
var _messages: Array[GodotDoctorValidationMessage]

## The number of messages that count as [constant ValidationCondition.Severity.ERROR]
## across all messages contained in this report,
## including those that were originally reported with severity level
## [constant ValidationCondition.Severity.WARNING] but were promoted to errors.
@abstract func get_effective_error_count() -> int

## The number of messages that were originally reported with severity level
## [constant ValidationCondition.Severity.WARNING] but were promoted to
## [constant ValidationCondition.Severity.ERROR] across all messages contained in this report.
@abstract func get_warnings_treated_as_errors_count() -> int

## Collects all [GodotDoctorValidationMessage]s contained in this report
## and returns them as an array.
@abstract func _collect_messages() -> Array[GodotDoctorValidationMessage]


## Gets all [GodotDoctorValidationMessage]s contained in this report.
func get_messages() -> Array[GodotDoctorValidationMessage]:
	if _messages == null:
		_messages = _collect_messages()
	return _messages


## Releases owned references to support deterministic teardown in CLI mode.
func teardown() -> void:
	if _messages != null:
		_messages.clear()
	_messages = []


## The number of messages that have a severity level of
## [constant ValidationCondition.Severity.INFO] across all messages contained in this report.
func get_info_messages_count() -> int:
	return _filter_on_severity_level(get_messages(), ValidationCondition.Severity.INFO).size()


## The number of messages that have a severity level of
## [constant ValidationCondition.Severity.WARNING] across all messages contained in this report.
func get_warning_messages_count() -> int:
	return _filter_on_severity_level(get_messages(), ValidationCondition.Severity.WARNING).size()


## The number of messages that have a severity level of
## [constant ValidationCondition.Severity.ERROR] across all messages contained in this report.
func get_hard_error_messages_count() -> int:
	return _filter_on_severity_level(get_messages(), ValidationCondition.Severity.ERROR).size()


## Returns whether this report contains any message that counts as an error
func passed() -> bool:
	return get_effective_error_count() == 0


## Filters the given [param messages] by the given [param severity_level]
## and returns the filtered array.
func _filter_on_severity_level(
	messages: Array[GodotDoctorValidationMessage], severity_level: ValidationCondition.Severity
) -> Array[GodotDoctorValidationMessage]:
	return messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool: return m.severity_level == severity_level
	)


#region Helper Methods for Abstract Method Implementations


## Call this with [param promote_warnings_to_errors] in the implementation of the
## public abstract method to avoid code duplication.
func _get_effective_error_count(promote_warnings_to_errors: bool) -> int:
	var effective_error_count = get_hard_error_messages_count()
	if promote_warnings_to_errors:
		effective_error_count += get_warning_messages_count()
	return effective_error_count


## Call this with [param promote_warnings_to_errors] in the implementation of the
## public abstract method to avoid code duplication.
func _get_warnings_treated_as_errors_count(promote_warnings_to_errors: bool) -> int:
	if promote_warnings_to_errors:
		return get_warning_messages_count()
	return 0

#endregion
