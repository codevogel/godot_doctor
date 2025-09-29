extends Node
class_name ClassNameQueryResult

var has_script: bool
var found_class_name: StringName
var has_class_name: bool


func _init(script_found: bool, class_name_found: StringName = &""):
	has_script = script_found
	found_class_name = class_name_found
	has_class_name = not found_class_name.is_empty()
