## Static helper for all styled terminal output used by [GodotDoctorCLI].
## Centralises color codes, formatting, and print patterns so call sites stay readable.
class_name CLIPrinter

## Represents the result state of a single validation item.
## Used to select the appropriate color and label for status lines.
enum Status { PASSED, FAILED, IGNORED }

## ANSI-safe colors guaranteed to render correctly in TUI environments.
enum TextColor { BLACK, RED, GREEN, YELLOW, LIGHT_YELLOW, BLUE, MAGENTA, CYAN, WHITE, GRAY }

const _HEADER_BORDER: String = "=============================================="
const _STAT_COLUMN_WIDTH: int = 16

const _COLOR_NAME: Dictionary = {
	TextColor.BLACK: "black",
	TextColor.RED: "red",
	TextColor.GREEN: "green",
	TextColor.YELLOW: "yellow",
	TextColor.LIGHT_YELLOW: "#ffff55",
	TextColor.BLUE: "blue",
	TextColor.MAGENTA: "magenta",
	TextColor.CYAN: "cyan",
	TextColor.WHITE: "white",
	TextColor.GRAY: "gray",
}

const _STATUS_LABEL: Dictionary = {
	Status.PASSED: "Passed",
	Status.FAILED: "Failed",
	Status.IGNORED: "Ignored",
}

const _STATUS_COLOR: Dictionary = {
	Status.PASSED: TextColor.GREEN,
	Status.FAILED: TextColor.RED,
	Status.IGNORED: TextColor.YELLOW,
}

const _SEVERITY_COLOR: Dictionary = {
	ValidationCondition.Severity.ERROR: TextColor.RED,
	ValidationCondition.Severity.WARNING: TextColor.LIGHT_YELLOW,
}


## Prints a file path as a scene/resource group header, separating directory from filename.
static func print_file_header(path: String) -> void:
	var directory: String = path.get_base_dir() + "/"
	var filename: String = path.get_file()
	print_rich("\n[b]In %s[/b]" % filename)
	print_rich(_colorize(directory, TextColor.GRAY))


## Prints the plugin startup line, e.g. "Starting Godot Doctor v1.2."
static func print_startup(version: String) -> void:
	print_rich(
		"Starting " + _colorize("[b]Godot Doctor[/b]", TextColor.BLUE) + " v" + version + "."
	)


## Prints a bordered section header, e.g. for the run summary.
static func print_header(title: String) -> void:
	print_rich("\n" + _colorize(_HEADER_BORDER, TextColor.YELLOW))
	print_rich(_colorize("= " + title, TextColor.YELLOW))
	print_rich(_colorize(_HEADER_BORDER, TextColor.YELLOW))


## Prints the suite start line, e.g. "Running validation suite: MyScene".
static func print_suite_header(suite_name: String) -> void:
	print_rich("\n" + _colorize("Running validation suite: ", TextColor.BLUE) + suite_name)


## Prints a tabbed status line for a validated item, e.g. "  [Passed] : MyNode".
static func print_status(object_name: String, status: Status) -> void:
	_print_labeled_line("\t", _STATUS_LABEL[status], object_name, _STATUS_COLOR[status])


## Prints the final pass/fail summary line at the end of the run.
static func print_final_result(fail_count: int) -> void:
	if fail_count > 0:
		print_rich(
			"\n\n" + _colorize("---- " + str(fail_count) + " failing tests. ----", TextColor.RED)
		)
	else:
		print_rich("\n\n" + _colorize("---- All tests passed! ----", TextColor.GREEN))


## Prints a plain-text section subheader with an underline, e.g. "Totals\n------".
static func print_section(title: String) -> void:
	print(title)
	print("-".repeat(title.length()))


## Prints a single labelled stat row, e.g. "Suites          4".
static func print_stat(label: String, value) -> void:
	print(label.rpad(_STAT_COLUMN_WIDTH) + str(value))


## Prints a severity-coloured message with a bold label, e.g. "  ERROR: Couldn't load file."
## An optional [param severity_name] overrides the default label derived from [param severity].
static func print_message(
	prefix: String,
	message: String,
	severity: ValidationCondition.Severity,
	severity_name: String = ""
) -> void:
	if severity_name.is_empty():
		severity_name = ValidationCondition.Severity.find_key(severity)
	_print_labeled_line(prefix, severity_name, message, _SEVERITY_COLOR.get(severity, -1))


# ============================================================================
# PRIVATE HELPERS
# ============================================================================


static func _print_labeled_line(
	prefix: String, label: String, text: String, color: TextColor
) -> void:
	var body: String = "[b]" + label + ": [/b]" + text
	if color == -1:
		print_rich(prefix + body)
	else:
		print_rich(prefix + _colorize(body, color))


static func _colorize(text: String, color: TextColor) -> String:
	return "[color=%s]%s[/color]" % [_COLOR_NAME[color], text]
