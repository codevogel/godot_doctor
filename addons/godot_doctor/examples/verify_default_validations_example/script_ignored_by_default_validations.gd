class_name ScriptIgnoredByDefaultValidations
extends Node

# Add this script to the `default_validation_ignore_list` in
# the `GodotDoctorSettings` asset to ignore the warnings for these
# variables.
@export var some_exported_string: String = ""
@export var some_exported_node: Node = null
