## A simple example spawner demonstrating PackedScene type validation.
## Used by GodotDoctor to show how to validate that an exported [PackedScene]
## matches a required type.
class_name ExampleFooSpawner
extends Node

## The scene to spawn. Must have a root node of type [Foo].
@export var packed_scene_of_foo_type: PackedScene


## Returns a [ValidationCondition] that ensures [member packed_scene_of_foo_type] is of type [Foo].
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		ValidationCondition.is_scene_of_type(
			packed_scene_of_foo_type, Foo, "packed_scene_of_foo_type"
		)
	]
