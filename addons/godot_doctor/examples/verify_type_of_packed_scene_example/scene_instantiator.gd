## A node that instantiates a PackedScene and verifies its type.
## Used by GodotDoctor to demonstrate type verification of PackedScenes.
class_name SceneInstantiator
extends Node

## This is a PackedScene that should have a root node of type `Foo`.
@export var scene_of_foo_type: PackedScene


## Returns a [ValidationCondition] that checks [member scene_of_foo_type] is of type [Foo].
func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.is_scene_of_type(scene_of_foo_type, Foo, "scene_of_foo_type")
	]
	return conditions
