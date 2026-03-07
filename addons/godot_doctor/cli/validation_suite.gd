class_name ValidationSuite
extends Resource

## Whether to treat warnings as errors when validating the scenes and resources in this suite.
@export var treat_warnings_as_errors: bool = false
## The paths to the scenes to validate in this suite.
@export_file("*.tscn", "*.scn") var scenes: Array[String] = []
## The paths to the resources to validate in this suite.
@export_file("*.tres", "*.res") var resources: Array[String] = []
