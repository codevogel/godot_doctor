# Godot Doctor 👨🏻‍⚕️🩺

A powerful validation plugin for Godot that catches errors before they reach
runtime. Validate scenes, nodes, and resources using a declarative, test-driven
approach. No `@tool` required!

<!-- markdownlint-disable-next-line MD033 MD013 -->
<img src="https://raw.githubusercontent.com/codevogel/godot_doctor/refs/heads/main/github_assets/png/godot_doctor_logo.png" width="256" alt="godot doctor logo"/>

See Godot Doctor in action:

![Godot Doctor Example Gif](/github_assets/gif/doctor_example.gif)

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
- [Running Godot Doctor on the CLI](#running-godot-doctor-on-the-cli)
  - [CI/CD Integration](#cicd-integration)
- [How It Works](#how-it-works)
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

![Before and After Godot Doctor](/github_assets/png/before_after.png)

Or how about this:

![Before and After Godot Doctor](/github_assets/png/before_after_2.png)

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
ValidationCondition.is_scene_of_type(scene_of_foo_type, Foo)
```

### Automatic Scene Validation

Validations run automatically when you save scenes, providing immediate feedback
during development. Errors are displayed in a dedicated dock, and you can click
on them to navigate directly to the problematic nodes.

![Godot Doctor Example Gif](/github_assets/gif/doctor_example.gif)

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
methods on the `ValidationCondition` class, such as `is_scene_of_type`,
`is_instance_valid`, `is_string_not_empty`, and more, which saves you time
writing common validation logic.

You can find them all in
[the `ValidationCondition` class](/addons/godot_doctor/primitives/validation_condition.gd)

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

## Running Godot Doctor on the CLI

Godot Doctor can be run from the command line, allowing you to integrate it into
your CI/CD pipeline or run it as a standalone validation tool. While using it in
the editor provides real-time feedback, running it on the CLI can be useful for
automated checks during development or before commits, ensuring your entire
project adheres to your validation rules.

To run Godot Doctor on the CLI:

1. Create a `GodotDoctorValidationSuite` resource in your project. By default,
   it will generatively collect _all_ scenes and resources in your project. You
   can also exclude specific scripts or directories in the suite asset from this
   collection process, or create multiple custom validation suites that only
   validate specific scenes or resources.

   > ℹ️ There is an
   > [example](/addons/godot_doctor/examples/validation_suite_example/README.md)
   > that goes more in depth on how to set up validation suites.

2. Assign the suite resource to the `validation_suites` property of the
   `GodotDoctorSettings` resource
   (`addons/godot_doctor/settings/godot_doctor_settings.tres`).

3. run Godot Doctor on the CLI, use the following command:

   ```bash
   godot --headless --editor --quit-after 30 -- --run-godot-doctor
   ```

   > ℹ️ The `--quit-after 30` flag is used to ensure that Godot exits after 30
   > seconds, just in case there are any issues that cause the validation
   > process to hang. You can adjust this timeout as needed.

The output is presented in a tree structure, making it easy to identify which
scenes and nodes have validation issues:

![cli-output-example](/github_assets/png/cli_output.png)

The CLI output exits with a non-zero status code if any validation conditions
fail, making it easy to integrate into CI/CD pipelines.

### CI/CD Integration

You can integrate Godot Doctor into your CI/CD pipeline (e.g., GitHub Actions,
GitLab CI, Jenkins) to automatically validate your project on every push or pull
request. This helps catch issues early and maintain code quality across your
team.

An example GitHub Actions workflow may look like this:

```yaml
name: "Godot Doctor"

on:
  workflow_dispatch: # this allows you to manually trigger the workflow from the Actions tab in GitHub
  push:
    branches: ["**"]
  pull_request:
    branches: ["**"]

jobs:
  gdscript-checks:
    name: "Run Godot Doctor CLI"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
      - name: Install Godot
        run: |
          GODOT_VERSION="4.6.1"
          wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
          unzip -q "Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
          mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot
          chmod +x /usr/local/bin/godot
      - name: Import project
        run: godot --headless --editor --quit --quit-after 30 || true
      - name: "Run Godot Doctor CLI"
        run: godot --headless --editor --quit-after 30 -- --run-godot-doctor
```

Placing this file at `.github/workflows/godot_doctor.yaml` in your repository
will set up the workflow to run on every push and pull request, installing
Godot, importing the project, and executing Godot Doctor in headless mode. If
any validation conditions fail, the workflow will exit with a non-zero status,
causing the check to fail and alerting the developers to the issues that need to
be addressed.

You can setup GitHub to require this check to pass before allowing pull requests
to be merged, ensuring that all code merged into your main branches adheres to
your validation rules.

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

## Examples

There are many examples available that help you better understand how to use
Godot Doctor in your project, and how to write validation conditions for
different use cases. You can find them all in
[the examples README](/addons/godot_doctor/examples/README.md).

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
