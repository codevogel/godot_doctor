## A class representing a range of integers
## with customizable inclusivity for the start and end points.
## Used by [ValidationCondition] for validating integer values against specified ranges.
class_name GodotDoctorRangeInt
extends RefCounted

## The start of the range.
var start: int = NAN
## The end of the range.
var end: int = NAN
## Whether the end of the range is included in the range.
## If [code]true[/code], the range includes the end value.
var inclusive: bool = false


## Initializes the [GodotDoctorRangeInt] with the given parameters.
## [param start] is the start of the range. [param end] is the end of the range.
## [param inclusive_end] determines whether [param end] is included in the range.
## By default, the range is exclusive.
## [br][br]
## Example:
## [codeblock]
## GodotDoctorRangeInt.new(1, 10)       # contains [1 ... 9]
## GodotDoctorRangeInt.new(1, 10, true) # contains [1 ... 10]
## [/codeblock]
func _init(start: int = 0, end: int = 0, inclusive_end: bool = false) -> void:
	if start > end:
		push_error("end of GodotDoctorRangeInt must be greater than start.")
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return
	self.start = start
	self.end = end
	self.inclusive = inclusive_end


## Returns [code]true[/code] if [param value] is within this range,
## [code]false[/code] otherwise.
func contains(value: int) -> bool:
	if inclusive:
		return value >= start and value <= end
	return value >= start and value < end


## Returns [code]true[/code] if [param other] is completely within this range,
## [code]false[/code] otherwise.
func contains_range(other: GodotDoctorRangeInt) -> bool:
	if other.start < start:
		return false
	if other.end > end:
		return false
	if other.end == end and not inclusive and other.inclusive:
		return false
	return true
