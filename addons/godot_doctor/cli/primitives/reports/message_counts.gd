class_name MessageCounts

var info: int = 0
var warning: int = 0
var hard_error: int = 0
var warnings_as_errors: int = 0

var total: int:
    get:
        return info + warning + hard_error

var total_errors: int:
    get:
        return hard_error + warnings_as_errors

func add(other: MessageCounts) -> void:
    info += other.info
    warning += other.warning
    hard_error += other.hard_error
    warnings_as_errors += other.warnings_as_errors
