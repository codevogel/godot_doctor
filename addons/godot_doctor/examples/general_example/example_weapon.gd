@tool
class_name ExampleWeapon
extends Resource

@export var damage: int = -10
@export var sprite: Texture2D
@export var reach_melee: float = 15.0
@export var reach_ranged: float = 5.0


func _get_validation_conditions() -> Array[ValidationCondition]:
	print("foo")
	var warnings: Array[ValidationCondition] = [
		ValidationCondition.simple(damage > 0, "Damage should be a positive value."),
		ValidationCondition.simple(
			reach_melee <= reach_ranged, "Melee reach should not be greater than ranged reach."
		)
	]
	return warnings


func get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = _get_validation_conditions()
	conditions.append(ValidationCondition.is_instance_valid(sprite, "sprite"))
	return conditions
