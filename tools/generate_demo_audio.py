"""Genera tres piezas sintéticas originales de 24 segundos, sin muestras externas.

Ejecutar desde la raíz: python3 tools/generate_demo_audio.py
Solo usa la biblioteca estándar. Audio mono PCM, 22050 Hz, 16 bits.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
SECONDS = 24
OUTPUT = Path(__file__).resolve().parent.parent / 'assets' / 'audio'
OUTPUT.mkdir(parents=True, exist_ok=True)

def synthesize(name, chords, tempo, seed):
    rng = random.Random(seed)
    beat = 60 / tempo
    samples = bytearray()
    for index in range(RATE * SECONDS):
        t = index / RATE
        chord = chords[int(t / 6) % len(chords)]
        fade = min(1, t / 1.5, (SECONDS - t) / 2)
        pad = sum(math.sin(2 * math.pi * note * t) for note in chord) / 3
        bass = math.sin(2 * math.pi * chord[0] / 2 * t) * 0.23
        step = int(t / (beat / 2))
        note = chord[step % len(chord)] * 2
        elapsed = t % (beat / 2)
        bell = math.sin(2 * math.pi * note * elapsed) * math.exp(-elapsed * 8) * 0.21
        pulse = t % beat
        kick = math.sin(2 * math.pi * (48 * pulse + 9 * (1 - math.exp(-pulse * 18)))) * math.exp(-pulse * 16) * 0.19
        noise = rng.uniform(-1, 1) * math.exp(-elapsed * 80) * 0.025
        value = (pad * 0.2 + bass + bell + kick + noise) * fade * 0.65
        samples.extend(struct.pack('<h', int(max(-1, min(1, value)) * 32767)))
    with wave.open(str(OUTPUT / name), 'wb') as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(samples)
    print(f'{name}: {SECONDS}s de audio original')

synthesize('midnight.wav', [(130.81, 155.56, 196), (103.83, 130.81, 155.56), (116.54, 146.83, 174.61), (98, 123.47, 146.83)], 80, 1)
synthesize('rain.wav', [(146.83, 174.61, 220), (130.81, 164.81, 196), (116.54, 146.83, 174.61), (130.81, 164.81, 196)], 110, 2)
synthesize('glow.wav', [(130.81, 164.81, 196), (110, 130.81, 164.81), (87.31, 110, 130.81), (98, 123.47, 146.83)], 90, 3)
