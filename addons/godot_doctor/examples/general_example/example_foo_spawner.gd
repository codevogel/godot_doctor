class_name ExampleFooSpawner
extends Node

@export var packed_scene_of_foo_type: PackedScene


func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		ValidationCondition.scene_is_of_type(
			packed_scene_of_foo_type, Foo, "packed_scene_of_foo_type"
		)
	]
