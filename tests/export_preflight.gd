extends SceneTree
## Read-only Windows export-path check using Godot's native ConfigFile parser.
## Does not run an export, modify a preset, or execute the existing binary.

func _init() -> void:
	var failures: Array[String] = []
	var config := ConfigFile.new()
	if config.load("res://export_presets.cfg") != OK:
		failures.append("Cannot load export_presets.cfg")
	var selected := ""
	for section in config.get_sections():
		if config.get_value(section, "name", "") == "Windows Desktop":
			selected = section
	if selected.is_empty():
		failures.append("Missing Windows Desktop preset")
	var version := Engine.get_version_info()
	var template_version := "%d.%d.%d.%s" % [version.major, version.minor, version.patch, version.status]
	var template_directory := OS.get_environment("APPDATA").path_join("Godot/export_templates").path_join(template_version)
	for file in ["windows_debug_x86_64.exe", "windows_release_x86_64.exe"]:
		if not FileAccess.file_exists(template_directory.path_join(file)):
			failures.append("Missing matching template: " + file)
	var output := ""
	if not selected.is_empty():
		output = String(config.get_value(selected, "export_path", ""))
		if not output.ends_with(".exe") or not output.begins_with("./.export/"):
			failures.append("Unexpected export target; do not overwrite it")
		var excluded := String(config.get_value(selected, "exclude_filter", ""))
		for pattern in ["tests/*", "tools/*", ".codex/*", ".chainlink/*", "addons/gut/*"]:
			if not excluded.contains(pattern):
				failures.append("Missing development exclusion: " + pattern)
	var report := {"passed": failures.is_empty(), "failures": failures, "preset": "Windows Desktop", "template_version": template_version, "output": output, "export_performed": false, "exported_build_smoke": "NOT PERFORMED"}
	DirAccess.make_dir_recursive_absolute("user://structural_audio_overhaul_20260906")
	var file := FileAccess.open("user://structural_audio_overhaul_20260906/export_preflight.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("EXPORT_PREFLIGHT=" + JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
