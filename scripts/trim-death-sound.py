#!/usr/bin/env python3
"""Trim a decoded user GTA clip; decode first with afconvert -f WAVE -d LEI16.
Measured 10 ms leading windows are silent until 60 ms; trailing 100 ms
windows stay below -40 dBFS RMS after 6.1 s. Preserve the audible echo,
with 150 ms fade to silence at 6.15 s. No speed or pitch changes.
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
start, end, fade = round(0.06 * rate), round(6.15 * rate), round(0.15 * rate)
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
