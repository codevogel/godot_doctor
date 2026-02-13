# Example: Validating Exported Resources and Their Internal State

This example demonstrates Godot Doctor's crucial ability to verify configuration
requirements both on an **exported Resource** and on the **internal properties**
of that Resource itself.

## The Issue: Limitations of Native Resource Validation

**Resource** files are central to Godot games, but they often have complex
configuration requirements that are difficult to enforce:

1. **Dynamic Property Constraints:** You might have a `Resource` representing a
    character's stats where the `current_health` must always be between `0` and
    `max_health`. While Godot's `@export_range` is useful, it only accepts
    constant limits. It cannot enforce dynamic constraints where one property's
    valid range depends on the value of another property within the same
    Resource.
2. **Broken References:** A Resource often links to other data like Textures,
    Scenes, or other Resources. If these links are forgotten (null) or the
    linked file is deleted, you get a **broken reference** that leads to
    frustrating runtime errors, as Godot offers no editor-time warning for this.

## The Solution

Godot Doctor allows you to define custom validation directly within the Resource
script, using the same **`_get_validation_conditions()`** mechanism used for
Nodes.

1. We can create a custom check to ensure that the `health` property is always
    greater than zero, and we can even make this check dynamic by referencing
    other properties of the `Resource`.

2. We can also create checks to ensure that all linked resources are valid and
    not null, helping us catch broken references at design time rather than at
    runtime.

We can report these errors directly from the `Resource` itself, or from any
`Node` that uses this `Resource`. (e.g. when inspecting a `Resource` instance in
the inspector, or when verifying a scene that references this `Resource`.)

## This Example

In this example, we have a scene, `verify_resource_example.tscn`, which contains
a `Node` `NodeWithExportedResource` that has a script attached to it,
`script_with_exported_resource.gd`.

This script exports a `my_resource` property of type `MyResource`, which is
defined in `my_resource.gd`.

Let's take a look at the `ValidationCondition` in
`script_with_exported_resource.gd`:

```gdscript
## Get `ValidationCondition`s for exported variables.
func _get_validation_conditions() -> Array[ValidationCondition]:
 return [
  # We rely on the default validaiton conditions here to see
  # if the resource is valid.
  # But, notice how we return an empty array in case the instance
  # is not null, or we might call get_validation_conditions on
  # a null instance.
  ValidationCondition.new(
   func() -> Variant:
    return (
     my_resource.get_validation_conditions()
     if is_instance_valid(my_resource)
     else []
    ),
   "This string will never be used"
  ),
  # If we would turn off the default validation checks, we might
  # manually want to report that the resource is null
  # Here's an example of that:
  #
  # ValidationCondition.new(
  #  func() -> Variant:
  #   if not is_instance_valid(my_resource):
  #    return false
  #   return my_resource.get_validation_conditions(),
  #  "my_resource has not been assigned!"
  # ),
 ]

```

Verifying this scene results in an error:

- The `my_resource` property is not assigned.
  - You can resolve this error by assigning the `my_resource.tres` instance from
    the example folder to the `my_resource` property in the inspector.

- Note that we can define in- and get the validation conditions directly from
  the `my_resource` script. (This does require the `MyResource` class to be
  annotated with `@tool`.)

  ```gdscript
  ## The signature is _get_validation_conditions(),
  ## so the validator can report incorrect values when inspecting this resource in the inspector.
  func _get_validation_conditions() -> Array[ValidationCondition]:
      var conditions: Array[ValidationCondition] = [
          ValidationCondition.simple(
              my_int >= my_min_int and my_int <= my_max_int,
              "my_int must be between %d and %d, but is %s." % [my_min_int, my_max_int, my_int]
          ),
          ValidationCondition.simple(my_string != "", "my_string must not be empty."),
          ValidationCondition.simple(
              my_max_int >= my_min_int, "my_max_int must be greater than or equal to my_min_int."
          ),
          ValidationCondition.simple(
              my_min_int <= my_max_int, "my_min_int must be less than or equal to my_max_int."
          )
      ]
      return conditions


  ## We can expose it publicly as well,
  ## so we can call it from other Nodes during scene validation,
  ## and return a nested array of `ValidationCondition`s
  func get_validation_conditions() -> Array[ValidationCondition]:
      return _get_validation_conditions()
  ```

- Assigning the `my_resource` instance results in further errors, as the default
  resource state is invalid:
  - The **`my_string`** property is empty.
    - You can resolve this error by setting a non-empty value to the `my_string`
      property in the inspector.
  - The **`my_int`** property is set to `-1`, which is outside the required
    range of the `my_min_int` (`0`) and `my_max_int` (`10`) properties.
    - You can resolve this error by assigning it a value between `my_min_int`
      and `my_max_int` (e.g., `5`) in the inspector.
  - Tip: try setting `my_min_int` or `my_max_int` to contradictory values (e.g.
    the `min` greater than the `max`) and see how the error message also catch
    those.

Last thing to try is to close the example scene, and just open the
`my_resource.tres` instance directly in the inspector. You will see the same
validation errors reported directly in the inspector for the resource instance
itself.
