# Example: Verifying Array Match Counts By Predicate

This example demonstrates Godot Doctor's ability to validate that an array
contains the expected number of entries matching custom predicate conditions.

## The Issue

Sometimes, we need to enforce not just that items exist in an array, but that
**the right number of items** satisfy specific criteria.

In this example, we have an exported `factories` array where each factory has a
`type_to_spawn` value (`A` or `B`). We want to assert that:

1. Exactly 2 factories spawn type `A`
2. Exactly 1 factory spawns type `B`

Without explicit validation, this kind of distribution bug can go unnoticed
until runtime logic depends on those counts.

## The Solution

Use `ValidationCondition.array_matches_count_by_predicate()` inside
`_get_validation_conditions()`.

This helper takes:

1. The target array
2. The expected match count
3. A predicate callable that decides whether an item is a match
4. Optional description fields for clearer error messages

This allows you to express count-based validation rules declaratively and run
them at design time.

## This Example

The scene `verify_array_matches_count_by_predicate_example.tscn` contains an
`ExampleSpawnFromFactory` node with the script
`example_spawn_from_factory.gd` attached.

That script defines two validations:

```gdscript
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
)
```

In the provided scene data:

1. `num_products_for_type_a` is `2`
2. `num_products_for_type_b` is `1`
3. The actual factory setup yields `1` factory for type `A` and `2` for type `B`

So both validations fail, demonstrating how predicate-based count checks produce
clear, targeted errors.
