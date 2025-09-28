# Validation examples

This directory contains examples of the validation plugin.

## How to use

1. Enable the plugin in Project > Project Settings > Plugins.
2. Open the example scene, at `./scenes/main/main.tscn`.
3. Save the scene to trigger validation.
4. Check the validation window for validation errors.

## What to expect

The example scene will report a couple of validation errors by design.
Try to click on the validation warnings to be taken to the offending node.

Try to fix the errors, and save again to see the validation window update.

## The examples

The `MyNode` node has a script attached that can be found at `./scenes/main/my_script.gd`.

	> The main purpose of this example is to demonstrate that validation works across different types of properties, and that validation can be nested.

It has two validation rules:
- It checks whether the `my_referenced_node` property is set.
	- You can assign a node to it in the inspector to clear this warning.
- It checks whether the `my_resource` property is set.
	- You can assign a resource to it in the inspector to clear this warning.
	- By clearing the not-assigned warning, you will see more warnings appear.
	- This is because the `my_resource` has it's own validation rules, that we check in the `Callable` from the second `ValidationCondition` in `my_script.gd`. 
		- It checks whether the `my_string` property is set to a non-empty string.
			- You can set it in the inspector to clear this warning.
		- It checks whether `my_int` is between `my_min_int` and `my_max_int`, whether `my_max_int` is greater than or equal to `my_min_int`, and whether `my_min_int` is less than or equal to `my_max_int`.
			- You can set `my_int`, `my_min_int` and `my_max_int` in the inspector to clear these warnings.

The `MyToolNode` has a script attached to it that can be found at `./scenes/main/my_tool.gd`.

	> The main purpose of this node is to demonstrate that validation also works in tool scripts.

It has one validation rule:
	- It checks whether the `my_int` property is lower than `my_max_int`.
		- You can set `my_int` and `my_max_int` in the inspector to clear this warning.
	- The main purpose of this node is to demonstrate that validation also works in tool scripts.

The `MySceneType` node is saved as its own scene, at `./scenes/main/my_scene_type.tscn`.
Its root node has a script attached to it that can be found at `./scenes/main/my_scene_type.gd`.

	> The main purpose of this example is to demonstrate that validation also works for the node path syntax, and that validation works across scenes, as long as the scene is instanced in the main scene.

It has two validation rules:
	- It checks whether the `my_node_path_node` property resolves to a valid node path. 
		- This is set to a valid node path by default, so you won't see a warning for it.
	- It checks whether the `my_deeper_node_path_node` property resolves to a valid node path.
		- Because the `my_deeper_node_path_node` is set to `$MyNodePathNode/MyDeeperNodePathNode`, and the Node is named `MyNodePathNode/WronglyNamedNode`, you will get a warning for it. The console should also log an error, as resolving the node path failed.
		- You can rename the node to `MyDeeperNodePathNode` to clear this warning.

## Conclusion

The `main` scene should be free of validation warnings if you followed the steps above.
Hopefully this gives you a good idea of:
	- why this plugin is useful
	- how to use the plugin
	- where you can find it's warnings
	- and how to fix the warnings
