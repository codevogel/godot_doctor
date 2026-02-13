# Example: Verifying the Root Type of a PackedScene

This example demonstrates how Godot Doctor can verify the expected script
**type** of a **PackedScene**'s root node at design time.

## The Issue

One of Godot's notorious shortcomings is the inability to strongly type exported
**PackedScenes** in GDScript.

For instance, when exporting a scene intended to be an enemy:

```gdscript
@export var enemy_scene: PackedScene
```

We want to ensure that `enemy_scene` is a scene whose root node has a script
with `class_name Enemy`. If we accidentally assign a `Player` or a plain `Node`
scene, the code to instantiate and cast the node becomes fragile:

```gdscript
var instance: Enemy = enemy_scene.instantiate() as Enemy
if not instance:
 # We only find out about the mistake at runtime, potentially crashing the game!
 push_error("The assigned scene is not of the expected 'Enemy' type.")
```

Ideally, we would catch this configuration error in the editor before hitting
**Play**.

## The Solution

Godot Doctor provides a specialized utility function,
`ValidationCondition.scene_is_of_type()`, to solve this exact problem by
checking the `PackedScene`'s root script _class name_.

This function checks:

1. Is the `PackedScene` valid and assigned?
2. Does the root node of the scene have a script attached?
3. If a script exists, does it define a `class_name` that matches the
    `expected_type`?

It returns a `ValidationCondition` that fails if any of these checks do not
pass, allowing you to catch the error at design time. We use it in our
validation method (`_get_validation_conditions() -> Array[ValidationCondition]`)
like this:

```gdscript
## Returns a validation condition that checks whether the `packed_scene` is of `expected_type`.
ValidationCondition.scene_is_of_type(
    packed_scene: PackedScene,
    expected_type: Variant,
    variable_name: String = "Packed Scene"
)
```

## This Example

The `verify_type_of_packed_scene_example.tscn` scene contains four `Node`s, each
using the `scene_instantiator.gd` script. This script expects the exported
`scene_of_foo_type` property to be a `PackedScene` of type **Foo** (i.e., its
root node must have a script with `class_name Foo`).

The validation is set up in the script like this:

```gdscript
## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
    var conditions: Array[ValidationCondition] = [
        ValidationCondition.scene_is_of_type(scene_of_foo_type, Foo, "scene_of_foo_type")
    ]
    return conditions
```

Verifying this scene results in several errors:

- MySceneInstantiatorWithFooTypeScene is correctly assigned the
  scene_with_script_of_type_foo.tscn. This condition passes and requires no
  action.
- MySceneInstantiatorWithBarTypeScene is assigned a scene of type Bar, but the
  script expects Foo.
  - Resolution: Assign the correct scene, scene_with_script_of_type_foo.tscn, to
    the scene_of_foo_type property.
  - An alternative resolution is to assign a scene whose root node has a script
    with `class_name Bar` if that is the intended type (which would make sense,
    given its name). MySceneInstantiatorWithNoClassName is assigned a scene
    whose script has no class_name. This fails the type check for Foo.
  - Resolution: Assign the correct scene, scene_with_script_of_type_foo.tscn, to
    the scene_of_foo_type property.
  - An alternative resolution is to assign a scene whose root node has a script
    with a `class_name` defined, if that is the intended type.
    MySceneInstantiatorWithNoScript is assigned a scene with no script attached
    to its root node. This also fails the type check for Foo.
  - Resolution: Assign the correct scene, scene_with_script_of_type_foo.tscn, to
    the scene_of_foo_type property.
  - An alternative resolution is to assign a scene whose root node has a script
    with a `class_name` defined, if that is the intended type.
