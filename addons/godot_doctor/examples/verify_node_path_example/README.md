# Example: Validating Node Paths

This example demonstrates **Godot Doctor’s** ability to verify the existence of
**nodes referenced through `@onready` variables** (using the `$` syntax) at
design time.

## The Issue

In Godot, it’s common to use `@onready var node = $ChildNode` or
`@onready var node = get_node("Path/To/Node")` to reference nodes in your scene.
This approach is fast and convenient, but it introduces a risk during scene
refactoring:

1. **Renaming or Deleting a Node:** If a node’s name changes or it’s deleted,
   any script referencing it via the old path will load with a `null` reference.
   You might not notice until much later, when trying to access that node at
   runtime—leading to confusing crashes or errors.
2. **Nested or Complex Paths:** When you use deep paths like
   `$"MyParent/MyChild/MyTarget"`, it’s easy to lose track of whether the path
   is still valid after rearranging the scene.

Godot will report runtime errors when a node reference is missing, but ideally
we’d catch these problems **before** running the scene.

## The Solution

Godot Doctor lets us define **design-time validation rules** using
`ValidationCondition.simple()` or helper methods like
`ValidationCondition.has_node_path()`.

These conditions, declared in `_get_validation_conditions()`, automatically
check whether node paths referenced by your script actually exist in the scene:

```gdscript
ValidationCondition.has_node_path(
    self,
    "Path/To/Node",
    "variable_name"
)
```

If the node can’t be found, Godot Doctor will report a validation error directly
in the editor—helping you catch missing or renamed nodes immediately.

_(As a general best practice, prefer using `@export` or explicit NodePath
variables for anything that might move or be renamed frequently. They’re more
robust than hardcoded `$` paths.)_

## This Example

The scene `verify_node_path_example.tscn` contains a `Node` named
`NodeWithNodePath`, with the script `script_with_node_path.gd` attached. This
script references two child nodes:

1. `$MyNodePathNode` — a direct child node.
2. `$MyNodePathNode/MyDeeperNodePathNode` — a nested child node.

Here’s the validation logic from the script:

```gdscript
func _get_validation_conditions() -> Array[ValidationCondition]:
 var conditions: Array[ValidationCondition] = [
  ValidationCondition.simple(
   has_node("MyNodePathNode"), "MyNodePathNode was not found."
  ),
  # The below helper method does the same thing as above, but
  # standardizes the error message.
  ValidationCondition.has_node_path(
   self, "MyNodePathNode/MyDeeperNodePathNode", "my_deeper_node_path_node"
  )
 ]
 return conditions
```

When running the validation on this scene, the results are as follows:

- The check for **`MyNodePathNode`** **passes**, since the node exists in the
  scene tree.
- The check for **`MyNodePathNode/MyDeeperNodePathNode`** **fails**.
  - Looking at the scene, the nested node is actually named
    `MyWronglyNamedNode`. The script expects `MyDeeperNodePathNode`, so the
    validation correctly reports it as missing.
  - **Resolution:** Rename `MyWronglyNamedNode` to **`MyDeeperNodePathNode`** in
    the Scene Dock.
  - _Note:_ Godot will already produce a warning when
    `$MyNodePathNode/MyDeeperNodePathNode` fails to resolve, but defining this
    as a `ValidationCondition` ensures the problem appears in Godot Doctor’s
    structured validation output—making it consistent with other checks in your
    project.
