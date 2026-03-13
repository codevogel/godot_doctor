@tool
## A simple example weapon resource demonstrating validation on a [Resource].
## Used by GodotDoctor to show how to add custom validation conditions to resources.
class_name ExampleWeapon
extends Resource

## The amount of damage this weapon deals. Must be greater than zero.
@export var damage: int = -10
## The sprite texture displayed for this weapon.
@export var sprite: Texture2D
## The effective reach for melee attacks.
@export var reach_melee: float = 15.0
## The effective reach for ranged attacks. Must be greater than or equal to [member reach_melee].
@export var reach_ranged: float = 5.0


## Returns [ValidationCondition]s checking that [member damage] is positive
## and [member reach_melee] does not exceed [member reach_ranged].
func _get_validation_conditions() -> Array[ValidationCondition]:
	var warnings: Array[ValidationCondition] = [
		ValidationCondition.simple(damage > 0, "Damage should be a positive value."),
		ValidationCondition.simple(
			reach_melee <= reach_ranged, "Melee reach should not be greater than ranged reach."
		)
	]
	return warnings


## Public accessor that returns all validation conditions including a check for [member sprite].
## Intended to be called from other nodes that hold a reference to this weapon resource.
func get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = _get_validation_conditions()
	conditions.append(ValidationCondition.is_instance_valid(sprite, "sprite"))
	return conditions
