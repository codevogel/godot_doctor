# Example: Validating Node Paths at Design Time

This example demonstrates Godot Doctor's ability to verify the existence of **Nodes referenced by path** (using the `$` syntax) within a scene.

## The Issue

In Godot, using the `$` operator (or `@onready var node: Node = get_node("Path")`) is a frequently used way to reference child nodes. This is fast and convenient, but highly vulnerable to scene refactoring:

1.  **Renaming or Deleting a Node:** If you rename a node, or delete it entirely, any script referencing it via the old name or path will fail silently on load (the variable will be `null`), potentially leading to a crash much later when you try to use that node.
2.  **Complex Paths:** When using deep or relative paths (e.g., `$"../AnotherNode/Target"`), it can be difficult to visually confirm that the path is correct and the target node actually exists.

We do get reported errors at runtime, but it'd be nice to get these at design time, before we even run the scene.

## The Solution

Godot Doctor allows us to define checks using `ValidationCondition.simple()` that evaluate the validity of a node path at design time.

By placing the path checks within the `_get_validation_conditions()` method, we can instantly verify that the nodes our script depends on are present in the scene tree:

```gdscript
ValidationCondition.simple(
    is_instance_valid($Path/To/Node), 
    "Error message if the node is missing."
)
````

This way, you catch structural errors immediately after changing the scene layout.

(A general recommendation of mine would be to avoid the `$` operator for anything but the most trivial cases. `@export` does the same thing, and is less susceptible to name changes.

## This Example

The `verify_node_path_example.tscn` scene contains a `Node` called `NodeWithNodePath` with the script `script_with_node_path.gd` attached. This script attempts to find two child nodes using the `$` operator:

1.  `$MyNodePathNode` (a direct child).
2.  `$MyNodePathNode/MyDeeperNodePathNode` (a nested child).

Let's look at the validation logic in the script:

```gdscript
func _get_validation_conditions() -> Array[ValidationCondition]:
    # ... intentional warning logic removed for clarity ...
    var conditions: Array[ValidationCondition] = [
        ValidationCondition.simple(
            is_instance_valid($MyNodePathNode), "MyNodePathNode was not found."
        ),
        ValidationCondition.simple(
            is_instance_valid($MyNodePathNode/MyDeeperNodePathNode),
            "MyDeeperNodePathNode was not found."
        )
    ]
    return conditions
```

Verifying this scene results in one error:

  - The check for **`$MyNodePathNode`** **passes** because the node is correctly named and located in the scene tree.
  - The check for **`$MyNodePathNode/MyDeeperNodePathNode`** **fails**.
      - Looking at the scene tree, the node at that location is actually named `MyWronglyNamedNode`. The script is looking for a node named `MyDeeperNodePathNode` but cannot find it, causing the check to fail.
      - **Resolution:** Rename the `MyWronglyNamedNode` to **`MyDeeperNodePathNode`** in the Scene Dock.
      - *Note:* The script intentionally includes a `push_warning` to explain the error setup in the editor itself, as Godot will report an error when it can't find the node during the validation process, which will happen when a reference is broken. (You could say this is already enough, but to make the experience consistent with the other validations, we include it as a ValidationWarning as well.)
