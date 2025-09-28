extends Control
class_name MySceneType

@onready var my_node_path_node: Node = $MyNodePathNode
@onready var my_deeper_node_path_node: Node = $MyNodePathNode/MyDeeperNodePathNode


func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.simple(
			is_instance_valid($MyNodePathNode), "MyNodePathNode was not found."
		),
		ValidationCondition.simple(
			is_instance_valid($MyNodePathNode/MyDeeperNodePathNode),
			"MyDeeperNodePathNode was not found."
		)
	]
	return conditions
