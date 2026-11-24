#!/usr/bin/env python3
"""Generates the short game sound cues into assets/sounds/ (stdlib only).

Usage: python tool/generate_sounds.py
"""
import math
import os
import struct
import wave

RATE = 44100
PEAK = 0.5  # about -6 dBFS
FADE = 0.004  # seconds of fade in and out, avoids clicks


def sine(phase):
    return math.sin(phase)


def triangle(phase):
    return 2.0 / math.pi * math.asin(math.sin(phase))


def tone(freq, duration, wave_fn=sine, attack=0.01, decay=6.0, gain=1.0):
    """One enveloped note: linear attack, exponential decay, edge fades."""
    n = int(RATE * duration)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) if attack > 0 else 1.0
        env *= math.exp(-decay * t / duration)
        edge = min(1.0, t / FADE, (duration - t) / FADE)
        out.append(gain * env * max(edge, 0.0) * wave_fn(2 * math.pi * freq * t))
    return out


def silence(duration):
    return [0.0] * int(RATE * duration)


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for track in tracks:
        for i, v in enumerate(track):
            out[i] += v
    return out


def sequence(notes, wave_fn=sine, step=0.1, length=0.2, decay=5.0):
    """Notes start `step` seconds apart, each lasting `length` seconds."""
    total = step * (len(notes) - 1) + length
    out = [0.0] * (int(RATE * total) + 2)
    for index, freq in enumerate(notes):
        note = tone(freq, length, wave_fn, decay=decay)
        start = int(RATE * step * index)
        for i, v in enumerate(note):
            out[start + i] += v
    return out


def write_wav(path, samples):
    peak = max(abs(s) for s in samples) or 1.0
    scale = PEAK / peak
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767))
                for s in samples
            )
        )


def main():
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sounds")
    os.makedirs(out_dir, exist_ok=True)

    sounds = {
        # Short woodblock-like blip.
        "tick": mix(
            tone(1500, 0.06, sine, attack=0.002, decay=9.0),
            tone(900, 0.06, triangle, attack=0.002, decay=9.0, gain=0.5),
        ),
        # Soft two-note rise.
        "phase_start": sequence([523.25, 659.25], triangle, step=0.09, length=0.22),
        # Quick confirming pip.
        "vote_cast": sequence([784.0, 1046.5], sine, step=0.06, length=0.14, decay=6.0),
        # Rising major arpeggio (C E G C).
        "imposter_caught": sequence(
            [523.25, 659.25, 783.99, 1046.5], triangle, step=0.11, length=0.36, decay=4.0
        ),
        # Sly descending minor (A C# -> A minor fall).
        "imposter_escaped": sequence(
            [880.0, 659.25, 523.25, 440.0], triangle, step=0.14, length=0.34, decay=4.5
        ),
        # Short fanfare: G G G C(high) with a held chord at the end.
        "game_won": mix(
            sequence([392.0, 392.0, 392.0], triangle, step=0.13, length=0.2, decay=3.0),
            silence(0.39) + tone(523.25, 0.5, triangle, decay=3.0),
            silence(0.39) + tone(659.25, 0.5, triangle, decay=3.0, gain=0.8),
            silence(0.39) + tone(783.99, 0.5, triangle, decay=3.0, gain=0.8),
        ),
        # Soft two-note fall.
        "game_lost": sequence([392.0, 293.66], sine, step=0.28, length=0.5, decay=4.0),
    }

    for name, samples in sounds.items():
        write_wav(os.path.join(out_dir, name + ".wav"), samples)
        print("wrote %s.wav (%d ms)" % (name, int(len(samples) * 1000 / RATE)))


if __name__ == "__main__":
    main()
