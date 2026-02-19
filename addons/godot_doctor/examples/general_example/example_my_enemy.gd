class_name ExampleMyEnemy
extends Node

@export var initial_health: int = 120
@export var max_health: int = 100


func _get_validation_conditions() -> Array[ValidationCondition]:
	var warnings: Array[ValidationCondition] = [
		ValidationCondition.simple(
			initial_health <= max_health, "Initial health should not be greater than max health."
		)
	]
	return warnings
