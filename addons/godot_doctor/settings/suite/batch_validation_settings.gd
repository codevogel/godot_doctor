## Resource used by the CLI interface. It holds lists of all Scenes and Resources that are to be 
## validated in a batched process.
class_name BatchValidationSettings extends Resource


# ============================================================================
# HELPER TYPES
# ============================================================================


## Enum defining how Warnings in the validation process should be treated.
enum WarningBehaviour {
		IGNORE_WARNINGS,		## Warnings will be reported, but will not fail validation.
		FAIL_ON_WARNINGS		## Warning will be reported and treated as errors, therefore will fail validation.
	}


# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================


## Defines how the whole batched validation process should deal with Warnings.
@export var warningBehaviour : WarningBehaviour

## List of all Validation Suites that are to be processed in batch.
@export var suites : Array[ValidationSuite]
