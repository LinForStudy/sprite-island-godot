from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 22050
ROOT = Path(__file__).resolve().parents[2]
MUSIC_DIR = ROOT / "assets" / "audio" / "music"
SFX_DIR = ROOT / "assets" / "audio" / "sfx"

NOTE = {
    "C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61,
    "G3": 196.00, "A3": 220.00, "B3": 246.94,
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23,
    "G4": 392.00, "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99,
}


def envelope(t: float, duration: float, attack: float = 0.03, release: float = 0.12) -> float:
    if t < attack:
        return t / max(attack, 1e-6)
    if t > duration - release:
        return max(0.0, (duration - t) / max(release, 1e-6))
    return 1.0


def tone(freq: float, duration: float, volume: float = 0.3, kind: str = "warm") -> list[float]:
    total = max(1, int(duration * SAMPLE_RATE))
    values: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        phase = 2.0 * math.pi * freq * t
        if kind == "bell":
            sample = math.sin(phase) + 0.35 * math.sin(phase * 2.01) + 0.16 * math.sin(phase * 3.98)
        elif kind == "soft":
            sample = math.sin(phase) + 0.18 * math.sin(phase * 0.5)
        else:
            sample = math.sin(phase) + 0.22 * math.sin(phase * 2.0) + 0.08 * math.sin(phase * 3.0)
        values.append(sample * volume * envelope(t, duration))
    return values


def mix(target: list[float], source: list[float], offset_seconds: float) -> None:
    start = int(offset_seconds * SAMPLE_RATE)
    needed = start + len(source)
    if needed > len(target):
        target.extend([0.0] * (needed - len(target)))
    for index, sample in enumerate(source):
        target[start + index] += sample


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(1.0, max((abs(value) for value in samples), default=1.0))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for value in samples:
            pcm = int(max(-1.0, min(1.0, value / peak * 0.92)) * 32767)
            frames.extend(struct.pack("<h", pcm))
        output.writeframes(frames)


def make_music(path: Path, melody: list[str], bass: list[str], beat: float, repeats: int, airy: bool = False) -> None:
    duration = beat * len(melody) * repeats
    samples = [0.0] * int(duration * SAMPLE_RATE)
    for repeat in range(repeats):
        for index, note_name in enumerate(melody):
            at = (repeat * len(melody) + index) * beat
            mix(samples, tone(NOTE[note_name], beat * 0.94, 0.22, "bell" if airy else "warm"), at)
            if index % 2 == 0:
                bass_name = bass[(repeat * len(melody) + index) // 2 % len(bass)]
                mix(samples, tone(NOTE[bass_name], beat * 1.85, 0.15, "soft"), at)
    write_wav(path, samples)


def make_sfx() -> None:
    click = tone(620.0, 0.08, 0.35, "bell") + tone(820.0, 0.07, 0.26, "bell")
    write_wav(SFX_DIR / "ui_click.wav", click)

    rng = random.Random(20260728)
    footstep: list[float] = []
    for index in range(int(0.13 * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        noise = rng.uniform(-1.0, 1.0)
        footstep.append((0.7 * math.sin(2 * math.pi * 82 * t) + 0.3 * noise) * 0.35 * envelope(t, 0.13, 0.005, 0.1))
    write_wav(SFX_DIR / "footstep.wav", footstep)

    skill: list[float] = []
    duration = 0.42
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        freq = 260.0 + 760.0 * (t / duration) ** 1.4
        skill.append(math.sin(2 * math.pi * freq * t) * 0.42 * envelope(t, duration, 0.01, 0.14))
    write_wav(SFX_DIR / "skill.wav", skill)

    hurt: list[float] = []
    duration = 0.3
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        freq = 190.0 - 105.0 * (t / duration)
        hurt.append((math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(2 * math.pi * freq * 0.5 * t)) * 0.38 * envelope(t, duration, 0.005, 0.2))
    write_wav(SFX_DIR / "hurt.wav", hurt)

    capture: list[float] = []
    for index, note_name in enumerate(["C4", "E4", "G4", "C5"]):
        mix(capture, tone(NOTE[note_name], 0.24, 0.33, "bell"), index * 0.16)
    write_wav(SFX_DIR / "capture.wav", capture)


def main() -> None:
    make_music(
        MUSIC_DIR / "new_island_theme.wav",
        ["C4", "E4", "G4", "E4", "D4", "F4", "A4", "F4"],
        ["C3", "G3", "F3", "G3"], 0.5, 4,
    )
    make_music(
        MUSIC_DIR / "grove_theme.wav",
        ["D4", "F4", "A4", "F4", "E4", "G4", "B4", "G4"],
        ["D3", "A3", "G3", "A3"], 0.58, 4, airy=True,
    )
    make_music(
        MUSIC_DIR / "battle_theme.wav",
        ["A3", "C4", "E4", "G4", "E4", "C4", "B3", "E4"],
        ["A3", "E3", "G3", "E3"], 0.28, 6,
    )
    make_sfx()


if __name__ == "__main__":
    main()
