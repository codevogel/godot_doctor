## CLI based wrapper around the [Validator]. Used to run validations offline in a batch.
## Uses [BatchValidationSettings] as source of information. Will print all results to the terminal.
extends Node


# ============================================================================
# HELPER TYPES
# ============================================================================


## Enum defining quit value of the application, needed in CI systems to notify if the validation
## process has succeeded or failed.
enum ExitCode { EXIT_OK , EXIT_FAIL }


# ============================================================================
# CONSTANTS
# ============================================================================


## Path to the plugin configuration file. The process will fail if the plugin is installed
## in a different than default directory. However, the common process is not to move plugins.
const PLUGIN_CFG_PATH : String = "res://addons/godot_doctor/plugin.cfg"


# ============================================================================
# PRIVATE PROPERTIES
# ============================================================================


## General settings of Godot Doctor.
var _doctor_settings : GodotDoctorSettings

## Settings for the batch validation, contains all scenes and resources that are to be validated.
var _batch_settings : BatchValidationSettings

var _output : ValidatorCLIOutput

## The validator object, this the main object, it does all the actual validation logic.
var _validator : Validator

## Flag marking if the current iteration is processing a new suite,
## one that has not been processed yet.
var _new_suite : bool = true

## Stores the index of the Validation Suite that is curentply processed.
var _current_suite_idx : int = 0

## Stores the index of the Scene in the current Validation Suite that is curentply processed.
var _current_scene_idx : int = 0 

## Stores the index of the Resource in the current Validation Suite that is curentply processed.
var _current_resource_idx : int = 0 

## The amount of warnings that the validation process has generated.
var _warning_count : int = 0

## The amount of errors that the validation process has generated.
var _error_count : int = 0

## The total amount of tests that have been processed.
var _test_count : int = 0

## The total amount of tests that have been passed.
var _passing_test_count : int = 0

## The total amount of tests that have been failed.
var _ignore_test_count : int = 0

## The total amount of tests that have been failed.
var _fail_test_count : int = 0

## The total amount of Validation Suites that have been processed.
var _suite_count : int = 0

## The total time the validation process has taken
var _total_time : int

## The node path to this node. Used for printing nicely path within the scene structure
## of the validated node.
var _base_path : String

# ============================================================================
# INITIALIZATION
# ============================================================================


## Basic initialization of the CLI validation process - mostly loads settings.
func _ready() -> void :
		
	# Initialse the settings.
	_doctor_settings = load(Validator.VALIDATOR_SETTINGS_PATH)
	_batch_settings = load(_doctor_settings.batch_validation)
	
	# If the batch settings couldn't be loaded, the whole process can't run. We need report
	# a total failure.
	if _batch_settings == null :
		push_error("Couldn't find Batch Validation Settings.")
		get_tree().quit(ExitCode.EXIT_FAIL)
		return
	
	
	# Store our node path, for parsing during validation.
	_base_path = get_path()
	
	
	# Initialise the validator with CLI output interface.
	_output = ValidatorCLIOutput.new(_doctor_settings)
	_validator = Validator.new(_output)
	
	
	# Load the plugin configuration file to get the current plugin version.
	var config = ConfigFile.new()
	var error : Error = config.load(PLUGIN_CFG_PATH)
	
	# If the configuration file has loaded correctly, proceed.
	if error == Error.OK:
		var plugin_version : String = config.get_value("plugin", "version", "1.0")
		print_rich("Starting [color=blue][b]Godot Doctor[/b][/color] v" + plugin_version + ".")
		
	# If the configuration file couldn't be read, something went very wront, stop precessing and
	# report an error.
	else : 
		push_error("Couldn't read Godot Doctor plugin configration file: " + PLUGIN_CFG_PATH + ".")
		get_tree().quit(ExitCode.EXIT_FAIL)
	
	
# ============================================================================
# CORE LOGIC - Reading in suite data and runing the validator.
# ============================================================================


## Main loop running the validation process. Will take one test (scene or resource) per frame,
## validate it, untill all tests have been run.
func _process(delta: float) -> void:
	
	# Grab the suite for the current run.
	var suite : ValidationSuite = _batch_settings.suites[_current_suite_idx]
	
	# Make sure the suite is valid.
	if suite == null :
		push_error("Found null in the Validation Suite list.")
		get_tree().quit(ExitCode.EXIT_FAIL)
		return
	
	# If we have just switched suites, notify the console and update count.
	if _new_suite :
		print_rich("\n[color=blue]Runing test suite: [/color]", suite.name)
		_suite_count += 1
		_new_suite = false
	
	# Validate that the suite contains tests to process.
	if suite.scenes.is_empty() and suite.resources.is_empty() :
		_output.print_global_message("Suite " + suite.name + "doesn't contain any tests.", ValidationCondition.Severity.WARNING)
	
	
	# These will hold the objects we will be validating. Although a PackedScene is also a resource,
	# given that we need to instantiate it, it's given special treatment.
	var scene : PackedScene
	var resource : Resource
	
	# Attempt to load the object that is to be validated.
	if suite.scenes.size() > _current_scene_idx :
		scene = _load_resource(suite.scenes[_current_scene_idx])
		
	elif suite.resources.size() > _current_resource_idx :
		resource = _load_resource(suite.resources[_current_resource_idx])
		
		
	# If we have a loaded Packed Scene, validate it now.
	if scene != null :
		
		# Grab the current time in microseconds - we need to report the test duration.
		var t : int = Time.get_ticks_usec()
		
		# Notify the console on which file is being validated.
		print("* " + scene.resource_path)
		
		# If the scene cannot be instantied, mark it as an error and move on.
		if not scene.can_instantiate() :
			
			# Get a human readable name of the packed scene resource.
			var name : String = scene.resource_name
			if name.is_empty() :
				name = scene.resource_path.get_file()
			
			# Log not being able to instantiate the scene as an error.
			print_rich("\t[color=red][Failed] : [/color]", name)
			_output.print_error("Couldn't instantiate scene.")
			
			# Increment the relevant counters.
			_test_count += 1
			_fail_test_count += 1
			_error_count += 1
			
		# If the node can be instantiated, proceed normally.
		else :

			# Init the scene and add it to the tree, otherwise it can't be properly validated.
			var node : Node = scene.instantiate()
			add_child(node)
			
			# Have the validator gather all nodes available for validation.
			var nodes_to_validate: Array = _validator.find_nodes_to_validate_in_tree(node)
			_output.push_debug("Found " + str(nodes_to_validate.size()) + " nodes to validate in scene " + scene.resource_path + ".")

			# If the scene doesn't have any nodes to validate, process it as and object to ignore.
			if nodes_to_validate.is_empty() :
				_process_ignore(node.name, "Scene has nothing to validate.")

			# If there nodes to validate, process them now.
			else :

				# Validate each node.
				for n: Node in nodes_to_validate :
					
					# Grab the path to the node, from the root of the validated scene.
					var name : String = n.get_path()
					name = name.substr(_base_path.length() + 1)
					
					# Run the node validation.
					_validator.validate_node(n)
					
					# Process the validation results.
					_process_results(name)
			
				# Clean up the node tree.
				remove_child(node)
				node.queue_free()
			
		# Calulcate the time that it took to run the validation.
		t = Time.get_ticks_usec() - t
		_total_time += t
			
	# If we have a loaded Resource, validate it now.
	elif resource != null :
		
		# Grab the current time in microseconds - we need to report the test duration.
		var t : int = Time.get_ticks_usec()
		
		# Notify the console on which file is being validated.
		print("* " + resource.resource_path)
		
		# Get a human readable name of the resource.
		var name : String = resource.resource_name
		if name.is_empty() :
			name = resource.resource_path.get_file()
		
		# Grab the script of the resource. 
		var script: Script = resource.get_script()
		
		# Check if the resource is in the ignore list, if so mark it as ignored.
		if script in _doctor_settings.default_validation_ignore_list :
			_process_ignore(name, "Resource with script " + script.resource_path + " is on the to-ignore list.")
		
		# If the resource can be validated, do it now.
		else :
			
			# Run the resouce validation logic.
			_validator.validate_resource(resource)
			
			# Process the validation results.
			_process_results(name)

		# Calulcate the time that it took to run the validation.
		t = Time.get_ticks_usec() - t
		_total_time += t
			
			
	# If there are more scenes in the current suite, go to the next one now.
	if _current_scene_idx + 1 < suite.scenes.size() :
		_current_scene_idx += 1
	
	# If there are more resources in the current suite, go to the next one now.
	elif _current_resource_idx + 1 < suite.resources.size() :
		_current_resource_idx += 1
		
	# If there are more suites to process, go to the next one now.
	elif _current_suite_idx + 1 < _batch_settings.suites.size() :
		_current_suite_idx += 1
		
		# Rest the scene/resource indices.
		_current_scene_idx = 0
		_current_resource_idx = 0
		
		# Mark that we are processing a new suite.
		_new_suite = true
		
	# If all tests have concluded, run the report and exit.
	else :
		
		var exit_code : ExitCode = _end()
		_output.push_debug("Exiting with " + ExitCode.find_key(exit_code) + ".")
		
		get_tree().quit(exit_code)
		
		
# ============================================================================
# HELPER METHODS
# ============================================================================


## Function that attempts to load a resource from the input path, but does it safely -
## checks if the file exits and can be loaded, and if necessary reports found errors.
func _load_resource(path : String) -> Resource :
	
	var suite : ValidationSuite = _batch_settings.suites[_current_suite_idx]
	
	# Make sure the path is not empty. Throw a special warning for this case.
	if path.is_empty() :
		_output.print_global_message("Empty path found in suite " + suite.name + ".", ValidationCondition.Severity.WARNING, _should_fail_on_warning(suite))
		_warning_count += 1
		return null
		
	# Check if the file exists in the first place.
	if not FileAccess.file_exists(path) :
		_output.print_global_message("File " + path + " not found in suite " + suite.name + ".", ValidationCondition.Severity.ERROR)
		_error_count += 1
		return null
	
	# Attempt to load the resource.
	var resource : Resource = load(path)
	
	# It's still possible that the resource have failed for whatever reason, if that's the case log that as an error.
	if resource == null :
		_output.print_global_message("Couldn't load file " + path + " in suite " + suite.name + ".", ValidationCondition.Severity.ERROR)
		_error_count += 1
		
	# Return the loaded in resource.
	return resource
	
	
## Returns whether the input [param suite] is set up to treat warnings as errors.
func _should_fail_on_warning(suite : ValidationSuite) -> bool :
	
	if suite.warningBehaviourOverride == ValidationSuite.WarningBehaviourOverride.FAIL_ON_WARNINGS :
		return true
	
	elif suite.warningBehaviourOverride == ValidationSuite.WarningBehaviourOverride.IGNORE_WARNINGS :
		return false
		
	else :
		return _batch_settings.warningBehaviour == BatchValidationSettings.WarningBehaviour.FAIL_ON_WARNINGS
	
	
## Returns whether a validation has passed based on input [param results].
func _has_passed(results : Array[ValidatorCLIOutput.Result]) -> bool :
	
	# Grab the current validation suite.
	var suite : ValidationSuite = _batch_settings.suites[_current_suite_idx]
	
	# Check whether the validation should fail if encountering a warning.
	var fail_on_warnings : bool = _should_fail_on_warning(suite)
	
	# Go through all input results.
	for result : ValidatorCLIOutput.Result in results :
		
		# If any result returns an error or warning with us needing to fail at warnings, return
		# that the validation has not passed.
		if result.severity == ValidationCondition.Severity.ERROR or (result.severity == ValidationCondition.Severity.WARNING and fail_on_warnings) :
			return false
			
	# If we reached here, the validation has passed.
	return true
	
	
## Prints out validaton result, for an object that is marked to be ignored, as well as making sure
## all counters are reflecting the validation state.
func _process_ignore(object_name : String, message : String) -> void :
	
	# Grab the current validation suite.
	var suite : ValidationSuite = _batch_settings.suites[_current_suite_idx]

	# Ignoring an object usually, results in a warning, we check here if warnings should be 
	# treated as errors for the current suite and if so process this as an error.s
	if _should_fail_on_warning(suite) :
		
		# Notify the console of the error.
		print_rich("\t[color=red][Failed] : [/color]", object_name)
		_output.print_warning(message, true)
		
		# Increment the relevant counters.
		_test_count += 1
		_fail_test_count += 1
		_error_count += 1
		
	# If we don't fail on warnings, process this as a regular warning.
	else :
		
		# Notify the console of the warning.
		print_rich("\t[color=orange][Ignored] : [/color]", object_name)
		_output.print_warning(message, false)
		
		# Increment the relevant counters.
		_test_count += 1
		_ignore_test_count += 1
		_warning_count += 1
	
	
## Main logic for processing validation results.
## Takes the current results  in [_output], prints relevant infor to the console and updates all
## validation state counters.
func _process_results(object_name : String) -> void :
	
	# Grab the current validation suite.
	var suite : ValidationSuite = _batch_settings.suites[_current_suite_idx]
	
	# We have test results, so we need to mark that another test has happened.
	_test_count += 1
	
	# Grab the results fromt the output.
	var results : Array[ValidatorCLIOutput.Result] = _output.get_results()
	
	# Check if we need to treat warnings as errors.
	var fail_on_warnings : bool = _should_fail_on_warning(suite)
	
	# If the validation has passed, print the information appropriately to the console,
	# and update passed test counter.
	if _has_passed(results) :
		print_rich("\t[color=green][Passed] : [/color]", object_name)
		_passing_test_count += 1
	
	# If the validation has failed, print the information appropriately to the console,
	# and update failed test counter.
	else :
		print_rich("\t[color=red][Failed] : [/color]", object_name)
		_fail_test_count += 1
		
	# Print out 
	for result : ValidatorCLIOutput.Result in results : 
		_output.print_result(result, fail_on_warnings)
		
		# Update the error/warning counters appropriately.
		if result.severity == ValidationCondition.Severity.ERROR or (result.severity == ValidationCondition.Severity.WARNING and fail_on_warnings) :
			_error_count += 1
		elif result.severity == ValidationCondition.Severity.WARNING :
			_warning_count += 1
	
	# The results have been processed, we can clear them now.
	_output.clear_results()
	

## Function that gathers all the high-level information about the ran validations process,
## reports it as a summary and returns if the whole process has passed or failed.
func _end() -> ExitCode :
	
	# Print the header
	
	print("\n")
	
	print_rich("[color=goldenrod]==============================================[/color]")
	print_rich("[color=goldenrod]= Run Summary[/color]")
	print_rich("[color=goldenrod]==============================================[/color]")
	
	print("\n")
	
	
	# Print the data.
	
	print("Totals")
	print("------")
	
	print("Suites\t\t", _suite_count)
	print("Tests\t\t", _test_count)
	
	if _error_count > 0 :
		print("Errors\t\t", _error_count)
	
	if _warning_count > 0 :
		print("Warnings\t", _warning_count)
	
	if _passing_test_count > 0 :
		print("Passing Tests\t", _passing_test_count)
		
	if _ignore_test_count > 0 :
		print("Ignored Tests\t", _ignore_test_count)
		
	if _fail_test_count > 0 :
		print("Failing Tests\t", _fail_test_count)
	
	print("Time \t\t" + str((float(_total_time)* 0.000001)) + "s")


	# Print the total result.

	if _fail_test_count > 0 :
		print_rich("\n\n[color=red]---- " + str(_fail_test_count) + " failing tests. ----[/color]")
	else :
		print_rich("\n\n[color=green]---- All tests passed! ----[/color]")


	# Return the general result of the validation.
	return ExitCode.EXIT_FAIL if _fail_test_count > 0 else ExitCode.EXIT_OK
