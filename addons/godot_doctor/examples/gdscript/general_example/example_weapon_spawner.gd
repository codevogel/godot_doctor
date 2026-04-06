## A simple example weapon spawner demonstrating nested resource validation.
## Used by GodotDoctor to show how to delegate to a resource's own validation conditions.
class_name ExampleWeaponSpawner
extends Node

## The weapon resource to spawn. Its own validation conditions will also be checked.
@export var weapon_resource: ExampleWeapon


## Returns a [ValidationCondition] that delegates to [member weapon_resource]'s own conditions
## when the resource is assigned.
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
