# Example: Verifying Node Exports

This example demonstrates Godot Doctor's capability to verify conditions for **exported properties** on a `Node` in a scene.

## The Issue

In Godot, it's common to use the `@export` keyword to expose properties in the editor.

You can get configuration warnings for those properties, such as missing references, but we'd have to make the script an `@tool` script to be able to run `_get_configuration_warnings()` in the editor.

This introduces quite a lot of boilerplate code, to ensure that the gameplay code is not executed in the editor. A good example of this can be found in the main `README` for `Godot Doctor`. In short, it requires us to bloat our gameplay code with calls like `if Editor.is_editor_hint() return`, and subscribe to `Notification`s to ensure that the checks are re-evaluated when properties change in the editor.

Furthermore, `_get_configuration_warnings()` only allows us to return a list of strings, which means we're encouraged to write code that returns strings, rather than code that evaluates our actual conditions.

## The Solution

**Godot Doctor** allows you to define custom validation checks for a `Node`'s (or `Resource`) exported properties directly within its script using the `_get_validation_conditions()` function.

1.  **Validate using simple boolean checks:** You can create checks with arbitrary logic (like ensuring a string is non-empty after trimming whitespace or matches a specific value, or that a number is strictly greater than zero).
2.  **Complex validation using Callables:** You can write `Callable`s for complex conditions for any exported reference, ensuring they are valid and meet specific criteria. These `Callables` can even contain nested `ValidationCheck`s if need be.

By running these checks in the editor, you catch configuration errors at design time, well before they cause a problem during gameplay.

## This Example

In this example, we have a scene, `verify_exports_example.tscn`, which contains a `Node` called `NodeWithExports` with the script `script_with_exports.gd` attached. This script defines three exported variables: `my_string`, `my_int`, and `my_node`.

Let's look at the validation conditions defined in `script_with_exports.gd`:

```gdscript
## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		# A helper method for the condition below is ValidationCondition.string_not_empty,
		# which does the exact same thing, but standardizes the error message.
		ValidationCondition.simple(
			not my_string.strip_edges().is_empty(), "my_string must not be empty"
		),
		ValidationCondition.simple(my_int > 0, "my_int must be greater than zero"),
		ValidationCondition.new(
			func() -> bool:
				return is_instance_valid(my_node) and my_node.name == "ExpectedNodeName",
			"my_node must be valid and named 'ExpectedNodeName'"
		)
	]
````

Verifying this scene results in **three errors** because none of the default exported values meet the conditions:

1.  **`my_string` is empty:** The default value `""` fails the `not my_string.strip_edges().is_empty()` check.
      * **Resolution:** Set a non-empty string value for **My String** in the Inspector.
2.  **`my_int` is not positive:** The default value `-42` fails the `my_int > 0` check.
      * **Resolution:** Set a value greater than `0` for **My Int** in the Inspector.
3.  **`my_node` is invalid/incorrectly named:** The default value is null, failing the check that it must be a valid instance.
      * **Resolution 1:** Drag the `WronglyNamedNode` from the scene tree into the **My Node** property slot in the Inspector. This will resolve the "invalid" part, but it will still fail the check because its name is not `'ExpectedNodeName'`.
		* **Resolution 2:** You'll then need to rename the node in the scene to `'ExpectedNodeName'` to fully resolve this specific error.
