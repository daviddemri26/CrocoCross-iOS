#!/usr/bin/env python3
"""Trim a decoded user GTA clip; decode first with afconvert -f WAVE -d LEI16.
Keep the original attack and both impacts, then shorten the echo with a
450 ms end fade. Keep 0.06–4.15 s: 4.09 seconds, no speed/pitch change.
"""
import array
import sys
import wave

with wave.open(sys.argv[1], 'rb') as source:
    rate, channels, width = source.getframerate(), source.getnchannels(), source.getsampwidth()
    assert width == 2 and rate == 44100 and channels == 2
    samples = array.array('h', source.readframes(source.getnframes()))
if sys.byteorder != 'little':
    samples.byteswap()
start, end, fade = round(0.06 * rate), round(4.15 * rate), round(0.45 * rate)
samples = samples[start * channels:end * channels]
frames = len(samples) // channels
for frame in range(frames - fade, frames):
    gain = (frames - 1 - frame) / (fade - 1)
    for channel in range(channels):
        i = frame * channels + channel
        samples[i] = round(samples[i] * gain)
if sys.byteorder != 'little':
    samples.byteswap()
with wave.open(sys.argv[2], 'wb') as output:
    output.setparams((channels, width, rate, frames, 'NONE', 'not compressed'))
    output.writeframes(samples.tobytes())
print(f'Trimmed death sound: {frames / rate:.3f} s')
