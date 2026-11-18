extends Node
# Sons et musique générés par code (aucun fichier audio nécessaire).
# Deux bus audio : "Music" (volume réglable par le joueur) et "SFX" (bruitages).

const RATE := 22050
const MUSIC_RATE := 11025
const REST := 99
const HOLD := 98
const SETTINGS_PATH := "user://rubis_settings.cfg"
const BASS := [0, 12, 7, 12, 0, 12, 7, 12]

# Chaque piste : 4 mesures de 8 croches. "melody" = demi-tons par rapport à "root".
const TRACKS := {
	"gentle": {"bpm": 92.0, "root": 72, "bass_root": 48, "chords": [0, -5, -3, -7], "lead": "tri", "decay": 1.3, "hat": false,
		"melody": [[7, 98, 4, 98, 0, 98, 4, 7], [11, 98, 7, 98, 2, 98, 7, 11], [12, 98, 9, 98, 4, 98, 9, 12], [9, 98, 5, 98, 0, 4, 5, 9]]},
	"bright": {"bpm": 132.0, "root": 72, "bass_root": 48, "chords": [0, 9, 5, 7], "lead": "pulse", "decay": 3.0, "hat": true,
		"melody": [[4, 98, 7, 98, 12, 98, 7, 4], [9, 98, 12, 9, 7, 98, 4, 99], [5, 98, 9, 98, 12, 98, 9, 5], [7, 11, 14, 98, 11, 7, 2, 99]]},
	"dusk": {"bpm": 120.0, "root": 69, "bass_root": 45, "chords": [0, -2, -4, -5], "lead": "pulse", "decay": 3.0, "hat": true,
		"melody": [[0, 3, 7, 98, 12, 7, 3, 0], [-2, 2, 5, 98, 10, 5, 2, -2], [-4, 0, 3, 98, 8, 3, 0, -4], [-5, -1, 2, -1, 7, 4, 2, 99]]},
	"night": {"bpm": 150.0, "root": 74, "bass_root": 50, "chords": [0, -4, -2, -5], "lead": "square", "decay": 3.5, "hat": true,
		"melody": [[0, 0, 7, 0, 5, 3, 0, 99], [-4, -4, 3, -4, 0, 3, -4, 99], [-2, -2, 5, -2, 2, 5, 7, 5], [-5, -1, 2, -1, 7, 2, -1, 2]]},
}

signal volume_changed

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_next := 0
var sounds: Dictionary = {}
var tracks: Dictionary = {}
var current_track := ""
var music_volume := 0.5
var muted := false
var music_bus := 0
var sfx_bus := 0
var last_tick := 0.0

func _ready() -> void:
	music_bus = _ensure_bus("Music")
	sfx_bus = _ensure_bus("SFX")
	load_settings()
	apply_volume()
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)
	_pregenerate()

func _ensure_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	return idx

# Prépare les sons petit à petit (une chose par image) pour éviter tout ralentissement.
func _pregenerate() -> void:
	for id in TRACKS:
		await get_tree().process_frame
		if not tracks.has(id):
			tracks[id] = make_track(id)
	for id in ["jump", "stomp", "key", "hurt", "checkpoint", "click", "shoot", "pop", "unlock", "free", "clear", "dead", "boss_hit", "boss_down", "power", "win", "pause_open", "resume", "tick"]:
		await get_tree().process_frame
		if not sounds.has(id):
			sounds[id] = make_sound(id)

# ---------------------------------------------------------------- RÉGLAGES
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_volume = clampf(float(cfg.get_value("audio", "music", 0.5)), 0.0, 1.0)
		muted = bool(cfg.get_value("audio", "muted", false))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "muted", muted)
	cfg.save(SETTINGS_PATH)

func apply_volume() -> void:
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_mute(music_bus, muted or music_volume <= 0.001)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if music_volume > 0.001:
		muted = false
	apply_volume()
	save_settings()
	volume_changed.emit()

func toggle_mute() -> void:
	muted = not muted
	apply_volume()
	save_settings()
	volume_changed.emit()

# ---------------------------------------------------------------- LECTURE
func play(id: String) -> void:
	if sfx_players.is_empty():
		return
	if id == "tick":
		var now := Time.get_ticks_msec() / 1000.0
		if now - last_tick < 0.05:
			return
		last_tick = now
	if not sounds.has(id):
		sounds[id] = make_sound(id)
	var player := sfx_players[sfx_next]
	sfx_next = (sfx_next + 1) % sfx_players.size()
	player.stream = sounds[id]
	player.play()

func play_music(id: String) -> void:
	if music_player == null or id == current_track:
		return
	current_track = id
	if not tracks.has(id):
		tracks[id] = make_track(id)
	music_player.stream = tracks[id]
	music_player.play()

# ---------------------------------------------------------------- SYNTHÈSE
func _wave_id(wave: String) -> int:
	match wave:
		"sine":
			return 0
		"square":
			return 1
		"pulse":
			return 2
		"tri":
			return 3
		"saw":
			return 4
	return 5

func _osc(code: int, phase: float) -> float:
	var p := fposmod(phase, 1.0)
	match code:
		0:
			return sin(TAU * phase)
		1:
			return 1.0 if p < 0.5 else -1.0
		2:
			return 1.0 if p < 0.25 else -1.0
		3:
			return 4.0 * absf(p - 0.5) - 1.0
		4:
			return 2.0 * p - 1.0
	return randf() * 2.0 - 1.0

func _to_stream(buf: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var n := buf.size()
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var v := clampi(int(buf[i] * 30000.0), -32768, 32767)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = n
	return stream

# Segment : t = début (s), d = durée (s), f0 -> f1 = fréquence, w = forme d'onde, v = volume, k = vitesse d'extinction.
func seg(t: float, d: float, f0: float, f1: float, w: String, v: float, k: float) -> Dictionary:
	return {"t": t, "d": d, "f0": f0, "f1": f1, "w": w, "v": v, "k": k}

func notes_seq(freqs: Array, start: float, gap: float, length: float, wave: String, vol: float, decay: float) -> Array:
	var out: Array = []
	for i in range(freqs.size()):
		var f: float = freqs[i]
		out.append(seg(start + gap * float(i), length, f, f, wave, vol, decay))
	return out

func sound_defs(id: String) -> Array:
	match id:
		"jump":
			return [seg(0.0, 0.17, 320.0, 760.0, "square", 0.28, 7.0)]
		"stomp":
			return [seg(0.0, 0.13, 420.0, 110.0, "square", 0.4, 10.0), seg(0.0, 0.07, 0.0, 0.0, "noise", 0.25, 25.0)]
		"pop":
			return [seg(0.0, 0.15, 900.0, 200.0, "saw", 0.26, 12.0)]
		"key":
			return [seg(0.0, 0.12, 988.0, 988.0, "square", 0.24, 9.0), seg(0.09, 0.3, 1319.0, 1319.0, "square", 0.24, 6.0)]
		"unlock":
			return notes_seq([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.0, 0.08, 0.22, "square", 0.24, 6.0)
		"hurt":
			return [seg(0.0, 0.36, 420.0, 90.0, "saw", 0.34, 5.0), seg(0.0, 0.2, 0.0, 0.0, "noise", 0.22, 14.0)]
		"dead":
			return notes_seq([392.0, 330.0, 262.0, 196.0], 0.0, 0.22, 0.5, "tri", 0.45, 3.0)
		"checkpoint":
			return notes_seq([523.0, 659.0, 784.0], 0.0, 0.08, 0.2, "square", 0.22, 7.0)
		"free":
			var s: Array = notes_seq([523.0, 659.0, 784.0, 1047.0], 0.0, 0.09, 0.25, "square", 0.24, 5.0)
			s.append(seg(0.36, 0.6, 1319.0, 1319.0, "square", 0.24, 3.0))
			s.append(seg(0.36, 0.6, 659.0, 659.0, "tri", 0.3, 3.0))
			return s
		"shoot":
			return [seg(0.0, 0.22, 1400.0, 300.0, "saw", 0.22, 9.0), seg(0.0, 0.05, 0.0, 0.0, "noise", 0.18, 30.0)]
		"power":
			return notes_seq([600.0, 800.0, 1000.0, 1300.0, 1600.0, 2000.0], 0.0, 0.06, 0.3, "sine", 0.3, 5.0)
		"boss_hit":
			return [seg(0.0, 0.26, 170.0, 55.0, "square", 0.45, 7.0), seg(0.0, 0.18, 0.0, 0.0, "noise", 0.45, 12.0)]
		"boss_down":
			var b: Array = [seg(0.0, 1.0, 320.0, 40.0, "saw", 0.4, 2.5), seg(0.0, 1.0, 0.0, 0.0, "noise", 0.3, 3.0)]
			b.append_array(notes_seq([523.0, 659.0, 784.0, 1047.0], 0.7, 0.1, 0.4, "square", 0.22, 4.0))
			return b
		"clear":
			var c: Array = notes_seq([523.0, 659.0, 784.0], 0.0, 0.12, 0.25, "square", 0.24, 5.0)
			c.append(seg(0.36, 0.55, 1047.0, 1047.0, "square", 0.24, 3.0))
			c.append(seg(0.36, 0.55, 523.0, 523.0, "tri", 0.3, 3.0))
			return c
		"win":
			var w: Array = notes_seq([523.0, 659.0, 784.0, 1047.0, 784.0, 1047.0, 1319.0], 0.0, 0.13, 0.3, "square", 0.24, 4.0)
			w.append(seg(0.9, 1.3, 1568.0, 1568.0, "square", 0.22, 2.0))
			w.append(seg(0.9, 1.3, 784.0, 784.0, "tri", 0.3, 2.0))
			w.append(seg(0.9, 1.3, 523.0, 523.0, "tri", 0.3, 2.0))
			return w
		"click":
			return [seg(0.0, 0.06, 700.0, 950.0, "square", 0.2, 30.0)]
		"pause_open":
			return [seg(0.0, 0.07, 650.0, 450.0, "square", 0.2, 12.0), seg(0.07, 0.09, 450.0, 330.0, "square", 0.2, 12.0)]
		"resume":
			return [seg(0.0, 0.07, 330.0, 450.0, "square", 0.2, 12.0), seg(0.07, 0.09, 450.0, 650.0, "square", 0.2, 12.0)]
		"tick":
			return [seg(0.0, 0.035, 900.0, 900.0, "square", 0.13, 40.0)]
	return [seg(0.0, 0.05, 600.0, 600.0, "square", 0.15, 30.0)]

func make_sound(id: String) -> AudioStreamWAV:
	var segs: Array = sound_defs(id)
	var total := 0.0
	for s in segs:
		total = maxf(total, float(s["t"]) + float(s["d"]))
	var n := int(total * float(RATE)) + 1
	var buf := PackedFloat32Array()
	buf.resize(n)
	for s in segs:
		var start := int(float(s["t"]) * float(RATE))
		var dur := float(s["d"])
		var count := int(dur * float(RATE))
		var f0 := float(s["f0"])
		var f1 := float(s["f1"])
		var vol := float(s["v"])
		var decay := float(s["k"])
		var code := _wave_id(str(s["w"]))
		var phase := 0.0
		for i in range(count):
			var tt := float(i) / float(RATE)
			var f := lerpf(f0, f1, tt / dur)
			phase += f / float(RATE)
			var env := exp(-decay * tt) * minf(1.0, tt / 0.004) * minf(1.0, (dur - tt) / 0.02)
			var idx := start + i
			if idx < n:
				buf[idx] += vol * env * _osc(code, phase)
	return _to_stream(buf, RATE, false)

func hz(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)

func add_note(buf: PackedFloat32Array, start: int, count: int, freq: float, wave: String, vol: float, decay: float) -> void:
	var code := _wave_id(wave)
	var n := buf.size()
	var attack := 0.003 * float(MUSIC_RATE)
	var release := 0.012 * float(MUSIC_RATE)
	for i in range(count):
		var idx := start + i
		if idx >= n:
			break
		var tt := float(i) / float(MUSIC_RATE)
		var env := exp(-decay * tt) * minf(1.0, float(i) / attack) * minf(1.0, float(count - i) / release)
		buf[idx] += vol * env * _osc(code, freq * tt)

func make_track(id: String) -> AudioStreamWAV:
	var def: Dictionary = TRACKS[id]
	var bars: Array = def["melody"]
	var chords: Array = def["chords"]
	var root: int = def["root"]
	var bass_root: int = def["bass_root"]
	var lead: String = def["lead"]
	var lead_decay: float = def["decay"]
	var hat: bool = def["hat"]
	var step_samples := int(30.0 / float(def["bpm"]) * float(MUSIC_RATE))
	var buf := PackedFloat32Array()
	buf.resize(bars.size() * 8 * step_samples)
	for bar in range(bars.size()):
		var notes: Array = bars[bar]
		var chord: int = chords[bar]
		for s in range(8):
			var base := (bar * 8 + s) * step_samples
			# Basse
			var bass_note: int = bass_root + chord + int(BASS[s])
			add_note(buf, base, step_samples, hz(bass_note), "tri", 0.26, 5.0)
			# Mélodie
			var note: int = notes[s]
			if note < HOLD:
				var length := 1
				var k := s + 1
				while k < 8 and int(notes[k]) == HOLD:
					length += 1
					k += 1
				add_note(buf, base, int(float(length * step_samples) * 0.92), hz(root + note), lead, 0.17, lead_decay / float(length))
			# Petit rythme
			if hat and s % 2 == 1:
				add_note(buf, base, int(0.012 * float(MUSIC_RATE)), 0.0, "noise", 0.05, 20.0)
	return _to_stream(buf, MUSIC_RATE, true)
