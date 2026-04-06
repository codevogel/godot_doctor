## A simple example player node demonstrating custom validation conditions.
## Used by GodotDoctor to show how to validate exported properties with custom rules.
class_name ExamplePlayer
extends Node

## The display name of the player. Names longer than 12 characters may cause UI issues.
@export var player_name: String = "Godot Doctor Enjoyer"


## Returns [ValidationCondition]s that flag [member player_name] values longer than 12 characters.
func _get_validation_conditions() -> Array[ValidationCondition]:
	var warnings: Array[ValidationCondition] = [
		ValidationCondition.simple(
			player_name.length() <= 12,
			"Player name longer than 12 characters may cause UI issues.",
			ValidationCondition.Severity.INFO
		)
	]
	return warnings
