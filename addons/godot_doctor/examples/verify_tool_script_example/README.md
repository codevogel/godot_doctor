# Example: Validating @tool Scripts with Godot Doctor

This example demonstrates how Godot Doctor provides a superior, less verbose way to validate configuration requirements on **@tool** scripts.
It also demonstrates that Godot Doctor can handle `@tool` scripts, as well as regular scripts.

## The Issue: Limitations of `_get_configuration_warnings()`

In native Godot development, the `_get_configuration_warnings()` function is the standard way to check a node's configuration in the editor. However, this approach has several drawbacks Godot Doctor seeks to resolve:

1.  **Manual Updates and Boilerplate:** The native warnings often don't update automatically when a scene is saved, especially for child nodes. Fixing this requires adding cumbersome boilerplate code, such as hooking into `NOTIFICATION_EDITOR_POST_SAVE` and manually calling `update_configuration_warnings()`.
2.  **String-Based Validation:** `_get_configuration_warnings()` forces you to return a `PackedStringArray`. This means your validation logic is written *inside* a function that returns the error message strings, cluttering your logic and making it harder to separate the condition check from the error metadata.
3.  **Code Contamination:** Adding `@tool` to a script to enable editor functionality means you must often pollute your gameplay-related functions (like `_process(delta)`) with editor-specific checks (`if Engine.is_editor_hint(): return`) to prevent them from running in the editor loop. This makes your core game code less clean.

## The Solution

Godot Doctor allows you to use the standard **`_get_validation_conditions()`** method on **@tool** scripts, offering a clean alternative:

1.  **Automatic, Comprehensive Validation:** Godot Doctor automatically runs validation on all nodes in a scene upon save, including child nodes, eliminating the need for manual update boilerplate.
2.  **Cleaner Logic (Separation of Concerns):** By using `ValidationCondition`, you define the validation check (a boolean expression) and the error message (a string) separately, resulting in cleaner, more maintainable, and easily **testable** code.
3.  **Unified Workflow:** You use the same consistent `ValidationCondition` syntax for validating both regular and `@tool` scripts, simplifying your development process.

## This Example

The `verify_tool_script_example.tscn` scene contains one child node, **`ToolNode`**, which has the `@tool` script `tool_script.gd` attached.

This script exports two properties, `my_int` and `my_max_int`, and defines a single `ValidationCondition`:

```gdscript
@tool
# ...
@export var my_int: int = 105 # Default value set high
@export var my_max_int: int = 100 # Default value set low

func _get_validation_conditions() -> Array[ValidationCondition]:
    var conditions: Array[ValidationCondition] = [
        ValidationCondition.simple(
            my_int <= my_max_int, 
            "my_int must be less than %s but is %s" % [my_max_int, my_int]
        ),
    ]
    return conditions
````

Verifying this scene results in an error:

  - The validation **fails** because the default value of `my_int` (`105`) is greater than `my_max_int` (`100`).
  - **Resolution:** To fix this error, change the value of **My Int** to `100` or less in the Inspector. This demonstrates a core configuration requirement being validated on an `@tool` script using the superior Godot Doctor syntax.
