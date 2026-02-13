# Example: No-Code Default Validations

This example demonstrates Godot Doctor's **default validations** feature, which
automatically validates exported properties without requiring you to write any
validation code.

## The Issue

When working with `@export` properties in Godot, it's common to forget to assign
values to object references or leave strings empty. This leads to runtime
errors:

```gdscript
@export var some_string: String = ""  # Oops, left empty!
@export var some_reference: SomeClass  # Oops, forgot to assign!

func _ready():
    # This fails at runtime because some_reference is null
    some_reference.call_method(some_string)
```

Ideally, we'd catch these configuration mistakes **at design time** in the
editor without writing validation code.

## The Solution

Godot Doctor's **default validations** automatically check your `@export`
properties for:

1. **Object References:** Ensures that exported `Object` types are valid
   instances (not `null`)
2. **Strings:** Ensures that exported `String` types are non-empty (after
   stripping whitespace)

These checks run automatically when you save your scene, **without requiring any
validation code** to be written.

## This Example

The scene `verify_default_validations_example.tscn` contains a node that has the
script `script_with_default_validations.gd` attached. This script demonstrates
how default validations work with two exported properties that violate the
validation rules:

1. `some_string` - A string property that is empty by default
2. `some_script_that_we_refer_to` - An object reference that is null by default

Notice that the script has **no `_get_validation_conditions()` method** and **no
custom validation code**. Yet Godot Doctor will still validate these properties
automatically.

### Running the Example

When you open this scene and Godot Doctor validates it, you'll see **four
validation errors**: For both nodes, the following errors will be reported:

1. **`some_string` is empty:** The default value `""` fails the default string
   validation
   - **Resolution:** Set a non-empty string value for **Some String** in the
     Inspector
2. **`some_script_that_we_refer_to` is null:** The default value is unassigned,
   failing the default object validation
   - **Resolution:** Create or assign an instance of `SomeScriptThatWeReferTo`
     to the **Some Script That We Refer To** property in the Inspector

For the `NodeWithIgnoredDefaultValidations` node, the above errors will also be
reported. We can add the `script_with_ignored_default_validations.gd` script to
the `default_validation_ignore_list` in the settings asset
(godot_doctor_settings.tres) to ignore these default validations for that
script, which will remove the errors for that node.

> ℹ️ You can open the settings asset (godot_doctor_settings.tres) and set the
> `ignore_default_validations` property to `true` to ignore these default
> validations altogether.

### Key Takeaway

Default validations provide powerful validation with **zero code overhead**:
your gameplay code stays clean while Godot Doctor ensures data integrity at
design time.
