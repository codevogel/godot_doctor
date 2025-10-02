extends Node
class_name ScriptWithNodePath

@onready var my_node_path_node: Node = $MyNodePathNode
@onready var my_deeper_node_path_node: Node = $MyNodePathNode/MyDeeperNodePathNode


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	if not is_instance_valid($MyNodePathNode/MyDeeperNodePathNode):
		push_warning(
			"The 'Node not found' error below is intentional and caused for demonstration purposes. See addons/validator/example/README.md for more information. You can fix this error by renaming the WronglyNamedNode to MyDeeperNodePathNode."
		)
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
