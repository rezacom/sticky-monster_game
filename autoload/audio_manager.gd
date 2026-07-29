extends Node

var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cache: Dictionary = {}
var next_sfx_player := 0
var music_player: AudioStreamPlayer


func _ready() -> void:
	for index in range(8):
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	_build_sfx_cache()
	_apply_settings()
	SaveManager.save_changed.connect(_apply_settings)
	play_music("menu")


func play_sfx(name: String, vibrate_ms: int = 0) -> void:
	if vibrate_ms > 0 and bool(SaveManager.get_setting("vibration_enabled", true)):
		Input.vibrate_handheld(vibrate_ms)
	if not bool(SaveManager.get_setting("sfx_enabled", true)):
		return
	var stream: AudioStreamWAV = sfx_cache.get(name, sfx_cache.get("button")) as AudioStreamWAV
	if stream == null or sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	player.stop()
	player.stream = stream
	var sfx_volume: float = clampf(float(SaveManager.get_setting("sfx_volume", 0.85)), 0.0, 1.0)
	player.volume_db = linear_to_db(max(0.001, sfx_volume))
	player.play()


func play_music(_name: String) -> void:
	if music_player == null:
		return
	if music_player.stream == null:
		music_player.stream = _make_tone([196.0, 246.94, 293.66, 392.0], 1.9, 0.18, true)
	_apply_settings()
	if bool(SaveManager.get_setting("music_enabled", true)) and not music_player.playing:
		music_player.play()


func _apply_settings() -> void:
	if music_player != null:
		var music_volume: float = clampf(float(SaveManager.get_setting("music_volume", 0.75)), 0.0, 1.0)
		var music_enabled: bool = bool(SaveManager.get_setting("music_enabled", true))
		music_player.volume_db = linear_to_db(max(0.001, music_volume * 0.42))
		music_player.stream_paused = not music_enabled
		if music_enabled and music_player.stream != null and not music_player.playing:
			music_player.play()
	for player in sfx_players:
		var sfx_volume: float = clampf(float(SaveManager.get_setting("sfx_volume", 0.85)), 0.0, 1.0)
		player.volume_db = linear_to_db(max(0.001, sfx_volume))


func _build_sfx_cache() -> void:
	sfx_cache = {
		"button": _make_tone([740.0, 920.0], 0.07, 0.38),
		"aim": _make_tone([360.0, 420.0], 0.08, 0.18),
		"launch": _make_tone([240.0, 520.0, 760.0], 0.16, 0.34),
		"coin": _make_tone([880.0, 1320.0], 0.12, 0.42),
		"exit": _make_tone([520.0, 780.0, 1040.0], 0.28, 0.38),
		"stick": _make_tone([180.0, 140.0], 0.12, 0.28),
		"soft_hit": _make_tone([180.0], 0.08, 0.26),
		"hard_hit": _make_tone([90.0, 65.0], 0.18, 0.42),
		"portal": _make_tone([420.0, 630.0, 840.0], 0.2, 0.26)
	}


func _make_tone(frequencies: Array, duration: float, volume: float, loop: bool = false) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(duration * float(mix_rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var t: float = float(sample_index) / float(mix_rate)
		var phase_ratio: float = float(sample_index) / float(max(1, sample_count - 1))
		var env: float = sin(phase_ratio * PI)
		if loop:
			env = 0.72 + sin(phase_ratio * TAU) * 0.08
		var value := 0.0
		for note_index in range(frequencies.size()):
			var freq: float = frequencies[note_index]
			value += sin(TAU * freq * t) / float(frequencies.size())
		value *= volume * env
		var int_sample := int(clampf(value, -1.0, 1.0) * 32767.0)
		if int_sample < 0:
			int_sample = 65536 + int_sample
		bytes[sample_index * 2] = int_sample & 0xff
		bytes[sample_index * 2 + 1] = (int_sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	return stream
