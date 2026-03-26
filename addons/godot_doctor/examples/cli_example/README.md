# Example: Using Godot Doctor on the Command Line

This example demonstrates how to configure a `GodotDoctorValidationSuite` for
CLI/headless validation, both with **generated suite contents** and **manual
suite contents**.

It also refers to the [main README](/addons/godot_doctor/README.md) for
instructions on setting up GitHub Actions workflows, XML report generation, and
job summaries based on the XML report.

## The Issue

When validating in CI or headless mode, you usually don't want to validate the
entire project every time. You often need to:

1. Validate a specific set of scenes/resources for a focused check, or
2. Automatically validate everything in selected directories without manually
   maintaining a long list.

Without validation suites, that setup quickly becomes hard to maintain as the
project grows.

## The Solution

Godot Doctor provides `GodotDoctorValidationSuite`, which lets you define
exactly what to validate in CLI mode.

Each suite supports two modes:

1. **Generated mode** (`generate_suite_contents = true`)
   - Build suite contents automatically from directories and filter rules:
     `directories_to_include`, `directories_to_exclude`, `scenes_to_exclude`,
     and `resources_to_exclude`.
2. **Manual mode** (`generate_suite_contents = false`)
   - Use the **Suite Contents** lists (`_scenes` and `_resources`) to explicitly
     define every scene/resource in the suite.

Additionally, each suite can enable `treat_warnings_as_errors` for stricter CI
pipelines.

## This Example

This directory contains `example_validation_suite.tres`, which is a
ValidationSuite that works through the **generated mode**:

```gdresource
[resource]
treat_warnings_as_errors = true
generate_suite_contents = true
directories_to_include = Array[String](["res://addons/godot_doctor/examples/gdscript/general_example"])
```

This means the suite will:

1. Automatically scan the `general_example` directory recursively,
2. Include matching scenes (`*.tscn`, `*.scn`) and resources (`*.tres`,
   `*.res`),
3. Treat warnings as errors in CLI output.

### Generated Setup (How To)

This mode is ideal when project files change frequently and you want the suite
to stay up to date automatically. It prevents the suite from becoming stale as
you forget to add new scenes/resources to it as the project evolves.

1. Create a new resource of type `GodotDoctorValidationSuite`.
2. Set `generate_suite_contents` to `true`.
3. Configure filters:
   - `directories_to_include` to define scan roots (empty means whole project)
   - `directories_to_exclude` to skip subtrees
   - `scenes_to_exclude` and `resources_to_exclude` for per-file overrides
4. Open `addons/godot_doctor/settings/godot_doctor_settings.tres` and add your
   suite resource to `validation_suites`.

### Manual Setup (How To)

This mode is ideal when you want exact, deterministic control over what gets
validated.

1. Create a new resource of type `GodotDoctorValidationSuite`.
2. Set `generate_suite_contents` to `false`.
3. Add explicit paths to **Suite Contents**:
   - `_scenes` (for `*.tscn`/`*.scn`)
   - `_resources` (for `*.tres`/`*.res`)
4. Open `addons/godot_doctor/settings/godot_doctor_settings.tres` and add your
   suite resource to `validation_suites`.

## GitHub Actions Workflow Setup

For workflow setup instructions, refer to the main README:

- [CI/CD Integration](/addons/godot_doctor/README.md#cicd-integration)

## XML Report Setup

For XML report configuration and output details, refer to:

- [Generating a JUnit-like XML Report](/addons/godot_doctor/README.md#generating-a-junit-like-xml-report)

## Job Summary Setup from the XML Report

For generating a GitHub Actions Job Summary from the XML report, refer to the
same main README section above and use the script included in this example as a
starting point:

- [`godot_doctor_job_summary_reporter.py`](/addons/godot_doctor/examples/cli_example/godot_doctor_job_summary_reporter.py)
- [Generating a JUnit-like XML Report](/addons/godot_doctor/README.md#generating-a-junit-like-xml-report)

## Key Takeaway

Use **generated suites** when you want low-maintenance, directory-driven
validation coverage, and **manual suites** when you need precise control.

It's possible to setup a runner workflow that runs Godot Doctor on the command
line, generate an XML report from the results, and then use that XML report to
process the results into any downstream tools you want, such as a script that
generates a GitHub Actions Job Summary.
