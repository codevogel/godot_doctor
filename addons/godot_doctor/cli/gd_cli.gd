extends Node

@onready var doctor_settings : GodotDoctorSettings = preload(SceneValidator.VALIDATOR_SETTINGS_PATH)
var batch_settings : BatchValidationSettings

var _output : ValidatorCLIOutputWrapper
var _validator : SceneValidator

var _new_suite : bool = true

var _current_suite_idx : int = 0
var _current_scene_idx : int = 0 
var _current_resource_idx : int = 0 

var _warning_count : int = 0
var _warning_as_error_count : int = 0
var _error_count : int = 0
var _test_count : int = 0
var _suite_count : int = 0

var _total_time : int

func _ready() -> void :
	batch_settings = load(doctor_settings.suite_settings)
	
	_output = ValidatorCLIOutputWrapper.new(doctor_settings)
	_validator = SceneValidator.new(_output)
	
	if batch_settings == null :
		push_error("Couldn't find Batch Validation Settings.")
		get_tree().quit(1)
		

func _load_resource(path : String) -> Resource :
	
	if path.is_empty() :
		_output.push_message("Empty path found in suite " + batch_settings.suites[_current_suite_idx].name + ".", ValidationCondition.Severity.ERROR)
		return null
		
	if not FileAccess.file_exists(path) :
		_output.push_message("File " + path + " not found in suite " + batch_settings.suites[_current_suite_idx].name + ".", ValidationCondition.Severity.ERROR)
		return null
	
	var resource : Resource = load(path)
	
	if resource == null :
		_output.push_message("Couldn't load file " + path + " in suite " + batch_settings.suites[_current_suite_idx].name + ".", ValidationCondition.Severity.ERROR)
		
	return resource

func _process(delta: float) -> void:
	
	var suite : ValidationSuite = batch_settings.suites[_current_suite_idx]
	
	if _new_suite :
		
		_output.push_message("Runing test suite " + suite.name)
		
		_new_suite = false
	
	var scene : PackedScene
	var resource : Resource
	
	if suite.scenes.size() > _current_scene_idx :
		scene = _load_resource(suite.scenes[_current_scene_idx])
		
	elif suite.resources.size() > _current_resource_idx :
		resource = _load_resource(suite.resources[_current_resource_idx])

	if scene != null :
		
		if not scene.can_instantiate() :			
			_output.push_message("Couldn't instantiate scene " + scene.resource_path + ".", ValidationCondition.Severity.ERROR)
		else :
			
			_output.push_message("Validating " + scene.resource_path)
			
			var t : int = Time.get_ticks_usec()
			
			var node : Node = scene.instantiate()
			add_child(node)
			
			var nodes_to_validate: Array = _validator.find_nodes_to_validate_in_tree(node)
			_output.print_message("Found " + str(nodes_to_validate.size()) + " nodes to validate in scene " + scene.resource_path + ".")

			# Validate each node
			for n: Node in nodes_to_validate:
				_validator.validate_node(n)
			
			remove_child(node)
			node.queue_free()
			
			t = Time.get_ticks_usec() - t
			_total_time += t
			
			print((float(t)* 0.000001))
			
			
	if resource != null :
		
		var t : int = Time.get_ticks_usec()
		
		_output.push_message("Validating " + resource.resource_path)
		_validator.validate_resource(resource)
		
		t = Time.get_ticks_usec() - t
		_total_time += t
		
		print((float(t)* 0.000001))
			
			
	if _current_scene_idx + 1 < suite.scenes.size() :
		_current_scene_idx += 1
	elif _current_resource_idx + 1 < suite.resources.size() :
		_current_resource_idx += 1
	elif _current_suite_idx + 1 < batch_settings.suites.size() :
		_current_suite_idx += 1
		_new_suite = true
	else :
		
		print("Tested in ", (float(_total_time)* 0.000001))
		
		get_tree().quit(1)
