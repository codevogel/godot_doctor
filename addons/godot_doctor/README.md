# Godot Doctor 👨🏻‍⚕️🩺

A powerful validation plugin for Godot that catches errors before they reach
runtime. Validate scenes, nodes, and resources using a declarative, test-driven
approach, in either `gdscript` or `C#`. No `@tool` required!

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
2. Copy the `addons/godot_doctor` folder to your project's `addons/` directory.
   (Optional:) If you don't use `C#` in your project, you can safely delete the
   `addons/godot_doctor/core/csharp` and the
   `addons/godot_doctor/examples/csharp` directories.

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
  - [IValidatable Interface](#ivalidatable-interface)
- [Running Godot Doctor on the CLI](#running-godot-doctor-on-the-cli)
  - [CI/CD Integration](#cicd-integration)
  - [Generating a JUnit-like XML Report](#generating-a-junit-like-xml-report)
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

<!-- markdownlint-disable-next-line MD033 MD013 -->
<details>
<!-- markdownlint-disable-next-line MD033 MD013 -->
<summary>
More examples
</summary>

![C# Wrapper example](/github_assets/png/csharp_wrapper_example.png)

![C# Wrapper resource example](/github_assets/png/csharp_wrapper_resource_example.png)

</details>

### Verify type of PackedScene

Godot has a problem with `PackedScene` type safety.
[We can not strongly type PackedScenes](https://github.com/godotengine/godot-proposals/issues/782).
This means that you may want to instantiate a scene that represents a `Friend`,
but accidentally assign an `Enemy` scene instead. Oops! Godot Doctor can
validate the type of a `PackedScene`, ensuring that the root of the scene that
you are instancing is of the expected type (e.g. has a script attached of that
type), before you even run the game.

**GDscript:**

```gdscript
## Example: A validation condition that checks whether the `PackedScene`
##          variable `scene_of_foo_type` is of type `Foo`.
ValidationCondition.is_scene_of_type(scene_of_foo_type, Foo)
```

**C#:**

```csharp
// Example: A validation condition that checks whether the `PackedScene`
// variable `PackedSceneOfFooType` is of type `Foo`.
ValidationCondition.IsSceneOfType<Foo>(PackedSceneOfFooType)
```

<!-- markdownlint-disable-next-line MD033 MD013 -->
<details>

<!-- markdownlint-disable-next-line MD033 MD013 -->
<summary>
For verifying the type of an inherited `PackedScene`, you can use any of the
following search strategies provided by the `ValidationCondition` class:
</summary>

```gdscript
enum InheritanceSearchStrategy {
 ## Only consider the root node of the PackedScene referenced,
 ## regardless of whether it has a script or not.
 ## i.e. the root node of the directly referenced scene,
 ## even if it has a scene as a parent scene.
 DIRECT,
 ## Only consider the very topmost root node of the PackedScene's inheritance chain,
 ## regardless of whether it has a script or not.
 ## i.e. the root node of the base scene that has no further parents.
 TOPMOST_ROOT,
 ## Only consider the first root node in the PackedScene's inheritance chain,
 ## that has a script attached.
 ## i.e. the root node of the first parent scene that has a script, starting
 ## from the directly referenced scene and moving up the inheritance chain.
 FIRST_SCRIPT_ROOT,
 ## Only consider the last root node in the PackedScene's inheritance chain,
 ## that has a script attached.
 ## i.e. the root node of the last parent scene that has a script.
 LAST_SCRIPT_ROOT
}

```

</details>

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

**GDscript:**

Just add a `_get_validation_conditions()` method script that returns an array of
`ValidationCondition` objects to any `.gd` script:

```gdscript
func _get_validation_conditions() -> Array[ValidationCondition]:
  return [
    ValidationCondition.new(
      func(): return health > 0,
      "Health must be greater than 0"
    ),
    ValidationCondition.simple(
      health > 0,
      "Health must be greater than 0"
    ),
    ValidationCondition.is_scene_of_type(scene_of_foo_type, Foo)
  ]
```

Note: You do not need to add `@tool` to `Node` scripts for this to work, so you
can keep your gameplay code clean and focused! However, if you want to validate
a `Resource` script, you _will_ need to add `@tool` to that script, due to
engine limitations. However, Resource scripts don't need to be guarded against
running editor code in runtime, so the `@tool` annotation should be all you
need.

**C#:**

Implement the `IValidatable` interface and a public implementation of the
`GetValidationConditions()` method that returns a `Godot.Collections.Array`.
(This interface is optional, but it makes it easier to implement consistently).

Create an `System.Array<VAlidationCondition>` of
`GodotDoctor.Core.Primitives.ValidationCondition` objects, then convert it to a
`Godot.Collections.Array` using the `ToGodotArray()` extension method:

```csharp
public Array GetValidationConditions()
{
   ValidationCondition[] conditions =
   [
      new ValidationCondition(
         () => InitialHealth > 0,
         "Initial health must be greater than 0"
      ),
      ValidationCondition.Simple(
         InitialHealth > 0,
         "Initial health must be greater than 0"
      ),
      ValidationCondition.IsSceneOfType<Foo>(SceneOfFooType)
   ];
   return conditions.ToGodotArray();
}
```

Note: Just like with GDScript, you do not need to add the `[Tool]` attribute to
`Node` scripts for this to work, so you can keep your gameplay code clean and
focused! However, if you want to validate a `Resource` script, you _will_ need
to add the `[Tool]` attribute to that script, due to engine limitations.
However, Resource scripts don't need to be guarded against running editor code
in runtime, so the `[Tool]` attribute should be all you need.

### ValidationCondition

The core of Godot Doctor is the `ValidationCondition` class, which takes a
callable and an error message:

**GDscript:**

```gdscript
# Basic validation condition
var condition = ValidationCondition.new(
    func(): return health > 0,
    "Health must be greater than 0"
)
```

**C#:**

```csharp
// Basic validation condition in C#
var condition = new ValidationCondition(
  () => health > 0,
  "Health must be greater than 0"
);
```

Optionally, you can also pass one of three severity levels (`INFO`, `WARNING`,
`ERROR`) as a third argument, which will adjust at what level of severity the
error is reported in the Godot Doctor dock:

**GDscript:**

```gdscript
# Validation condition with severity level
var condition = ValidationCondition.new(
    func(): return health > 0,
    "Health must be greater than 0",
    ValidationCondition.Severity.ERROR
)
```

**C#:**

```csharp
// Validation condition with severity level in C#
var condition = new ValidationCondition(
  () => health > 0,
  "Health must be greater than 0",
  ValidationCondition.Severity.ERROR
);
```

### Simple validations

For basic boolean validations, use the convenience `simple()` method, allowing
you to skip the `func()` wrapper:

**GDscript:**

```gdscript
# Equivalent to the above, but more concise
var condition = ValidationCondition.simple(
    health > 0,
    "Health must be greater than 0"
)
```

**C#:**

```csharp
// Equivalent to the above, but more concise in C#
var condition = ValidationCondition.Simple(
  health > 0,
  "Health must be greater than 0"
);
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

**GDscript:**

```gdscript
func _is_more_than_zero(value: int) -> bool:
  return value > 0

var condition = ValidationCondition.simple(
  _is_more_than_zero(health),
  "Health must be greater than 0"
)
```

**C#:**

```csharp
private bool IsMoreThanZero(int value)
{
  return value > 0;
}

var condition = ValidationCondition.Simple(
  IsMoreThanZero(health),
  "Health must be greater than 0"
);
```

### Abstract Away Complex Logic

Or abstract away complex logic into separate methods:

**GDscript:**

```gdscript
var condition = ValidationCondition.new(
  complex_validation_logic,
  "Complex validation failed"
)

func complex_validation_logic() -> bool:
 # Complex logic here
```

**C#:**

```csharp
var condition = new ValidationCondition(
  ComplexValidationLogic(value),
  "Complex validation failed"
);

// C# implementation of the complex logic in a separate method
private static bool ComplexValidationLogicImplementation(int value) {
  // Complex logic here
};

// Wrapper function to return a Godot Variant from the implementation
private static System.Func<Variant> ComplexValidationLogic(int value) => () => ComplexValidationLogicImplementation(value);


```

### Nested Validation Conditions

Making use of variatic typing, Validation conditions can return arrays of other
validation conditions, allowing you to nest validation logic where needed:

**GDscript:**

```gdscript
ValidationCondition.new(
  func() -> Variant:
  if not is_instance_valid(weapon_resource):
  # We return false in case the weapon resource is null
  return false
  # or an array of this resource's conditions in case it is valid.
  return weapon_resource.get_validation_conditions(),
  "Weapon resource validation failed"
)
```

**C#:**

```csharp
new ValidationCondition(
   () =>
   {
      if (IsInstanceValid(WeaponResource))
      {
         return WeaponResource.GetValidationConditions();
      }
      return false;
   },
   "Weapon resource is not valid."
)
```

## IValidatable Interface

The C# wrapper also includes a `IValidatable` interface that you can implement
on your C# scripts, which makes it easier to add validation conditions to your
script without needing to remember the exact method signature of
`GetValidationConditions()`:

```csharp
public partial class ExampleMyEnemy : Node, IValidatable
{
   /// <summary>The health value the enemy starts with.</summary>
   [Export]
   public int InitialHealth { get; set; } = 120;

   /// <summary>The maximum health value the enemy can have.</summary>
   [Export]
   public int MaxHealth { get; set; } = 100;

   public Array GetValidationConditions()
   {
      ValidationCondition[] conditions =
      [
         ValidationCondition.Simple(
            InitialHealth <= MaxHealth,
            "Initial health should not be greater than max health."
         ),
      ];
      return conditions.ToGodotArray();
   }
}
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
   > [example](/addons/godot_doctor/examples/cli_example/README.md) that goes
   > more in depth on how to set up validation suites.

2. Assign the suite resource to the `validation_suites` property of the
   `GodotDoctorSettings` resource
   (`addons/godot_doctor/settings/godot_doctor_settings.tres`).

3. run Godot Doctor on the CLI, use the following command:

   ```bash
   godot --headless --editor --quit-after 30 -- --run-godot-doctor
   ```

   > ℹ️ The `--quit-after 30` flag is used to ensure that Godot exits after 30
   > seconds, just in case there the plugin doesn't initialize properly. You can
   > adjust this timer as needed.

The output is presented in a tree structure, making it easy to identify which
scenes and nodes have validation issues:

![cli-output-example](/github_assets/png/cli_output.png)

The CLI output exits with a non-zero status code if any validation conditions
fail, making it easy to integrate into CI/CD pipelines.

> Currently, there is no proper built-in way to have an EditorPlugin wait for
> the editor to finish initializing when running in headless mode. There is an
> [open proposal](https://github.com/godotengine/godot-proposals/issues/14502)
> to address this, but until then, timing the run of the CLI is a bit hacky.
>
> So as a workaround, the plugin currently detects this through an internal
> editor hook (`_set_window_layout`). However, this hook is not guaranteed to
> fire in all environments. For example, on some CI runners there is no saved
> editor layout, and the `_set_window_layout` may not be called. To handle this,
> Godot Doctor provides two fallback timer settings in the `GodotDoctorSettings`
> resource (`addons/godot_doctor/settings/godot_doctor_settings.tres`).
> `fallback_cli_delay_before_start` determines how long to wait for the editor
> hook to fire before starting validation regardless of editor initialization,
> and `fallback_cli_delay_before_quit` determines how long to allow the
> validation run to execute before force-quitting with exit code `1`. This
> ensures that the CLI validation process doesn't hang indefinitely if something
> goes wrong. (Note that these timeouts are separate from the `--quit-after`
> flag passed to Godot, which is used for when the plugin doesn't initialize at
> all.) You can adjust these timeouts as needed based on the expected
> initialization time of your project, to save on runner minutes.

### CI/CD Integration

You can integrate Godot Doctor into your CI/CD pipeline (e.g., GitHub Actions,
GitLab CI, Jenkins) to automatically validate your project on every push or pull
request. This helps catch issues early and maintain code quality across your
team.

An example GitHub Actions workflow may look like this:

```yaml
name: "Godot Doctor"

on:
  # Allow the workflow to be triggered manually from the GitHub Actions tab
  workflow_dispatch:
  # Trigger the workflow on push to any branch
  push:
    branches: ["**"]
  # Trigger the workflow on pull request to any branch
  pull_request:
    branches: ["**"]

jobs:
  # This job runs the Godot Doctor CLI to analyze the project and (optionally) generate a report
  godot-doctor:
    name: "Run Godot Doctor CLI 🩺"
    runs-on: ubuntu-latest
    steps:
      # Checkout the repository to access the Godot project files
      - uses: "actions/checkout@v6.0.2"
      # Install Godot
      - name: "Install Godot"
        run: |
          GODOT_VERSION="4.6.1"
          wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
          unzip -q "Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
          mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot
          chmod +x /usr/local/bin/godot
      # Import the project first to ensure that it is ready for analysis.
      - name: Import project
        # This quits as soon as the project is imported, which is sufficient
        # for preparing the project for analysis
        # We use `--quit-after 30` as a failsafe so the runner doesn't hang
        # indefinitely if something goes wrong during importing
        # You may want to adjust this timeout if you find that your project
        # takes longer than 30 seconds to import.
        run: godot --headless --editor --quit --quit-after 30
      - name: "Run Godot Doctor CLI"
        # Now we run Godot Doctor again, this time running Godot Doctor through the CLI.
        # Again, we use `--quit-after 30` as a failsafe to prevent hanging indefinitely.
        run: godot --headless --editor --quit-after 30 -- --run-godot-doctor
      # Optional: When using the `enable_xml_report` setting, you can upload
      # the generated XML report as an artifact for later analysis
      - name: "Upload Godot Doctor Report"
        # Run regardless of the success or failure of the previous step,
        # as we want to know the results of Godot Doctor even if
        # it finds issues in the project, and thus fails the previous step.
        if: always()
        uses: actions/upload-artifact@v7
        with:
          # The name of the artifact can be anything you like.
          # Here we use "godot-doctor-report" for clarity.
          name: godot-doctor-report
          # The path to the generated XML report.
          # This should match the path you configured in the settings resource.
          path: tests/reports/godot_doctor_report.xml
      # Optional: You can also summarise the report in the workflow logs for a quick overview.
      # (See the next section 'Generating a JUnit-like XML Report' for more details
      #  on the XML report and how to generate it.)
      - name: Summarise report
        if: always()
        # The contents of this script can be found in the `cli_example` example.
        run:
          python3 .github/workflows/scripts/godot_doctor_job_summary_reporter.py
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

### Generating a JUnit-like XML Report

In addition to the console output, you can configure Godot Doctor to generate a
JUnit-like XML report of the validation results. This makes it easier to parse
the results of the report in later stages of your CI/CD pipeline, such as
generating a
[Job Summary](https://github.blog/news-insights/product-news/supercharging-github-actions-with-job-summaries/)
that shows the validation results in a human-readable format directly in the
GitHub Actions UI. (An example of such a script is found in the
[cli_example](/addons/godot_doctor/examples/cli_example/).)

To enable XML report generation, set the `export_xml_report` property to `true`
in the `GodotDoctorSettings` resource. Optionally, you can also specify the
output directory and filename for the XML report using the
`xml_report_output_dir` (default: `res://tests/reports/`) and
`xml_report_filename` (default: `godot_doctor_report.xml`). properties.

> ℹ️ Don't forget to add the output directory to your `.gitignore`, as you
> likely don't want to commit generated reports to your repository.

The XML report option will generate a report as such:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites tests="7" messages="9" failures="8" harderrors="4" warnings="4" infos="1" timestamp="2026-03-21T12:21:11">
  <testsuite name="example_validation_suite.tres" path="res://addons/godot_doctor/examples/cli_example/example_validation_suite.tres" tests="7" messages="9" failures="8" harderrors="4" warnings="4" infos="1">
    <testcase name="general_example.tscn" path="res://addons/godot_doctor/examples/gdscript/general_example/general_example.tscn" type="scene" tests="5" messages="6" failures="5" harderrors="3" warnings="2" infos="1">
      <node name="FooSpawner" path="MyGame/FooSpawner" messages="2" failures="2" harderrors="1" warnings="1" infos="0">
        <harderror>packed_scene_of_foo_type is not a valid instance.</harderror>
        <warning type="promoted_to_error">packed_scene_of_foo_type is null.</warning>
      </node>
      <node name="MyEnemy" path="MyGame/MyEnemy" messages="1" failures="1" harderrors="0" warnings="1" infos="0">
        <warning type="promoted_to_error">Initial health should not be greater than max health.</warning>
      </node>
      <node name="PlayerController" path="MyGame/PlayerController" messages="1" failures="1" harderrors="1" warnings="0" infos="0">
        <harderror>player is not a valid instance.</harderror>
      </node>
      <node name="Player" path="MyGame/Player" messages="1" failures="0" harderrors="0" warnings="0" infos="1">
        <info>Player name longer than 12 characters may cause UI issues.</info>
      </node>
      <node name="WeaponSpawner" path="MyGame/WeaponSpawner" messages="1" failures="1" harderrors="1" warnings="0" infos="0">
        <harderror>weapon_resource is not a valid instance.</harderror>
      </node>
    </testcase>
    <testcase name="example_scene_foo_type.tscn" path="res://addons/godot_doctor/examples/gdscript/general_example/example_scene_foo_type.tscn" type="scene" tests="1" messages="0" failures="0" harderrors="0" warnings="0" infos="0">
    </testcase>
    <testcase name="example_weapon.tres" path="res://addons/godot_doctor/examples/gdscript/general_example/example_weapon.tres" type="resource" tests="1" messages="3" failures="3" harderrors="1" warnings="2" infos="0">
      <resource name="example_weapon.tres" path="res://addons/godot_doctor/examples/gdscript/general_example/example_weapon.tres" messages="3" failures="3" harderrors="1" warnings="2" infos="0">
        <harderror>sprite is not a valid instance.</harderror>
        <warning type="promoted_to_error">Damage should be a positive value.</warning>
        <warning type="promoted_to_error">Melee reach should not be greater than ranged reach.</warning>
      </resource>
    </testcase>
  </testsuite>
</testsuites>
```

The `xml` report is JUnit-_like_, meaning it follows a structure somewhat
similar to the XML reports generated by testing frameworks like JUnit. Godot
Doctor takes some liberties with the structure to better fit the validation
context, so here's a breakdown of the structure:

- The top-level element is `<testsuites>`, which collects all the validation
  suites that were run.
- Each `<testsuite>` element represents a `GodotDoctorValidationSuite` resource,
  tallying up the statistics for all the scenes and resources that were
  validated as part of that suite. The `name` attribute corresponds to the name
  of the suite resource, and the `path` attribute indicates the file path to
  that resource.
- Inside each `<testsuite>`, there are `<testcase>` elements, which represent
  individual scenes or resources that were validated. The `name` attribute is
  the name of the scene or resource, the `path` attribute is the file path to
  that scene or resource, and the `type` attribute indicates whether it's a
  scene or a resource.
- Within each `<testcase>`, there are either `<node>` elements or `<resource>`
  elements, depending on the `type` of the testcase.
  - `<node>` elements represent individual nodes in a scene that had validation
    messages reported. The `name` attribute is the name of the node, and the
    `path` attribute is the node's path within the scene.
  - `<resource>` elements represent individual resources that had validation
    messages reported. The `name` attribute is the name of the resource, and the
    `path` attribute is the file path to that resource.
- Inside each `<node>` or `<resource>`, there are `<harderror>`, `<warning>`,
  and `<info>` elements, which represent the individual validation messages that
  were reported for that node or resource. The text content of these elements is
  the error message associated with the validation condition that failed.
- Each `<testsuites>`, `<testsuite>`, `<testcase>`, `<node>`, and `<resource>`
  element includes attributes that tally up the total number of tests, messages,
  failures, hard errors, warnings, and infos that were reported at that level of
  the hierarchy.

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
