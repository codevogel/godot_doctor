## A simple example script demonstrating how to suppress default validations for a script.
## Add this script to [member GodotDoctorSettings.default_validation_ignore_list]
## to prevent GodotDoctor from flagging its exported properties.
class_name ScriptIgnoredByDefaultValidations
extends Node

## An exported string that would normally trigger a default empty-string warning.
@export var some_exported_string: String = ""
## An exported node that would normally trigger a default null-instance warning.
@export var some_exported_node: Node = null
