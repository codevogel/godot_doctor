extends Node
class_name MySceneInstantiator

@export var scene_of_foo_type: PackedScene


func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.scene_is_of_type(scene_of_foo_type, Foo, "scene_of_foo_type")
	]
	return conditions
