extends Node

@export var my_referenced_node: Node
@export var my_resource: MyResource


func _get_validation_conditions() -> Array[ValidationCondition]:
	var resource_exists: bool = is_instance_valid(my_resource)
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.simple(
			is_instance_valid(my_referenced_node), "my_referenced_node must be assigned."
		),
		ValidationCondition.new(
			func() -> Variant:
				if not is_instance_valid(my_resource):
					return false
				return my_resource.get_validation_conditions(),
			"my_resource must be assigned."
		)
	]
	return conditions
