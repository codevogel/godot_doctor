## A script that demonstrates how to validate an exported resource variable.
## Used by GodotDoctor to show how to validate exported resources.
class_name ScriptWithExportedResource
extends Node

## A resource type with its own validation conditions.
@export var my_resource: MyResource


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		# We rely on the default validaiton conditions here to see
		# if the resource is valid.
		# But, notice how we return an empty array in case the instance
		# is not null, or we might call get_validation_conditions on
		# a null instance.
		ValidationCondition.new(
			func() -> Variant:
				return (
					my_resource.get_validation_conditions()
					if is_instance_valid(my_resource)
					else []
				),
			"This string will never be used"
		),
		# If we would turn off the default validation checks, we might
		# manually want to report that the resource is null
		# Here's an example of that:
		#
		# ValidationCondition.new(
		# 	func() -> Variant:
		# 		if not is_instance_valid(my_resource):
		# 			return false
		# 		return my_resource.get_validation_conditions(),
		# 	"my_resource has not been assigned!"
		# ),
	]
