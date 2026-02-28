# Example: CLI Validation

This example holds an example `CLIValidationSettings` resource, which is used to
run Godot Doctor in the CLI.

To test the CLI, set it as the `cli_validation_settings` property in the
`addons/godot_doctor/settings/godot_doctor_settings.tres` resource, and then run
the CLI as explained in the
[CLI instructions](../../README.md#command-line-interface).

You should see any warnings or errors reported as per the other examples. If
you've walked through those examples and fixed the issues, you should see the
validation pass without any warnings or errors.
