class_name ExampleFactory
extends Node

@export var type_to_spawn: ExampleProductBase.Type


func spawn_product(type: ExampleProductBase.Type) -> ExampleProductBase:
	var spawned_product: ExampleProductBase = null
	match type:
		ExampleProductBase.Type.A:
			spawned_product = ExampleProductA.new()
		ExampleProductBase.Type.B:
			spawned_product = ExampleProductB.new()
		_:
			push_error("Unknown product type: %s" % type)
	return spawned_product
