## A script that demonstrates how to validate an exported resource variable.
## Used by GodotDoctor to show how to validate exported resources.
extends Node
class_name ScriptWithExportedResource

## A resource type with its own validation conditions.
@export var my_resource: MyResource


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		ValidationCondition.new(
			func() -> Variant:
				if not is_instance_valid(my_resource):
					return false
				return my_resource.get_validation_conditions(),
			"my_resource is not assigned"
		)
	]
