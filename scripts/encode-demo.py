"""Encode screenshot sequences into README GIFs. Requires Pillow."""
from pathlib import Path
import sys
from PIL import Image
frames = Path(sys.argv[1])
out = Path(__file__).resolve().parent.parent / 'docs' / 'images'
for kind in ('drag', 'import'):
    images = [Image.open(p).convert('RGB') for p in sorted(frames.glob(f'{kind}-*.png'))]
    if not images:
        raise ValueError(f'No frames for {kind}')
    durations = [40 if kind == 'drag' else 110] * len(images)
    durations[0] = 1000
    durations[-1] = 1800
    # Share a palette across every frame to prevent color flicker during movement.
    palette = images[0].quantize(colors=128)
    images = [im.quantize(palette=palette, dither=Image.Dither.NONE) for im in images]
    images[0].save(out / f'{kind}-demo.gif', save_all=True, append_images=images[1:], duration=durations, loop=0, optimize=True)
    print(f'{kind}: {len(images)} frames')
