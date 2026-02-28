## UI based implementation of the [ValidatorOutputInterface]. Outputs information to the console,
## as well as collects error and warning data to be processed by the CLI validation logic.
class_name ValidatorCLIOutput
extends ValidatorOutputInterface

# ============================================================================
# HELPER TYPES
# ============================================================================

## String used when printing warnings that need to be treated as errors.
const WARNING_AS_ERROR_TITLE: String = "WARNING AS ERROR"

# ============================================================================
# HELPER TYPES
# ============================================================================


## Helper class used to store the results of validation of a given object.
class Result:
	var object_name: String
	var message: String
	var severity: ValidationCondition.Severity

	func _init(name: String, validation_message: ValidationMessage) -> void:
		object_name = name
		message = validation_message.message
		severity = validation_message.severity_level


# ============================================================================
# PRIVATE PROPERTIES
# ============================================================================

## Array holding all validation results of the currently validated object.
var _results: Array[Result]

# ============================================================================
# CORE INTERFACE
# ============================================================================


## Function that outputs the input [param message] and formats it
## according to the input [param severity] taking into conisideration
## whether a warning needs be output as an error [param warning_as_error].
## Used for showing information about the validation process as a whole and not specific tests.
func print_global_message(
	message: String,
	severity: ValidationCondition.Severity = ValidationCondition.Severity.INFO,
	warning_as_error: bool = false
) -> void:
	if warning_as_error and severity == ValidationCondition.Severity.WARNING:
		_print_formated_message(
			"", message, ValidationCondition.Severity.ERROR, WARNING_AS_ERROR_TITLE
		)
	else:
		_print_formated_message("", message, severity)


## Function that prints out information about the input validation [param result],
## taking into conisideration whether a warning needs be output
## as an error [param warning_as_error].
func print_result(result: Result, warning_as_error: bool = false) -> void:
	if warning_as_error and result.severity == ValidationCondition.Severity.WARNING:
		_print_formated_message(
			"\t\t", result.message, ValidationCondition.Severity.ERROR, WARNING_AS_ERROR_TITLE
		)
	else:
		_print_formated_message("\t\t", result.message, result.severity)


## Function that prints a custom validation warning with input [param message],
## taking into conisideration whether a warning needs be output
## as an error [param warning_as_error].
## Used when a warning is not attached to a validation result.
func print_warning(message: String, warning_as_error: bool = false) -> void:
	if warning_as_error:
		_print_formated_message(
			"\t\t", message, ValidationCondition.Severity.ERROR, WARNING_AS_ERROR_TITLE
		)
	else:
		_print_formated_message("\t\t", message, ValidationCondition.Severity.WARNING)


## Function that prints a custom validation error with input [param message].
## Used when an error is not attached to a validation result.
func print_error(message: String) -> void:
	_print_formated_message("\t\t", message, ValidationCondition.Severity.ERROR)


## Accessor returning [_results] - all validation results of the currently validated object.
func get_results() -> Array[Result]:
	return _results


## Clears [_results] and allows for validation of the next object.
func clear_results() -> void:
	_results.clear()


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================


## Helper function that outputs the input [param message]
## and formats it according to the input [param severity]
## and addes the input [param prefix] at the begining.
## The optional [param severity_name] can be used
## to display a custom title describing the type of message being shown.
func _print_formated_message(
	prefix: String,
	message: String,
	severity: ValidationCondition.Severity,
	severity_name: String = ""
) -> void:
	# If the severity name is not set, use the default one for the input severity.
	if severity_name.is_empty():
		severity_name = ValidationCondition.Severity.find_key(severity)

	# Format and print the message accordingly.
	if severity == ValidationCondition.Severity.INFO:
		print_rich(prefix + "[b]" + severity_name + ": [/b]%s" % message)
	elif severity == ValidationCondition.Severity.WARNING:
		print_rich(prefix + "[color=orange][b]" + severity_name + ": [/b]%s[/color]" % message)
	elif severity == ValidationCondition.Severity.ERROR:
		print_rich(prefix + "[color=red][b]" + severity_name + ": [/b]%s[/color]" % message)


# ============================================================================
# ABSTRACT INTERAFACE IMPLMENTATION - Implementation of the functions from ValidatorOutputInterface
# ============================================================================


## Normally this pushes a toast notification to the editor toaster. However, this is irrelevant
## in the CLI as we have all the information already.s
func push_toast(_message: String, _severity: int = 0) -> void:
	pass


## Adds warning from the validation of the input [param origin_node],
## with the input [param validation_message] to the [_results] list.
func add_node_warning(origin_node: Node, validation_message: ValidationMessage) -> void:
	_results.append(Result.new(origin_node.name, validation_message))


## Adds warning from the validation of the input [param origin_resource],
## with the input [param validation_message] to the [_results] list.
func add_resource_warning(origin_resource: Resource, validation_message: ValidationMessage) -> void:
	_results.append(Result.new(origin_resource.name, validation_message))
