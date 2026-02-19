class_name ExamplePlayer
extends Node

@export var player_name: String = "Godot Doctor Enjoyer"


func _get_validation_conditions() -> Array[ValidationCondition]:
	var warnings: Array[ValidationCondition] = [
		ValidationCondition.simple(
			player_name.length() <= 12,
			"Player name longer than 12 characters may cause UI issues.",
			ValidationCondition.Severity.INFO
		)
	]
	return warnings
