extends RefCounted

const SAMPLE_RATE := 22050


static func create_jump_stream() -> AudioStreamWAV:
	var duration := 0.18
	var samples: Array[float] = []

	for i in range(int(SAMPLE_RATE * duration)):
		var t: float = float(i) / float(SAMPLE_RATE)
		var freq: float = 540.0 + 420.0 * (1.0 - t / duration)
		var amp: float = 0.32 * _envelope(t, duration, 0.005, 0.08)
		samples.append(_square_wave(freq, t) * amp)

	return _build_stream(samples)


static func create_land_stream() -> AudioStreamWAV:
	var duration := 0.22
	var samples: Array[float] = []

	for i in range(int(SAMPLE_RATE * duration)):
		var t: float = float(i) / float(SAMPLE_RATE)
		var thump: float = sin(TAU * 95.0 * t) * exp(-15.0 * t) * 0.45
		var noise_basis: float = sin(1783.0 * t) + sin(2411.0 * t * 1.17)
		var noise: float = noise_basis * exp(-26.0 * t) * 0.08
		var amp: float = _envelope(t, duration, 0.002, 0.1)
		samples.append((thump + noise) * amp)

	return _build_stream(samples)


static func create_music_stream() -> AudioStreamWAV:
	var seconds_per_beat := 60.0 / 132.0
	var beats := 32
	var duration: float = beats * seconds_per_beat
	var samples: Array[float] = []

	var lead_pattern := [76, 79, 83, 79, 74, 79, 81, 79]
	var bass_pattern := [40, 40, 43, 43, 36, 36, 38, 38]
	var chord_pattern := [[64, 67], [64, 71], [67, 71], [62, 69]]

	for i in range(int(SAMPLE_RATE * duration)):
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat: float = t / seconds_per_beat
		var step: int = int(beat * 2.0) % lead_pattern.size()
		var half_step_time: float = fposmod(beat * 2.0, 1.0)
		var quarter_step: int = int(beat) % bass_pattern.size()
		var quarter_time: float = fposmod(beat, 1.0)
		var bar: int = int(beat / 4.0) % chord_pattern.size()

		var lead_note: int = lead_pattern[step]
		var bass_note: int = bass_pattern[quarter_step]
		var chord_notes: Array = chord_pattern[bar]

		var lead_gate: float = 1.0 if half_step_time < 0.82 else 0.0
		var bass_gate: float = 1.0 if quarter_time < 0.88 else 0.0
		var hat_gate: float = 1.0 if fposmod(beat * 4.0, 1.0) < 0.12 else 0.0

		var lead: float = _square_wave(_midi_to_hz(lead_note), t) * lead_gate * 0.18
		var bass: float = _triangle_wave(_midi_to_hz(bass_note), t) * bass_gate * 0.14
		var chord := 0.0
		for note in chord_notes:
			chord += _square_wave(_midi_to_hz(int(note)), t) * 0.05

		var kick_phase: float = fposmod(beat, 2.0)
		var kick: float = sin(TAU * (58.0 - 18.0 * kick_phase) * t) * exp(-8.0 * kick_phase) * 0.24
		var snare_phase: float = fposmod(beat + 1.0, 2.0)
		var snare_noise: float = 0.0
		if snare_phase < 0.32:
			snare_noise = sin(973.0 * t) * exp(-14.0 * snare_phase) * 0.08
		var hat: float = sin(6300.0 * t) * hat_gate * 0.025

		samples.append((lead + bass + chord + kick + snare_noise + hat) * 0.9)

	var loop_fade := int(SAMPLE_RATE * 0.012)
	for i in range(loop_fade):
		var blend: float = float(i) / float(loop_fade)
		var tail_index: int = samples.size() - loop_fade + i
		samples[tail_index] = samples[tail_index] * (1.0 - blend) + samples[i] * blend

	return _build_stream(samples)


static func _build_stream(samples: Array[float]) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)

	for i in range(samples.size()):
		var sample_int: int = clampi(int(samples[i] * 32767.0), -32767, 32767)
		if sample_int < 0:
			sample_int += 65536
		data[i * 2] = sample_int & 0xff
		data[i * 2 + 1] = (sample_int >> 8) & 0xff

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func _envelope(t: float, duration: float, attack: float, release: float) -> float:
	if t < attack:
		return t / max(attack, 0.000001)
	if t > duration - release:
		return max(0.0, (duration - t) / max(release, 0.000001))
	return 1.0


static func _square_wave(freq: float, t: float) -> float:
	return 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0


static func _triangle_wave(freq: float, t: float) -> float:
	return 2.0 * abs(2.0 * fposmod(freq * t, 1.0) - 1.0) - 1.0


static func _midi_to_hz(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)
