# Godot Doctor Examples

This folder contains various scenes and scripts demonstrating Godot Doctor's
capabilities to validate common configuration challenges in a Godot project.

Examples are split into two folders:

- **[`gdscript/`](./gdscript/)** — GDScript examples
- **[`csharp/`](./csharp/)** — C# examples

Each sub-folder contains a specific example scene (`.tscn`) and a dedicated
**`README.md`** file that explains the issue being solved, the validation logic
used, and how to reproduce/resolve the errors.

## Example Summaries

> Note that all examples include both GDScript and C# variants!

### [General example](./gdscript/general_example/)

**Core Concept:** **General Validation Use Cases** A collection of various
validation scenarios in a 'real-world' context.

### [verify_default_validations_example](./gdscript/verify_default_validations_example/README.md)

**Core Concept:** **No-Code Default Validations** Demonstrates Godot Doctor's
automatic validation of exported properties without writing any validation code.
Shows how default validations catch null object references and empty strings
with zero custom code.

### [verify_resource_example](./gdscript/verify_resource_example/README.md)

**Core Concept:** **Chained Validation & Resource Limits** Shows how a **Node**
validates the existence of an exported **Resource**, then chains the validation
to check the **internal properties** of that Resource for dynamic range limits
and required values.

### [verify_exports_example](./gdscript/verify_exports_example/README.md)

**Core Concept:** **Node Exported Property Validation** Demonstrates basic
validation on a **Node's exported properties**, ensuring correct data types
(e.g., `int > 0`), non-empty strings, and that assigned Node references meet
specific criteria (e.g., a required name).

### [verify_type_of_packed_scene_example](./gdscript/verify_type_of_packed_scene_example/README.md)

**Core Concept:** **Strongly Typing PackedScenes** Solves the common problem of
non-strongly typed `PackedScene` exports by verifying that the root node of the
assigned scene has a script attached with the **expected `class_name`**.

### [verify_node_path_example](./gdscript/verify_node_path_example/README.md)

**Core Concept:** **Verifying Node Paths (`$`)** Shows how to use validation
conditions to check at design time that **nodes referenced by path**
(`$NodeName`) actually exist in the scene tree, preventing hard-to-debug runtime
"Node not found" errors.

### [verify_tool_script_example](./gdscript/verify_tool_script_example/README.md)

**Core Concept:** **@tool Script Validation (Improved)** Highlights using Godot
Doctor as a superior alternative to native `_get_configuration_warnings()` for
**@tool scripts**, offering cleaner syntax, automatic updates, and better
separation of logic.

### [verify_child_count_example](./gdscript/verify_child_count_example/README.md)

**Core Concept:** **Validating Child Node Counts** Demonstrates how to verify
the number of child nodes attached to a node, including exact counts, minimums,
maximums, and no-children constraints.

### [cli_example](./cli_example/README.md)

**Core Concept:** **Validation Suite Setup (Manual + Generated)** Demonstrates
how to configure `GodotDoctorValidationSuite` resources for CLI/headless
validation, both by manually listing scenes/resources and by generating suite
contents from directory filters, with links to the main README for GitHub
Actions workflow setup, XML report export, and Job Summary generation.

To get started, simply open any of the scenes inside the respective sub-folders
and run the Godot Doctor validation check.
