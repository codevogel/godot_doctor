# Godot Doctor 👨🏻‍⚕️🩺

A powerful validation plugin for Godot that catches errors before they reach
runtime. Validate scenes, nodes, and resources using a declarative, test-driven
approach. No `@tool` required!

<!-- markdownlint-disable-next-line MD033 MD013 -->
<img src="https://raw.githubusercontent.com/codevogel/godot_doctor/refs/heads/main/github_assets/png/godot_doctor_logo.png" width="256" alt="godot doctor logo"/>

See Godot Doctor in action:

![Godot Doctor Example Gif](./github_assets/gif/doctor_example.gif)

## Quickstart 🚀

You can download Godot Doctor
[directly from the Editor through the Asset Library](https://godotengine.org/asset-library/asset/4374).

Or, by manual installation:

1. Download the source code .zip from the
   [latest release](https://github.com/codevogel/godot_doctor/releases/latest).
2. Copy the `addons/godot_doctor` folder to your project's `addons/` directory
3. Enable the plugin in Project Settings > Plugins
4. (Optional:) Adjust the settings asset in `addons/godot_doctor/settings`.

## Table of Contents

- [What is Godot Doctor?](#what-is-godot-doctor)
- [Why Use Godot Doctor?](#why-use-godot-doctor)
  - [No-code validations](#no-code-default-validations)
  - [No `@tool` Required](#no-tool-required)
  - [Verify type of PackedScene](#verify-type-of-packedscene)
  - [Automatic Scene Validation](#automatic-scene-validation)
  - [Validate Nodes AND Resources](#validate-nodes-and-resources)
  - [Test-Driven Validation](#test-driven-validation)
  - [Declarative Syntax](#declarative-syntax)
- [Syntax](#syntax)
  - [ValidationCondition](#validationcondition)
  - [Simple](#simple-validations)
  - [Predefined Common Validation Conditions](#predefined-common-validation-conditions)
  - [Reuse validation logic with Callables](#reuse-validation-logic-with-callables)
  - [Abstract Away Complex Logic](#abstract-away-complex-logic)
  - [Nested Validation Conditions](#nested-validation-conditions)
- [How It Works](#how-it-works)
- [Command Line Interface](#command-line-interface)
- [Examples](#examples)
- [Installation](#installation)
- [License](#license)
  - [Attribution](#attribution)
- [Contributing, Bug Reports & Feature Requests](#contributing-bug-reports--feature-requests)

## What is Godot Doctor?

Godot Doctor is a Godot plugin that validates your scenes and nodes using a
declarative, test-driven approach. Instead of writing procedural warning code,
you define validation conditions using callables that focus on validation logic
first, with error messages as metadata.

## Why Use Godot Doctor?

### No-code default validations

Realistically, when you add any `@export` variables, you don't want them to stay
unassigned. Nor do you want to `@export` a string only for it to stay empty. But
we often forget to assign a value to these. So, new in Godot Doctor v1.1 are
**default validation conditions**:

Godot Doctor will validate any nodes that have scripts attached to them (and any
opened resource), scan it's `@export` properties, and automatically reports on
unassigned objects and empty strings, **without even needing to write a single
line of validation code**!

> ℹ️ You can turn off default validations alltogether in the settings asset, or
> you can add scripts to the ignore list, which will only disable default
> validations for those specific scripts.

### No `@tool` Required

Unlike
[`_get_configuration_warnings()`](https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-private-method-get-configuration-warnings),
Godot Doctor works without requiring the
[`@tool`](https://docs.godotengine.org/en/4.5/tutorials/plugins/running_code_in_the_editor.html#what-is-tool)
annotation on your scripts. This means that you no longer have to worry about
your gameplay code being muddied by editor-specific logic.

See the difference for yourself:

![Before and After Godot Doctor](./github_assets/png/before_after.png)

Or how about this:

![Before and After Godot Doctor](./github_assets/png/before_after_2.png)

Our gameplay code stays much more clean and focused!

### Verify type of PackedScene

Godot has a problem with `PackedScene` type safety.
[We can not strongly type PackedScenes](https://github.com/godotengine/godot-proposals/issues/782).
This means that you may want to instantiate a scene that represents a `Friend`,
but accidentally assign an `Enemy` scene instead. Oops! Godot Doctor can
validate the type of a `PackedScene`, ensuring that the root of the scene that
you are instancing is of the expected type (e.g. has a script attached of that
type), before you even run the game.

```gdscript
## Example: A validation condition that checks whether the `PackedScene`
##          variable `scene_of_foo_type` is of type `Foo`.
ValidationCondition.scene_is_of_type(scene_of_foo_type, Foo)
```

### Automatic Scene Validation

Validations run automatically when you save scenes, providing immediate feedback
during development. Errors are displayed in a dedicated dock, and you can click
on them to navigate directly to the problematic nodes.

![Godot Doctor Example Gif](./github_assets/gif/doctor_example.gif)

### Validate Nodes AND Resources

Godot Doctor can not only validate nodes in your scene, but `Resource` scripts
can define their own validation conditions as well. Very useful for validating
whether your resources have conflicting data (i.e. a value that is higher than
the maximum value), or missing references (i.e. an empty string, or a missing
texture).

### Test-Driven Validation

Godot Doctor encourages you to write validation logic that resembles unit tests
rather than write code that returns strings containing warnings. This
encourages:

- Testable validation logic
- Organized code
- Better maintainability
- Human-readable validation conditions
- Separation of concerns between validation logic and error messages

### Declarative Syntax

Where `_get_configuration_warnings()` makes you write code that generates
strings, Godot Doctor lets you design your validation logic separately from the
error messages, making it easier to read and maintain.

## Syntax

### ValidationCondition

The core of Godot Doctor is the `ValidationCondition` class, which takes a
callable and an error message:

```gdscript
# Basic validation condition
var condition = ValidationCondition.new(
    func(): return health > 0,
    "Health must be greater than 0"
)
```

Optionally, you can also pass one of three severity levels (`INFO`, `WARNING`,
`ERROR`) as a third argument, which will adjust at what level of severity the
error is reported in the Godot Doctor dock:

```gdscript
# Validation condition with severity level
var condition = ValidationCondition.new(
    func(): return health > 0,
    "Health must be greater than 0",
    ValidationCondition.Severity.ERROR
)
```

### Simple validations

For basic boolean validations, use the convenience `simple()` method, allowing
you to skip the `func()` wrapper:

```gdscript
# Equivalent to the above, but more concise
var condition = ValidationCondition.simple(
    health > 0,
    "Health must be greater than 0"
)
```

### Predefined Common Validation Conditions

There's also a bunch of often-used validation conditions available as static
methods on the `ValidationCondition` class, such as `scene_is_of_type`,
`is_instance_valid`, `string_not_empty`, and more, which saves you time writing
common validation logic.

You can find them all in
[the `ValidationCondition` class](./addons/godot_doctor/primitives/validation_condition.gd)

### Reuse validation logic with Callables

Using `Callables` allows you to reuse common validation methods:

```gdscript
func _is_more_than_zero(value: int) -> bool:
  return value > 0

var condition = ValidationCondition.simple(
  _is_more_than_zero(health),
  "Health must be greater than 0"
)
```

### Abstract Away Complex Logic

Or abstract away complex logic into separate methods:

```gdscript
var condition = ValidationCondition.new(
  complex_validation_logic,
  "Complex validation failed"
)

func complex_validation_logic() -> bool:
 # Complex logic here
```

### Nested Validation Conditions

Making use of variatic typing, Validation conditions can return arrays of other
validation conditions, allowing you to nest validation logic where needed:

```gdscript
ValidationCondition.new(
   func() -> Variant:
    if not is_instance_valid(my_resource):
     return false
    return my_resource.get_validation_conditions(),
   "my_resource must be assigned."
  )
```

## How It Works

1. **Automatic Discovery**: When you save a scene, Godot Doctor scans all nodes
   for `@export` properties and a `_get_validation_conditions()` method
2. **Instance Creation**: For non-`@tool` scripts, temporary instances are
   created to run validation logic
3. **Condition Evaluation**: Each validation condition's callable is executed
4. **Error Reporting**: Failed conditions display their error messages in the
   Godot Doctor dock
5. **Navigation**: Click on errors in the dock to navigate directly to the
   problematic nodes

## Command Line Interface

Also supplied in this repo is the `gd_cmdln.gd` script that can be run from the command line.

The script will run validations of set scenes (`*.tscn/*.scn`files) and resources (`*.tres/*.res` files).

The script will return `0` if all validation succeed and `1` if any validation fail. While providing Error and Warning information to the console. This makes it useful for integration into CI/CD (Continuous Integration / Continuous Delivery) pipelines.

### Usage

From the command line, at the root of your project, use the following command to run the script. 
```
[godot] --headless --debug --script addons/godot_doctor/godot_doctor_cmdln.gd
```

* `[godot]` - the path to the Godot Editor executable.
* `--headless` - tells Godor to run in headless mode - without the GUI. This is required on platforms that do not have GPU access, such most CI/CD servers.
* `--debug` - tells Godot to run in debug mode which can by helpful by providing more information to the console.
* `--script` - tells Godot to run a script, in this case Godot Doctor in CLI mode.

It should be possible to run the script from outside the project root by using the `--path` option.

### Configuration

Behaviour of the Godot Doctor Command Line Interface is managed by a `BatchValidationSettings` resource. It contains lists of Validation Suites, that contain lists of scenes and resources that are to be validated, as well as configuration on how to handle Warnings.

The Godot Doctor settings resource (found at `addons/godot_doctor/settings/godot_doctor_settings.tres`) needs to link to a `BatchValidationSettings` resource. It will be automatically picked by the CLI when run.

**NOTE:** The default locations of the `BatchValidationSettings` resource is 'res://test/batch_validation_settings.tres' and that's the default path used by the Godot Doctor settings. However, that file is not supplies, it needs be create manually.  

## Examples

For detailed examples and common validation patterns, see
[the examples README](./addons/godot_doctor/examples/README.md).

## Installation

1. Copy the `addons/godot_doctor` folder to your project's `addons/` directory
2. Enable the plugin in Project Settings > Plugins
3. The Godot Doctor dock will appear in the editor's left panel
4. `use_default_validations` is on by default in the settings resource
   (`addons/godot_doctor/settings/godot_doctor_settings.tres`), so it will start
   reporting any of the [default validations](#no-code-default-validations) as
   soon as you save a scene.
5. Start adding custom validations by adding a `_get_validation_conditions()`
   method to your scripts, then save your scenes to see validation results!

## License

Godot Doctor is released under the MIT License. See the LICENSE file for
details.

### Attribution

If you end up using Godot Doctor in your project, a line in your credits would
be very much appreciated! 🐦

## Contributing, Bug Reports & Feature Requests

Godot Doctor is open-source and welcomes any contributions! Feel free to open
issues or submit pull requests on
[GitHub](https://github.com/codevogel/godot_doctor/).
