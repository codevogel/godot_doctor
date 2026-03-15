# Example: Validation Suites (Manual + Generated)

This example demonstrates how to configure a `GodotDoctorValidationSuite` for
CLI/headless validation, both with **generated suite contents** and **manual
suite contents**.

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

This folder contains `validation_suite.tres`, configured in **generated mode**:

```gdresource
[resource]
treat_warnings_as_errors = true
generate_suite_contents = true
directories_to_include = Array[String](["res://addons/godot_doctor/examples/general_example"])
```

This means the suite will:

1. Automatically scan `general_example` recursively,
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

## Key Takeaway

Use **generated suites** when you want low-maintenance, directory-driven
validation coverage, and **manual suites** when you need precise control.
