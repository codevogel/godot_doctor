extends Node

@export var my_referenced_node: Node
@export var my_resource: MyResource


func _get_validation_conditions() -> Array[ValidationCondition]:
	var resource_exists: bool = is_instance_valid(my_resource)
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.simple(
			is_instance_valid(my_referenced_node), "my_referenced_node must be assigned."
		),
		ValidationCondition.simple(resource_exists, "my_resource must be assigned.")
	]
	if resource_exists:
		conditions.append_array(my_resource.get_validation_conditions())
	return conditions
