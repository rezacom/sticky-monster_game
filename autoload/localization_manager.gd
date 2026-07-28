extends Node

signal language_changed(language: String)

var language := "en"
var strings: Dictionary = {}


func _ready() -> void:
	language = String(SaveManager.get_setting("language", "en"))
	set_language(language, false)


func set_language(new_language: String, persist: bool = true) -> void:
	if new_language != "fa" and new_language != "en":
		new_language = "en"
	language = new_language
	strings = _load_language(language)
	if persist:
		SaveManager.update_setting("language", language)
	emit_signal("language_changed", language)


func tr_key(key: String) -> String:
	return String(strings.get(key, key))


func is_rtl() -> bool:
	return language == "fa"


func _load_language(lang: String) -> Dictionary:
	var path := "res://data/localization/%s.json" % lang
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
