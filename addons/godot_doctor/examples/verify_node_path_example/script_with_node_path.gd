## A script that demonstrates how to validate node paths using onready variables.
## Used by GodotDoctor to show how to validate node paths.
extends Node
class_name ScriptWithNodePath

## A node path that should point to a node named `MyNodePathNode`.
@onready var my_node_path_node: Node = $MyNodePathNode
## A deeper node path that should point to a node named `MyDeeperNodePathNode` inside `MyNodePathNode`.
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
