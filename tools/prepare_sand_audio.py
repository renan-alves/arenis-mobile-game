"""Prepare fine sand in glass from CC0 recordings; FFmpeg is authoring-only."""
import argparse
import hashlib
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = {
    'hourglass-625655.mp3': '2d3c5cd4c1c40378bd7fa94ae6dd168f48a058c35dc9e47fa0a000b0f6bd31e8',
    'sand-on-glass-199361.mp3': '9cf74a6ac1ebfa3e9cbf85baffc6c92bc75031a661161f1e07e41cd1b534196b',
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', default='ffmpeg')
    args = parser.parse_args()
    for filename, expected in SOURCES.items():
        source = ROOT/'tools/audio_sources'/filename
        if hashlib.sha256(source.read_bytes()).hexdigest() != expected:
            raise ValueError('Unexpected source recording: ' + filename)
    output = ROOT/'assets/audio/sand.wav'
    folder = ROOT/'tools/audio_sources'
    # Hourglass grains are the body; glass contact is a quiet, filtered secondary layer.
    filters = ('[0:a]aformat=channel_layouts=mono,highpass=f=300,lowpass=f=8500,volume=0.8[grains];'
               '[1:a]aformat=channel_layouts=mono,highpass=f=1500,lowpass=f=6500,volume=0.05[glass];'
               '[grains][glass]amix=inputs=2:normalize=0,'
               'afade=t=in:st=0:d=0.12,afade=t=out:st=1.85:d=0.25[out]')
    subprocess.run([args.ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
                    '-ss', '7', '-t', '2.1', '-i', str(folder/'hourglass-625655.mp3'),
                    '-ss', '6.6', '-t', '2.1', '-i', str(folder/'sand-on-glass-199361.mp3'),
                    '-filter_complex', filters, '-map', '[out]', '-ac', '1', '-ar', '22050',
                    '-c:a', 'pcm_s16le', '-map_metadata', '-1', str(output)], check=True)
    print(f'Prepared fine sand in glass: {output}')

if __name__ == '__main__':
    main()
