class_name ValidationSuite extends Resource

enum WarningBehaviour { INHERIT, IGNORE_WARNINGS, FAIL_ON_WARNINGS }

@export var name : String
@export var warningBehaviour : WarningBehaviour

@export_file("*.tscn", "*.scn") var scenes : Array[String]
@export_file("*.tres", "*.res") var resources : Array[String]
