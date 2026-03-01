## Resource used by the CLI interface. It holds lists of Scenes and Resource that are to be
## validated in a batched process. Used by [CLIValidationSettings].
@tool
class_name ValidationSuite
extends Resource

enum WarningBehaviourOverride { INHERIT, IGNORE_WARNINGS, FAIL_ON_WARNINGS }

@export var name: String
@export var warning_behaviour_override: WarningBehaviourOverride

## When true, all scenes and resources in the project are included automatically.
## The [member scenes] and [member resources] lists below will be filled by the CLI,
## taking into account the exclusion settings in [CLIValidationSettings].
@export var include_all_generatively: bool = false:
	set(value):
		include_all_generatively = value
		notify_property_list_changed()

## Paths to specific scenes to validate. Ignored when [member include_all_generatively] is true.
@export_file("*.tscn", "*.scn") var scenes: Array[String]

## Paths to specific resources to validate. Ignored when [member include_all_generatively] is true.
@export_file("*.tres", "*.res") var resources: Array[String]


func _validate_property(property: Dictionary) -> void:
	if property.name in ["scenes", "resources"] and include_all_generatively:
		property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR
