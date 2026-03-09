## Holds the results for a class name query.
## Used by GodotDoctor to determine if a script has a class name and what it is
class_name ClassNameQueryResult
extends RefCounted

var has_script: bool
var found_class_name: StringName
var has_class_name: bool


## Initializes the result.
## `script_found` is a boolean indicating if a script was found.
## `class_name_found` is the class name found in the script,
## or an empty StringName if none was found.
func _init(script_found: bool, class_name_found: StringName = &""):
	has_script = script_found
	found_class_name = class_name_found
	has_class_name = not found_class_name.is_empty()
