#!/usr/bin/env python3
"""
Audio Synthesizer for Startup Simulator.
Generates clean, authentic 16-bit 44.1kHz PCM WAV audio assets for:
- Footsteps (wood parquet, stone cobblestone)
- UI (click, notification, success chime, cash register)
- Physical interactions (door latch, keyboard typing, room ambience)
"""

import os
import math
import struct
import random

SAMPLE_RATE = 44100

def write_wav(filename: str, samples: list, channels: int = 1):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    num_samples = len(samples) // channels
    byte_rate = SAMPLE_RATE * channels * 2
    block_align = channels * 2
    data_size = num_samples * channels * 2
    
    with open(filename, 'wb') as f:
        # RIFF header
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))
        f.write(b'WAVE')
        # fmt subchunk
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))
        f.write(struct.pack('<H', 1))  # PCM format
        f.write(struct.pack('<H', channels))
        f.write(struct.pack('<I', SAMPLE_RATE))
        f.write(struct.pack('<I', byte_rate))
        f.write(struct.pack('<H', block_align))
        f.write(struct.pack('<H', 16)) # 16-bit
        # data subchunk
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        for s in samples:
            val = max(-32767, min(32767, int(s * 32767)))
            f.write(struct.pack('<h', val))

def generate_footstep_wood(duration: float = 0.18):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        # Low thud + wood resonance
        env = math.exp(-t * 32.0)
        f1 = 90.0 * math.exp(-t * 20.0)
        f2 = 180.0
        click = (random.random() * 2.0 - 1.0) * math.exp(-t * 90.0) * 0.4
        thud = math.sin(2.0 * math.pi * f1 * t) * 0.6 + math.sin(2.0 * math.pi * f2 * t) * 0.3
        samples.append(env * (thud + click))
    return samples

def generate_footstep_stone(duration: float = 0.20):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        # Crisper strike + stone crunch
        env = math.exp(-t * 28.0)
        noise = (random.random() * 2.0 - 1.0) * 0.5 * math.exp(-t * 40.0)
        grit = math.sin(2.0 * math.pi * 320.0 * t) * 0.35 + math.sin(2.0 * math.pi * 120.0 * t) * 0.4
        samples.append(env * (grit + noise))
    return samples

def generate_ui_click(duration: float = 0.05):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 120.0)
        tone = math.sin(2.0 * math.pi * 1200.0 * t) * 0.7 + (random.random() * 2.0 - 1.0) * 0.2
        samples.append(env * tone)
    return samples

def generate_ui_notification(duration: float = 0.35):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 8.0)
        # Gentle dual-tone chime (F#5 to C#6)
        tone1 = math.sin(2.0 * math.pi * 740.0 * t) * 0.5
        tone2 = math.sin(2.0 * math.pi * 1108.0 * t) * 0.4 * (1.0 if t > 0.08 else 0.0)
        samples.append(env * (tone1 + tone2))
    return samples

def generate_ui_success(duration: float = 0.8):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 4.0)
        # Major chord arpeggio (C5 - E5 - G5 - C6)
        val = 0.0
        val += math.sin(2.0 * math.pi * 523.25 * t) * 0.3 * (1.0 if t >= 0.00 else 0.0)
        val += math.sin(2.0 * math.pi * 659.25 * t) * 0.35 * (1.0 if t >= 0.12 else 0.0)
        val += math.sin(2.0 * math.pi * 783.99 * t) * 0.35 * (1.0 if t >= 0.24 else 0.0)
        val += math.sin(2.0 * math.pi * 1046.50 * t) * 0.45 * (1.0 if t >= 0.36 else 0.0)
        samples.append(env * val)
    return samples

def generate_cash_register(duration: float = 0.65):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        # Mechanical latch click followed by bright bell chime
        env1 = math.exp(-t * 50.0)
        click = (random.random() * 2.0 - 1.0) * 0.6 * env1
        
        bell_t = t - 0.08
        if bell_t > 0:
            env2 = math.exp(-bell_t * 6.0)
            bell = (math.sin(2.0 * math.pi * 2093.0 * bell_t) * 0.5 + 
                    math.sin(2.0 * math.pi * 3135.0 * bell_t) * 0.3 +
                    math.sin(2.0 * math.pi * 4186.0 * bell_t) * 0.2) * env2
        else:
            bell = 0.0
        samples.append(click + bell)
    return samples

def generate_keyboard_typing(duration: float = 0.12):
    total = int(SAMPLE_RATE * duration)
    samples = []
    freq = random.uniform(800.0, 1400.0)
    for i in range(total):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 70.0)
        click = (random.random() * 2.0 - 1.0) * 0.4
        thump = math.sin(2.0 * math.pi * freq * t) * 0.5
        samples.append(env * (click + thump))
    return samples

def generate_door_open(duration: float = 0.5):
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        # Latch click + wooden creak
        latch = math.exp(-t * 60.0) * (random.random() * 2.0 - 1.0) * 0.5
        creak_env = (1.0 - math.exp(-t * 10.0)) * math.exp(-t * 5.0)
        creak_freq = 280.0 + math.sin(2.0 * math.pi * 15.0 * t) * 70.0
        creak = math.sin(2.0 * math.pi * creak_freq * t) * 0.4 * creak_env
        samples.append(latch + creak)
    return samples

def generate_ambient_studio(duration: float = 3.0):
    total = int(SAMPLE_RATE * duration)
    samples = []
    # Smooth quiet room tone with soft fan hum (60Hz + 120Hz harmonics)
    for i in range(total):
        t = i / SAMPLE_RATE
        hum = math.sin(2.0 * math.pi * 60.0 * t) * 0.03 + math.sin(2.0 * math.pi * 120.0 * t) * 0.015
        fan_noise = (random.random() * 2.0 - 1.0) * 0.008
        samples.append(hum + fan_noise)
    return samples

def main():
    out_dir = "/home/antigravity/startup-simulator/assets/audio"
    os.makedirs(out_dir, exist_ok=True)
    
    effects = {
        "footstep_wood.wav": generate_footstep_wood(),
        "footstep_stone.wav": generate_footstep_stone(),
        "ui_click.wav": generate_ui_click(),
        "ui_notification.wav": generate_ui_notification(),
        "ui_success.wav": generate_ui_success(),
        "cash_register.wav": generate_cash_register(),
        "keyboard_typing.wav": generate_keyboard_typing(),
        "door_open.wav": generate_door_open(),
        "ambient_studio.wav": generate_ambient_studio(),
    }
    
    for fname, data in effects.items():
        path = os.path.join(out_dir, fname)
        write_wav(path, data)
        print(f"Generated: {path} ({len(data)} samples)")

if __name__ == "__main__":
    main()
