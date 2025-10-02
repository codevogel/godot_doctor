extends Node
class_name SceneInstantiator

@export var scene_of_foo_type: PackedScene


## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	var conditions: Array[ValidationCondition] = [
		ValidationCondition.scene_is_of_type(scene_of_foo_type, Foo, "scene_of_foo_type")
	]
	return conditions
