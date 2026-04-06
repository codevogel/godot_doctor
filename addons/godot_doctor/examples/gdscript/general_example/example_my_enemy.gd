## A simple example enemy node demonstrating cross-property validation.
## Used by GodotDoctor to show how to validate relationships between exported properties.
class_name ExampleMyEnemy
extends Node

## The health value the enemy starts with.
@export var initial_health: int = 120
## The maximum health value the enemy can have.
@export var max_health: int = 100


## Returns a [ValidationCondition] that ensures [member initial_health]
## does not exceed [member max_health].
func _get_validation_conditions() -> Array[ValidationCondition]:
	var warnings: Array[ValidationCondition] = [
		ValidationCondition.simple(
			initial_health <= max_health, "Initial health should not be greater than max health."
		)
	]
	return warnings
