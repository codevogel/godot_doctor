# Example: Validating Node Paths

This example demonstrates **Godot Doctor’s** ability to verify the number of
**child nodes attached to a node** at design time.

## The Issue

Sometimes, we may need to check that a node has a specific number of children.
Or, maybe we want to ensure a node has a minimum or maximum number of children.
We could also want to verify that a node has no children at all.

In Godot, the only way to go about that is to use `@tool` and
`_get_configuration_warnings()`, which is cumbersome and not very user-friendly.

## The Solution

Godot Doctor lets us check these conditions using helper methods like
`ValidationCondition.has_child_count()`, and
`ValidationCondition.has_no_children()`.

## This Example

The scene `verify_node_count_example.tscn` contains a few `Node`s:

- NodeWithNoChildrenAllowed
- NodeWithChildCount
- NodeWithMinChildCount
- NodeWithMaxChildCount

Here’s the validation logic for one of the scripts, attached to
`NodeWithChildCount`:

```gdscript
## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
 return [ValidationCondition.has_child_count(self, 3, name)]
```

It checks that the node has exactly 3 children. Similar scripts are attached to
the other nodes, checking for no children, a minimum of 3 children, and a
maximum of 3 children.

When running the validation on this scene, the results are as follows:

- All checks fail, since none of the nodes meet their child count requirements.
- By removing or adding children to the nodes in the Scene Dock, you can see the
  validation results update after saving the scene.
