class_name GodotDoctorUpdateChecker
extends Node

## Emitted when the update check is completed, regardless of the result,
## allowing the update checker to be freed after the check is done.
signal update_check_completed

#gdlint: disable=max-line-length
## The path for the plugin.cfg file, used to get the current version of the plugin.
const PLUGIN_CFG_PATH: String = "res://addons/godot_doctor/plugin.cfg"
## The GitHub API URL to check for the latest release of the plugin.
const GITHUB_API_LATEST_RELEASE_URL: String = "https://api.github.com/repos/codevogel/godot_doctor/releases/latest"
## The URL for the latest release page, used in the update message if a new version is available.
const PLUGIN_RELEASE_PAGE_URL: String = "https://github.com/codevogel/godot_doctor/releases/latest"
## A hint to the user that they can disable the update check if they don't want to see the message again.
const SILENCE_HINT = "(You can disable this check in the plugin settings if you don't want to see this message again.)"
#gdlint: enable=max-line-length

## The HTTPRequest node used to make the API request.
## Stored as a member variable to keep it alive during the request.
var _http: HTTPRequest


func _ready() -> void:
	check_for_updates()


## Checks GitHub for the latest release of the plugin and compares it to the current version.
func check_for_updates() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed, CONNECT_ONE_SHOT)

	var headers := ["User-Agent: GodotPlugin"]
	var err := _http.request(GITHUB_API_LATEST_RELEASE_URL, headers)
	if err != OK:
		push_warning("[GODOT DOCTOR]: Update Checker failed to start HTTP request: %s" % err)


## Callback for when the HTTP request is completed.
## Parses the response and checks if an update is available.
func _on_request_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	_http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.ResponseCode.RESPONSE_OK:
		push_warning("[GODOT DOCTOR]: Update Checker request failed. Code: %s" % response_code)
		update_check_completed.emit()
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		push_warning("[GODOT DOCTOR]: Update Checker failed to parse GitHub response.")
		update_check_completed.emit()
		return

	var tag: String = json.data.get("tag_name", "")
	if tag.is_empty():
		push_warning("[GODOT DOCTOR]: Update Checker response missing 'tag_name'.")
		update_check_completed.emit()
		return

	var latest: String = tag.lstrip("v")  # strips a leading "v" if present (e.g. "v1.3.0" → "1.3.0")
	var current: String = _get_current_version()

	if current.is_empty():
		push_warning("[GODOT DOCTOR]: Update Checker could not determine current plugin version.")
		update_check_completed.emit()
		return

	if _is_newer(latest, current):
		print(
			(
				"[GODOT DOCTOR]: Update available! Current: %s → Latest: %s\nGet it at: %s\n%s"
				% [current, latest, PLUGIN_RELEASE_PAGE_URL, SILENCE_HINT]
			)
		)
		GodotDoctorNotifier.push_toast(
			(
				"Update available for Godot Doctor plugin!\nCurrent: %s → Latest: %s"
				% [current, latest]
			),
			0
		)
	else:
		print("[GODOT DOCTOR]: Plugin is up to date (%s).\n%s" % [current, SILENCE_HINT])

	update_check_completed.emit()


## Get the current version of the plugin from plugin.cfg,
## stripping any build metadata (e.g. "1.0.0+docs" → "1.0.0").
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
