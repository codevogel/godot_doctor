class_name ExampleWeaponSpawner
extends Node

@export var weapon_resource: ExampleWeapon


func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.new(
			func() -> Variant:
				if weapon_resource == null:
					# This will be handled by the default validations
					return true
				return weapon_resource.get_validation_conditions(),
			"This string won't be used"
		)
	]
	return conditions
