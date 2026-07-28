extends Node

var sfx_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for index in range(6):
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)
	_apply_settings()
	SaveManager.save_changed.connect(_apply_settings)


func play_sfx(_name: String, vibrate_ms: int = 0) -> void:
	if vibrate_ms > 0 and bool(SaveManager.get_setting("vibration_enabled", true)):
		Input.vibrate_handheld(vibrate_ms)
	# Audio files are optional in this build. Missing streams intentionally do nothing.


func play_music(_name: String) -> void:
	_apply_settings()


func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(float(SaveManager.get_setting("sfx_volume", 0.85))))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not bool(SaveManager.get_setting("sfx_enabled", true)))
