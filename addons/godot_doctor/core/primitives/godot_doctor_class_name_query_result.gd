## Holds the results for a class name query.
## Used by [ValidationCondition] to determine if a script has a class name and what it is.
class_name GodotDoctorClassNameQueryResult
extends RefCounted

## Whether a script was found on the queried node.
var has_script: bool
## The class name found in the script, or an empty [StringName] if none was found.
var found_class_name: StringName
## Whether a non-empty class name was found in the script.
var has_class_name: bool


## Initializes the result.
## [param script_found] indicates whether a script was found on the target node.
## [param class_name_found] is the class name found in the script,
## or an empty [StringName] if none was found.
func _init(script_found: bool, class_name_found: StringName = &""):
	has_script = script_found
	found_class_name = class_name_found
	has_class_name = not found_class_name.is_empty()
