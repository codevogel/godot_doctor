## A script that demonstrates how to validate node paths using onready variables.
## Used by GodotDoctor to show how to validate node paths.
class_name ScriptWithNodePath
extends Node

## A node path that should point to a node named `MyNodePathNode`.
@onready var my_node_path_node: Node = $MyNodePathNode

## A deeper node path that should point to a node
## named `MyDeeperNodePathNode` inside `MyNodePathNode`.
@onready var my_deeper_node_path_node: Node = $MyNodePathNode/MyDeeperNodePathNode


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.simple(has_node("MyNodePathNode"), "MyNodePathNode was not found."),
		# The below helper method does the same thing as above, but
		# standardizes the error message.
		ValidationCondition.has_node_path(
			self, "MyNodePathNode/MyDeeperNodePathNode", "my_deeper_node_path_node"
		)
	]
	return conditions
