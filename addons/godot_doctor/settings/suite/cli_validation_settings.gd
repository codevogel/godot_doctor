## Resource used by the CLI interface. It holds lists of all Scenes and Resources that are to be
## validated when running Godot Doctor from the command line,
## as well as settings on how to treat Warnings in the validation process.
class_name CLIValidationSettings extends Resource

# ============================================================================
# HELPER TYPES
# ============================================================================

## Enum defining how Warnings in the validation process should be treated.
## IGNORE_WARNINGS: Warnings will be reported, but will not fail validation.
## FAIL_ON_WARNINGS: Warning will be reported and treated as errors, therefore will fail validation.
enum WarningBehaviour { IGNORE_WARNINGS, FAIL_ON_WARNINGS }

# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================

## Defines how the whole batched validation process should deal with Warnings.
@export var warning_behaviour: WarningBehaviour

## List of all Validation Suites that are to be processed in batch.
@export var suites: Array[ValidationSuite]
