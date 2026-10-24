#!/usr/bin/env python3
"""Draws the fastfetch logos (assets/fastfetch/*.txt) as shaded ASCII art.

Each logo is drawn as smooth shapes at high resolution, one colour region per
fastfetch colour ($1, $2, $3), then sampled down to characters. Denser
characters mean more ink and more light, in the style of distro logos such as
CachyOS's.

    python3 tools/make-logos.py            # writes assets/fastfetch/*.txt
    python3 tools/make-logos.py --preview  # also prints them in colour

Needs Pillow and NumPy (only to regenerate, not to use ricescape).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 480, 480            # drawing canvas
COLS, ROWS = 40, 20        # output size in characters (cells are ~1:2)
RAMP = " .:-=+*#%"         # light to dense
EDGE_RAMP = " .:-"         # used where a cell is only partly covered

OUT = Path(__file__).resolve().parent.parent / "assets" / "fastfetch"


def canvas():
    return Image.new("L", (W, H), 0)


def penguin():
    """OSRS-style penguin head in profile: dark hood, white face, orange beak.
    Returns (layers, holes): holes are cut out of everything (left blank)."""
    hood, face, beak, holes = canvas(), canvas(), canvas(), canvas()

    d = ImageDraw.Draw(hood)
    d.ellipse((30, 30, 400, 420), fill=255)
    d.ellipse((60, 230, 380, 470), fill=255)          # rounded chin

    d = ImageDraw.Draw(face)
    d.ellipse((200, 95, 410, 450), fill=255)
    face = Image.fromarray(np.minimum(np.array(face), np.array(hood)))

    d = ImageDraw.Draw(beak)
    d.polygon([(345, 200), (478, 262), (345, 325)], fill=255)

    d = ImageDraw.Draw(holes)
    d.ellipse((262, 165, 318, 230), fill=255)         # eye

    return [hood, face, beak], holes


def helm():
    """Ironman great helm, front on: dome, crest, T-shaped visor, rim band."""
    metal, band, holes = canvas(), canvas(), canvas()

    d = ImageDraw.Draw(metal)
    d.ellipse((50, 10, 430, 390), fill=255)                       # dome
    d.rectangle((50, 200, 430, 410), fill=255)                    # sides
    d.polygon([(50, 410), (430, 410), (395, 468), (85, 468)], fill=255)

    d = ImageDraw.Draw(band)
    d.rectangle((50, 175, 430, 205), fill=255)                    # brow band
    d.rectangle((222, 12, 258, 175), fill=255)                    # crest ridge
    d.rectangle((50, 440, 430, 470), fill=255)                    # bottom rim
    band = Image.fromarray(np.minimum(np.array(band), np.array(metal)))

    d = ImageDraw.Draw(holes)
    d.rounded_rectangle((95, 225, 385, 268), radius=12, fill=255)  # eye slit
    d.rounded_rectangle((212, 225, 268, 420), radius=12, fill=255) # nose/mouth slit

    return [metal, band], holes


def render(drawing):
    """drawing: ([mask for $1, mask for $2, ...], holes). Later layers sit on top."""
    layers, holes = drawing
    hole = np.array(holes, dtype=np.float32) / 255
    masks = [np.array(m, dtype=np.float32) / 255 * (1 - hole) for m in layers]
    # What each layer shows once the layers above it are drawn.
    visible = []
    above = np.zeros_like(masks[0])
    for m in reversed(masks):
        visible.insert(0, np.clip(m - above, 0, 1))
        above = np.clip(above + m, 0, 1)
    union = above

    # Light from the top left, falling off towards the edges.
    inner = np.array(Image.fromarray((union * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(26)),
                     dtype=np.float32) / 255
    yy, xx = np.mgrid[0:H, 0:W]
    light = 1.1 - 0.5 * (yy / H) - 0.2 * (xx / W)
    shade = np.clip(inner * light, 0, 1)

    cw, ch = W / COLS, H / ROWS
    lines = []
    for r in range(ROWS):
        out, cur = "", None
        for c in range(COLS):
            y0, y1 = int(r * ch), int((r + 1) * ch)
            x0, x1 = int(c * cw), int((c + 1) * cw)
            cover = union[y0:y1, x0:x1].mean()
            if cover < 0.15:
                out += " "
                continue
            region = int(np.argmax([v[y0:y1, x0:x1].mean() for v in visible]))
            level = shade[y0:y1, x0:x1].mean()
            if cover < 0.7:
                char = EDGE_RAMP[min(len(EDGE_RAMP) - 1, 1 + int(cover * (len(EDGE_RAMP) - 1)))]
            else:
                char = RAMP[min(len(RAMP) - 1, 2 + int(level * (len(RAMP) - 2)))]
            if region != cur:
                out += f"${region + 1}"
                cur = region
            out += char
        lines.append(out.rstrip())
    while lines and not lines[-1].strip():
        lines.pop()
    while lines and not lines[0].strip():
        lines.pop(0)
    return "\n".join(lines) + "\n"


def preview(text, colours):
    import re
    for line in text.splitlines():
        print(re.sub(r"\$(\d)", lambda m: f"\x1b[38;2;{colours[int(m.group(1)) - 1]}m", line) + "\x1b[0m")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    logos = {
        "penguin": (penguin(), ["110;110;110", "240;240;240", "240;138;28"]),
        "helm": (helm(), ["154;154;154", "90;90;90"]),
    }
    for name, (layers, colours) in logos.items():
        text = render(layers)
        (OUT / f"{name}.txt").write_text(text)
        if "--preview" in sys.argv:
            print(name)
            preview(text, colours)


if __name__ == "__main__":
    main()
