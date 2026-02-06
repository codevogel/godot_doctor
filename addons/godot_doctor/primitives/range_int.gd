## A class representing a range of integers
## with customizable inclusivity for the start and end points.
## Used in GodotDoctor for validating integer values against specified ranges.
class_name RangeInt
extends RefCounted

## The start of the range.
var start: int = NAN
## The end of the range.
var end: int = NAN
## Whether the end of the range is included in the range.
## If true, the range includes the end value.
var inclusive: bool = false


## Initializes the RangeInt with the given parameters.
## `start` is the start of the range. `end` is the end of the range.
## `inclusive` determines if the range contains `end`.
## By default, the range is exclusive.
## e.g.
## RangeInt(1, 10) will contain [1 ... 9].
## RangeInt(1, 10, true) will contain [1 ... 10].
func _init(start: int = 0, end: int = 0, inclusive_end: bool = false) -> void:
	if start > end:
		push_error("end of RangeInt must be greater than start.")
		return
	self.start = start
	self.end = end
	self.inclusive = inclusive_end


## Returns true if the value is within the range, false otherwise.
func contains(value: int) -> bool:
	if inclusive:
		return value >= start and value <= end
	return value >= start and value < end


## Returns true if the other RangeInt is completely within this range, false otherwise.
func contains_range(other: RangeInt) -> bool:
	if other.start < start:
		return false
	if other.end > end:
		return false
	if other.end == end and not inclusive and other.inclusive:
		return false
	return true
