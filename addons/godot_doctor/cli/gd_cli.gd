## CLI based wrapper around the [SceneValidator]. Used to run validations offline in a batch.
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
const plugin_cfg_path : String = "res://addons/godot_doctor/plugin.cfg"

# ============================================================================
# PRIVATE PROPERTIES
# ============================================================================


## General settings of Godot Doctor.
var _doctor_settings : GodotDoctorSettings

## Settings for the batch validation, contains all scenes and resources that are to be validated.
var _batch_settings : BatchValidationSettings

var _output : ValidatorCLIOutputWrapper

## The validator object, this the main object, it does all the actual validation logic.
var _validator : SceneValidator

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

## The amount of warnings that should be treated as errors that the validation process has generated.
var _warning_as_error_count : int = 0

## The amount of errors that the validation process has generated.
var _error_count : int = 0

## The total amount of tests that have been processed.
var _test_count : int = 0

## The total amount of tests that have been passed.
var _passing_test_count : int = 0

## The total amount of tests that have been failed.
var _fail_test_count : int = 0

## The total amount of Validation Suites that have been processed.
var _suite_count : int = 0

## The total time the validation process has taken
var _total_time : int


# ============================================================================
# INITIALIZATION
# ============================================================================


## Basic initialization of the CLI validation process - mostly loads settings.
func _ready() -> void :
		
	# Initialse the settings.
	_doctor_settings = load(SceneValidator.VALIDATOR_SETTINGS_PATH)	
	_batch_settings = load(_doctor_settings.suite_settings)
	
	# If the batch settings couldn't be loaded, the whole process can't run. We need report
	# a total failure.
	if _batch_settings == null :
		push_error("Couldn't find Batch Validation Settings.")
		get_tree().quit(ExitCode.EXIT_FAIL)
	
	# Initialise the validator with CLI output interface.
	_output = ValidatorCLIOutputWrapper.new(_doctor_settings)
	_validator = SceneValidator.new(_output)
	
	
	# Load the plugin configuration file to get the current plugin version.
	var config = ConfigFile.new()
	var error : Error = config.load(plugin_cfg_path)
	
	# If the configuration file has loaded correctly, proceed.
	if error == Error.OK:
		var plugin_version : String = config.get_value("plugin", "version", "1.0")
		print_rich("Starting [color=blue][b]Godot Doctor[/b][/color] v" + plugin_version + ".")
		
	# If the configuration file couldn't be read, something went very wront, stop precessing and
	# report an error.
	else : 
		push_error("Couldn't read Godot Doctor plugin configration file: " + plugin_cfg_path + ".")
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
	
	# Validate that the suite contains tests to process.
	if suite.scenes.is_empty() and suite.resources.is_empty() :
		_output.push_message("Suite " + suite.name + "doesn't contain any tests.", ValidationCondition.Severity.WARNING)
	
	# If we have just switched suites, notify the console.
	if _new_suite :
		print_rich("\n[color=blue]Runing test suite: [/color]", suite.name)
		_new_suite = false
	
	
	# These will hold the objects we will be validating. Although a PackedScene is also a resource,
	# given that we need to instantiate it, it's given special treatment.
	var scene : PackedScene
	var resource : Resource
	
	# Attempt to load the object that is to be validated.
	if suite.scenes.size() > _current_scene_idx :
		scene = _load_resource(suite.scenes[_current_scene_idx])
		
		# If the scene failed to load, mark the test as failed.
		if scene == null :
			_fail_test_count += 1
		
	elif suite.resources.size() > _current_resource_idx :
		resource = _load_resource(suite.resources[_current_resource_idx])
		
		# If the resouce failed to load, mark the test as failed.
		if resource == null :
			_fail_test_count += 1
		
		# If the resouce has loaded correctly, we need to check if it's in the ignore list.
		else :
			
			var script: Script = resource.get_script()
			if script in _doctor_settings.default_validation_ignore_list :
				_output.push_message("Resource " + resource.resource_path + " with script " + script.resource_path + " is on the to-ignore list.", ValidationCondition.Severity.WARNING)
				_warning_count += 1
				resource = null
			
			
	# If we have a loaded Packed Scene, validate it now.
	if scene != null :
		
		# Notify the console on our progress.
		print("* " + scene.resource_path)
		
		# If the scene cannot be instantied, mark it as an error and move on.
		if not scene.can_instantiate() :
			_output.push_message("Couldn't instantiate scene " + scene.resource_path + ".", ValidationCondition.Severity.ERROR)
			_error_count += 1
			_fail_test_count += 1
			
		# If the node can be instantiated, proceed normally.
		else :
			
			# Grab the current time in microseconds - we need to report the test duration.
			var t : int = Time.get_ticks_usec()
			
			# Init the scene and add it to the tree, otherwise it can't be properly validated.
			var node : Node = scene.instantiate()
			add_child(node)
			
			# Have the validator gather all nodes available for validation.
			var nodes_to_validate: Array = _validator.find_nodes_to_validate_in_tree(node)
			_output.push_debug("Found " + str(nodes_to_validate.size()) + " nodes to validate in scene " + scene.resource_path + ".")

			# Validate each node.
			for n: Node in nodes_to_validate :
				_validator.validate_node(n)
				
				# TODO Print out the currently validated node, show pased/failed and errors.
			
			# Mark the test as passed.
			# TODO This needs to rely on information returned from the validator, so the validator
			#		will need be modified to return a validation result.
			_passing_test_count += 1
			
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
		
		# Notify the console on our progress.
		print("* " + resource.resource_path)
		
		# Run the resouce validation logic.
		_validator.validate_resource(resource)
		
		# Mark the test as passed.
		# TODO This needs to rely on information returned from the validator, so the validator
		#		will need be modified to return a validation result.
		_passing_test_count += 1
		
		# Calulcate the time that it took to run the validation.
		t = Time.get_ticks_usec() - t
		_total_time += t
			
			
	# If there are more scenes in the current suite, go to the next one now.
	if _current_scene_idx + 1 < suite.scenes.size() :
		_current_scene_idx += 1
		
		_test_count += 1
		
	# If there are more resources in the current suite, go to the next one now.
	elif _current_resource_idx + 1 < suite.resources.size() :
		_current_resource_idx += 1
		
		_test_count += 1
		
	# If there are more suites to process, go to the next one now.
	elif _current_suite_idx + 1 < _batch_settings.suites.size() :
		_current_suite_idx += 1
		
		# Rest the scene/resource indices.
		_current_scene_idx = 0
		_current_resource_idx = 0
		
		# We need to check the next suite, so grab it.
		var next_suite : ValidationSuite = _batch_settings.suites[_current_suite_idx]
		
		# Make sure the suite is set. No error here, it will be reported on next iteration.
		if next_suite != null :
			
			# Make sure we update the test variables only the suite contains data.
			# Again no error here, it will be reported next iteration.
			if not next_suite.scenes.is_empty() or not next_suite.resources.is_empty() :
				_test_count += 1
				_suite_count += 1
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
	
	# Make sure the path is not empty. Throw a special error for this case.
	if path.is_empty() :
		_output.push_message("Empty path found in suite " + _batch_settings.suites[_current_suite_idx].name + ".", ValidationCondition.Severity.ERROR)
		_error_count += 1
		return null
		
	# Check if the file exists in the first place.
	if not FileAccess.file_exists(path) :
		_output.push_message("File " + path + " not found in suite " + _batch_settings.suites[_current_suite_idx].name + ".", ValidationCondition.Severity.ERROR)
		_error_count += 1
		return null
	
	# Attempt to load the resource.
	var resource : Resource = load(path)
	
	# It's still possible that the resource have failed for whatever reason, if that's the case log that as an error.
	if resource == null :
		_output.push_message("Couldn't load file " + path + " in suite " + _batch_settings.suites[_current_suite_idx].name + ".", ValidationCondition.Severity.ERROR)
		_error_count += 1
		
	# Return the loaded in resource.
	return resource
	
	
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
	
	if (_error_count + _warning_as_error_count) > 0 :
		print("Errors\t\t", (_error_count + _warning_as_error_count))
	
	if _warning_count > 0 :
		print("Warnings\t", _warning_count)
	
	if _passing_test_count > 0 :
		print("Passing Tests\t", _passing_test_count)
		
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
