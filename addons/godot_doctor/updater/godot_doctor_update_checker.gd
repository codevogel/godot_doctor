class_name GodotDoctorUpdateChecker
extends Node

const PLUGIN_CFG_PATH := "res://addons/godot_doctor/plugin.cfg"
const GITHUB_API_URL := "https://api.github.com/repos/codevogel/godot_doctor/releases/latest"
const RELEASE_PAGE_URL := "https://github.com/codevogel/godot_doctor/releases/latest"

var _http: HTTPRequest


func _ready() -> void:
	check_for_updates()


func check_for_updates() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	var headers := ["User-Agent: GodotPlugin"]
	var err := _http.request(GITHUB_API_URL, headers)
	if err != OK:
		push_warning("[GODOT DOCTOR]: Update Checker failed to start HTTP request: %s" % err)


func _on_request_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	_http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("[GODOT DOCTOR]: Update Checker request failed. Code: %s" % response_code)
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		push_warning("[GODOT DOCTOR]: Update Checker failed to parse GitHub response.")
		return

	var tag: String = json.data.get("tag_name", "")
	if tag.is_empty():
		return

	var latest := tag.lstrip("v")  # strips a leading "v" if present (e.g. "v1.3.0" → "1.3.0")
	var current := _get_current_version()

	if current.is_empty():
		return

	if _is_newer(latest, current):
		print(
			(
				"[GODOT DOCTOR]: Update available! Current: %s → Latest: %s\nGet it at: %s"
				% [current, latest, RELEASE_PAGE_URL]
			)
		)
	else:
		print("[GODOT DOCTOR]: Plugin is up to date (%s)." % current)


func _get_current_version() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(PLUGIN_CFG_PATH) != OK:
		push_warning("[GODOT DOCTOR]: Update Checker could not load plugin.cfg")
		return ""
	return cfg.get_value("plugin", "version", "").split("+")[0]


# Returns true if `a` is strictly newer than `b` (semver: major.minor.patch)
func _is_newer(a: String, b: String) -> bool:
	# Strip build metadata (e.g. "1.0.0+docs" → "1.0.0")
	var pa := a.split("+")[0].split(".")
	var pb := b.split("+")[0].split(".")
	for i in 3:
		var na := int(pa[i]) if i < pa.size() else 0
		var nb := int(pb[i]) if i < pb.size() else 0
		if na != nb:
			return na > nb
	return false
