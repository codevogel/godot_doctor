class_name ExampleSpawnFromFactory
extends Node

@export var factories: Array[ExampleFactory] = []

@export var num_products_for_type_a: int = 2
@export var num_products_for_type_b: int = 1


func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		# This condition checks that the factories array contains the
		# expected amount of factories that spawn products of type A and B
		# respectively, demonstrating how to use
		# ValidationCondition.array_matches_count_by_predicate to validate
		# the contents of an array based on a custom predicate function.
		# In this case, the predicate function checks the type_to_spawn property
		# of each factory to determine whether that factory spawns a product of the expected type.
		ValidationCondition.array_matches_count_by_predicate(
			factories,
			num_products_for_type_a,
			func(factory: ExampleFactory) -> bool:
				return factory.type_to_spawn == ExampleProductBase.Type.A,
			"factories",
			"type_to_spawn is Type A"
		),
		ValidationCondition.array_matches_count_by_predicate(
			factories,
			num_products_for_type_b,
			func(factory: ExampleFactory) -> bool:
				return factory.type_to_spawn == ExampleProductBase.Type.B,
			"factories",
			"type_to_spawn is Type B"
		),
	]
