class_name BatchValidationSettings extends Resource

enum WarningBehaviour { IGNORE_WARNINGS, FAIL_ON_WARNINGS }

@export var warningBehaviour : WarningBehaviour

@export var suites : Array[ValidationSuite]
