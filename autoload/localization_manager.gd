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


func apply_direction(root: Node) -> void:
	_apply_direction_recursive(root, is_rtl())


func _apply_direction_recursive(node: Node, rtl: bool) -> void:
	if node is Control:
		var control := node as Control
		_set_if_present(control, "layout_direction", 3 if rtl else 2)
		if control is Label:
			var label := control as Label
			if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
		elif control is Button:
			var button := control as Button
			var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_RIGHT if rtl else HORIZONTAL_ALIGNMENT_LEFT
			_set_if_present(button, "alignment", alignment)
			_set_if_present(button, "text_alignment", alignment)
	for child in node.get_children():
		_apply_direction_recursive(child, rtl)


func _set_if_present(object: Object, property_name: String, value: Variant) -> void:
	for property in object.get_property_list():
		if String(property.get("name", "")) == property_name:
			object.set(property_name, value)
			return


func _load_language(lang: String) -> Dictionary:
	var path := "res://data/localization/%s.json" % lang
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
