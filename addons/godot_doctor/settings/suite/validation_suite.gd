## Resource used by the CLI interface. It holds lists of Scenes and Resource that are to be 
## validated in a batched process. Used by [BatchValidationSettings].
class_name ValidationSuite extends Resource


# ============================================================================
# HELPER TYPES
# ============================================================================


## Enum defining how Warnings in the validation process should be treated.
enum WarningBehaviourOverride {
		INHERIT,				## Will use the settings in the parent [BatchValidationSettings].
		IGNORE_WARNINGS,		## Warnings will be reported, but will not fail validation.
		FAIL_ON_WARNINGS		## Warning will be reported and treated as errors, therefore will fail validation.
	}


# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================


## The human readable name of this suite. Used for reporting.
@export var name : String

## Defines how validation of this suite should deal with Warnings.
@export var warningBehaviourOverride : WarningBehaviourOverride

## Paths to scenes that are to be validated.
@export_file("*.tscn", "*.scn") var scenes : Array[String]

## Paths to resources that are to be validated.
@export_file("*.tres", "*.res") var resources : Array[String]
