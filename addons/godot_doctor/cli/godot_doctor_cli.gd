## CLI based wrapper around the [Validator]. Used to run validations offline in a batch.
## Uses [CLIValidationSettings] as source of information. Will print all results to the terminal.
class_name GodotDoctorCLI
extends Node

# ============================================================================
# HELPER TYPES
# ============================================================================

## Enum defining quit value of the application, needed in CI systems to notify if the validation
## process has succeeded or failed.
enum ExitCode { EXIT_OK, EXIT_FAIL }

# ============================================================================
# CONSTANTS
# ============================================================================

## Path to the plugin configuration file. The process will fail if the plugin is installed
## in a different than default directory. However, the common process is not to move plugins.
const PLUGIN_CFG_PATH: String = "res://addons/godot_doctor/plugin.cfg"

# ============================================================================
# PRIVATE PROPERTIES
# ============================================================================

## Settings for the batch validation, contains all scenes and resources that are to be validated.
var _cli_validation_settings: CLIValidationSettings

var _output: ValidatorCLIOutput

## The validator object, this the main object, it does all the actual validation logic.
var _validator: Validator

## Flag marking if the current iteration is processing a new suite,
## (one that has not been processed yet).
var _new_suite: bool = true

## Stores the index of the Validation Suite that is currently processed.
var _current_suite_idx: int = 0

## Stores the index of the Scene in the current Validation Suite that is currently processed.
var _current_scene_idx: int = 0

## Stores the index of the Resource in the current Validation Suite that is currently processed.
var _current_resource_idx: int = 0

## The amount of warnings that the validation process has generated.
var _warning_count: int = 0

## The amount of errors that the validation process has generated.
var _error_count: int = 0

## The total amount of tests that have been processed.
var _test_count: int = 0

## The total amount of tests that have been passed.
var _passing_test_count: int = 0

## The total amount of tests that have been failed.
var _ignore_test_count: int = 0

## The total amount of tests that have been failed.
var _fail_test_count: int = 0

## The total amount of Validation Suites that have been processed.
var _suite_count: int = 0

## The total time the validation process has taken
var _total_time: int

## The node path to this node. Used for printing nicely path within the scene structure
## of the validated node.
var _base_path: String

# ============================================================================
# INITIALIZATION
# ============================================================================


## Basic initialization of the CLI validation process - mostly loads settings.
func _ready() -> void:
	# Initialize the settings.
	var godot_doctor_settings: GodotDoctorSettings = GodotDoctorPlugin.settings
	_cli_validation_settings = godot_doctor_settings.cli_validation_settings

	# If the CLI validation settings couldn't be loaded, the whole process can't run. We need report
	# a total failure.
	if _cli_validation_settings == null:
		push_error("Couldn't find CLI Validation Settings.")
		get_tree().quit(ExitCode.EXIT_FAIL)
		return

	# Store our node path, for parsing during validation.
	_base_path = get_path()

	# Initialise the validator with CLI output interface.
	_output = ValidatorCLIOutput.new()
	_validator = Validator.new(_output)

	# Load the plugin configuration file to get the current plugin version.
	var config = ConfigFile.new()
	var error: Error = config.load(PLUGIN_CFG_PATH)

	# If the configuration file hasn't loaded correctly, quit early.
	if error != Error.OK:
		# If the configuration file couldn't be read, something went very wrong, stop processing and
		# report an error.
		push_error("Couldn't read Godot Doctor plugin configuration file: " + PLUGIN_CFG_PATH + ".")
		get_tree().quit(ExitCode.EXIT_FAIL)
		return
	var plugin_version: String = config.get_value("plugin", "version", "1.0")
	print_rich("Starting [color=blue][b]Godot Doctor[/b][/color] v" + plugin_version + ".")


# ============================================================================
# CORE LOGIC - Main loop
# ============================================================================


## Main loop running the validation process. Will take one test (scene or resource) per frame,
## validate it, until all tests have been run.
func _process(_delta: float) -> void:
	var suite: ValidationSuite = _get_current_suite()
	if suite == null:
		return

	_enter_suite_if_new(suite)
	_warn_if_suite_empty(suite)
	_process_current_item(suite)
	_advance_to_next_item_or_end()


# ============================================================================
# CORE LOGIC - Suite and item processing
# ============================================================================


## Returns the current suite, quitting with an error if it is null.
func _get_current_suite() -> ValidationSuite:
	var suite: ValidationSuite = _cli_validation_settings.suites[_current_suite_idx]
	if suite == null:
		push_error("Found null in the Validation Suite list.")
		get_tree().quit(ExitCode.EXIT_FAIL)
	return suite


## Prints the suite header and increments the suite counter when entering a new suite.
func _enter_suite_if_new(suite: ValidationSuite) -> void:
	if not _new_suite:
		return
	print_rich("\n[color=blue]Running validation suite: [/color]", suite.name)
	_suite_count += 1
	_new_suite = false


## Emits a warning if the suite contains no scenes or resources to validate.
func _warn_if_suite_empty(suite: ValidationSuite) -> void:
	if suite.scenes.is_empty() and suite.resources.is_empty():
		_output.print_global_message(
			"Suite " + suite.name + " doesn't contain any validations.",
			ValidationCondition.Severity.WARNING
		)


## Loads and processes the next scene or resource in the current suite.
func _process_current_item(suite: ValidationSuite) -> void:
	if suite.scenes.size() > _current_scene_idx:
		var scene: PackedScene = _load_resource(suite.scenes[_current_scene_idx])
		if scene == null:
			push_error("Scene at path " + suite.scenes[_current_scene_idx] + " couldn't be loaded.")
			return
		_process_scene(scene)
		return

	if suite.resources.size() > _current_resource_idx:
		var resource: Resource = _load_resource(suite.resources[_current_resource_idx])
		if resource == null:
			push_error(
				(
					"Resource at path "
					+ suite.resources[_current_resource_idx]
					+ " couldn't be loaded."
				)
			)
			return
		_process_resource(resource)


## Advances the internal indices to the next scene, resource, or suite.
## Calls [_end] and quits if all items have been processed.
func _advance_to_next_item_or_end() -> void:
	var suite: ValidationSuite = _cli_validation_settings.suites[_current_suite_idx]

	if _current_scene_idx + 1 < suite.scenes.size():
		_current_scene_idx += 1

	elif _current_resource_idx + 1 < suite.resources.size():
		_current_resource_idx += 1

	elif _current_suite_idx + 1 < _cli_validation_settings.suites.size():
		_current_suite_idx += 1
		_current_scene_idx = 0
		_current_resource_idx = 0
		_new_suite = true

	else:
		var exit_code: ExitCode = _end()
		_output.push_debug("Exiting with " + ExitCode.find_key(exit_code) + ".")
		get_tree().quit(exit_code)


## Validates a single [PackedScene], instantiating it and running all node validations within.
func _process_scene(scene: PackedScene) -> void:
	var t: int = Time.get_ticks_usec()
	print("* " + scene.resource_path)

	if not scene.can_instantiate():
		_process_uninstantiable_scene(scene)
	else:
		_process_instantiable_scene(scene)

	_total_time += Time.get_ticks_usec() - t


## Handles the failure case where a [PackedScene] cannot be instantiated.
func _process_uninstantiable_scene(scene: PackedScene) -> void:
	var name: String = scene.resource_name
	if name.is_empty():
		name = scene.resource_path.get_file()

	print_rich("\t[color=red][Failed] : [/color]", name)
	_output.print_error("Couldn't instantiate scene.")

	_test_count += 1
	_fail_test_count += 1
	_error_count += 1


## Instantiates the scene, finds all validatable nodes, and runs validation on each.
func _process_instantiable_scene(scene: PackedScene) -> void:
	var node: Node = scene.instantiate()
	add_child(node)

	var nodes_to_validate: Array = _validator.find_nodes_to_validate_in_tree(node)
	_output.push_debug(
		(
			"Found "
			+ str(nodes_to_validate.size())
			+ " nodes to validate in scene "
			+ scene.resource_path
			+ "."
		)
	)

	if nodes_to_validate.is_empty():
		_process_ignore(node.name, "Scene has nothing to validate.")
	else:
		_validate_nodes(nodes_to_validate)

	remove_child(node)
	node.queue_free()


## Runs validation on each node in [param nodes_to_validate] and processes results.
func _validate_nodes(nodes_to_validate: Array) -> void:
	for n: Node in nodes_to_validate:
		var name: String = n.get_path()
		name = name.substr(_base_path.length() + 1)
		_validator.validate_node(n)
		_process_results(name)


## Validates a single [Resource] and processes the results.
func _process_resource(resource: Resource) -> void:
	var t: int = Time.get_ticks_usec()
	print("* " + resource.resource_path)

	var name: String = resource.resource_name
	if name.is_empty():
		name = resource.resource_path.get_file()

	_validator.validate_resource(resource)
	_process_results(name)

	_total_time += Time.get_ticks_usec() - t


# ============================================================================
# HELPER METHODS
# ============================================================================


## Function that attempts to load a resource from the input path, but does it safely -
## checks if the file exists and can be loaded, and if necessary reports found errors.
func _load_resource(path: String) -> Resource:
	var suite: ValidationSuite = _cli_validation_settings.suites[_current_suite_idx]

	if path.is_empty():
		_output.print_global_message(
			"Empty path found in suite " + suite.name + ".",
			ValidationCondition.Severity.WARNING,
			_should_fail_on_warning(suite)
		)
		_warning_count += 1
		return null

	if not FileAccess.file_exists(path):
		_output.print_global_message(
			"File " + path + " not found in suite " + suite.name + ".",
			ValidationCondition.Severity.ERROR
		)
		_error_count += 1
		return null

	var resource: Resource = load(path)

	if resource == null:
		_output.print_global_message(
			"Couldn't load file " + path + " in suite " + suite.name + ".",
			ValidationCondition.Severity.ERROR
		)
		_error_count += 1

	return resource


## Returns whether the input [param suite] is set up to treat warnings as errors.
func _should_fail_on_warning(suite: ValidationSuite) -> bool:
	if (
		suite.warning_behaviour_override
		== ValidationSuite.WarningBehaviourOverride.FAIL_ON_WARNINGS
	):
		return true

	if suite.warning_behaviour_override == ValidationSuite.WarningBehaviourOverride.IGNORE_WARNINGS:
		return false

	return (
		_cli_validation_settings.warning_behaviour
		== CLIValidationSettings.WarningBehaviour.FAIL_ON_WARNINGS
	)


## Returns whether a validation has passed based on input [param results].
func _has_passed(results: Array[ValidatorCLIOutput.Result]) -> bool:
	var suite: ValidationSuite = _cli_validation_settings.suites[_current_suite_idx]
	var fail_on_warnings: bool = _should_fail_on_warning(suite)

	for result: ValidatorCLIOutput.Result in results:
		if (
			result.severity == ValidationCondition.Severity.ERROR
			or (result.severity == ValidationCondition.Severity.WARNING and fail_on_warnings)
		):
			return false

	return true


## Prints out validation result for an object that is marked to be ignored, and updates counters.
func _process_ignore(object_name: String, message: String) -> void:
	var suite: ValidationSuite = _cli_validation_settings.suites[_current_suite_idx]

	if _should_fail_on_warning(suite):
		print_rich("\t[color=red][Failed] : [/color]", object_name)
		_output.print_warning(message, true)
		_test_count += 1
		_fail_test_count += 1
		_error_count += 1
	else:
		print_rich("\t[color=orange][Ignored] : [/color]", object_name)
		_output.print_warning(message, false)
		_test_count += 1
		_ignore_test_count += 1
		_warning_count += 1


## Main logic for processing validation results.
## Takes the current results in [_output], prints relevant info to the console and updates all
## validation state counters.
func _process_results(object_name: String) -> void:
	var suite: ValidationSuite = _cli_validation_settings.suites[_current_suite_idx]
	_test_count += 1

	var results: Array[ValidatorCLIOutput.Result] = _output.get_results()
	var fail_on_warnings: bool = _should_fail_on_warning(suite)

	if _has_passed(results):
		print_rich("\t[color=green][Passed] : [/color]", object_name)
		_passing_test_count += 1
	else:
		print_rich("\t[color=red][Failed] : [/color]", object_name)
		_fail_test_count += 1

	for result: ValidatorCLIOutput.Result in results:
		_output.print_result(result, fail_on_warnings)

		if (
			result.severity == ValidationCondition.Severity.ERROR
			or (result.severity == ValidationCondition.Severity.WARNING and fail_on_warnings)
		):
			_error_count += 1
		elif result.severity == ValidationCondition.Severity.WARNING:
			_warning_count += 1

	_output.clear_results()


## Gathers high-level information about the validation run, prints a summary,
## and returns whether the whole process passed or failed.
func _end() -> ExitCode:
	print("\n")
	print_rich("[color=goldenrod]==============================================[/color]")
	print_rich("[color=goldenrod]= Run Summary[/color]")
	print_rich("[color=goldenrod]==============================================[/color]")
	print("\n")

	print("Totals")
	print("------")
	print("Suites\t\t", _suite_count)
	print("Tests\t\t", _test_count)

	if _error_count > 0:
		print("Errors\t\t", _error_count)
	if _warning_count > 0:
		print("Warnings\t", _warning_count)
	if _passing_test_count > 0:
		print("Passing Tests\t", _passing_test_count)
	if _ignore_test_count > 0:
		print("Ignored Tests\t", _ignore_test_count)
	if _fail_test_count > 0:
		print("Failing Tests\t", _fail_test_count)

	print("Time \t\t" + str(float(_total_time) * 0.000001) + "s")

	if _fail_test_count > 0:
		print_rich("\n\n[color=red]---- " + str(_fail_test_count) + " failing tests. ----[/color]")
	else:
		print_rich("\n\n[color=green]---- All tests passed! ----[/color]")

	return ExitCode.EXIT_FAIL if _fail_test_count > 0 else ExitCode.EXIT_OK
