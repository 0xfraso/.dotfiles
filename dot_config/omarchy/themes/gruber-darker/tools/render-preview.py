#!/usr/bin/env python3
"""Render preview.png for this Omarchy theme (2560x1440, the switcher card).

Staged flat card in the style of the stock Omarchy themes: background canvas,
faint shell bar widgets, a title block, a notification card, a dock, and a
terminal panel showing the live palette. Reads colors.toml so the preview
always matches the theme. Needs: python-pillow, JetBrainsMono Nerd Font.
"""
from pathlib import Path
import os
import tomllib

from PIL import Image, ImageDraw, ImageFont

THEME = Path(__file__).resolve().parent.parent
OUT = THEME / "preview.png"

W, H = 2560, 1440
S = 2  # supersample, downscaled with Lanczos for crisp edges
FONT_DIR = "/usr/share/fonts/TTF"


def font(size, bold=False):
    name = "JetBrainsMonoNerdFont-Bold.ttf" if bold else "JetBrainsMonoNerdFont-Regular.ttf"
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size * S)


def main():
    c = tomllib.loads((THEME / "colors.toml").read_text())
    col = {k: v for k, v in c.items() if isinstance(v, str)}

    img = Image.new("RGB", (W * S, H * S), col["background"])
    d = ImageDraw.Draw(img)

    def text(x, y, s, fill, f, anchor="la"):
        d.text((x * S, y * S), s, fill=fill, font=f, anchor=anchor)

    def rrect(x0, y0, x1, y1, r, fill, outline=None, width=0):
        d.rounded_rectangle(
            [x0 * S, y0 * S, x1 * S, y1 * S], radius=r * S,
            fill=fill, outline=outline, width=width * S,
        )

    def dot(cx, cy, r, fill):
        d.ellipse([(cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S], fill=fill)

    # ── shell bar (faint, on the canvas like the stock previews) ──────────
    bar = font(26)
    for i, active in enumerate((True, False, False)):
        dot(210 + i * 44, 52, 9 if active else 7,
            col["accent"] if active else col["muted"])
    text(2470, 40, "arch  ·  Fri 21:47", col["muted"], bar, anchor="ra")

    # ── title block ───────────────────────────────────────────────────────
    text(200, 220, "Gruber Darker", col["bright_foreground"], font(96, bold=True))
    d.rectangle([204 * S, 356 * S, 354 * S, 366 * S], fill=col["accent"])

    # ── notification card (left) ──────────────────────────────────────────
    rrect(200, 760, 780, 910, 20, col["lighter_background"])
    dot(246, 812, 10, col["accent"])
    text(272, 796, "Omarchy", col["foreground"], font(28, bold=True))
    text(246, 846, "Theme set: Gruber Darker", col["muted"], font(26))

    # ── dock (bottom center) ──────────────────────────────────────────────
    rrect(1070, 1300, 1490, 1390, 22, col["darker_background"])
    for i, fill in enumerate(("foreground", "blue", "green", "magenta", "accent")):
        dot(1146 + i * 67, 1345, 15, col[fill])

    # ── terminal panel (lower right) ──────────────────────────────────────
    rrect(1160, 620, 2480, 1380, 24, col["dark_background"],
          outline=col["lighter_background"], width=2)
    tx, ty, lh = 1216, 726, 64
    mono = font(32)
    small = font(24)

    text(tx, ty, "fraso@arch", col["accent"], font(32, bold=True))
    text(tx + 13 * 19, ty, " ~ omarchy theme current", col["muted"], mono)
    ty += lh
    text(tx, ty, "Gruber Darker", col["foreground"], font(40, bold=True))
    ty += int(lh * 1.75)
    text(tx, ty, "palette", col["muted"], small)
    ty += 48

    swatches = (
        ("red", "yellow", "green"),
        ("cyan", "blue", "magenta"),
    )
    for row in swatches:
        x = tx
        for name in row:
            d.rectangle([x * S, ty * S, (x + 34) * S, (ty + 34) * S], fill=col[name])
            text(x + 46, ty + 2, col[name].lstrip("#"), col[name], small)
            x += 380
        ty += 56
    ty += 64

    text(tx, ty, "$ ls -la", col["muted"], mono)
    ty += lh
    lx = tx
    for label, color in (("dotfiles/", "blue"), ("notes.md", "green"), ("omarchy.tar.gz", "brown")):
        text(lx, ty, label, col[color], mono)
        lx += (len(label) + 3) * 19
    ty += lh + 24

    text(tx, ty, "$", col["foreground"], mono)
    d.rectangle([(tx + 42) * S, ty * S, (tx + 62) * S, (ty + 34) * S], fill=col["accent"])

    # ── save ──────────────────────────────────────────────────────────────
    img = img.resize((W, H), Image.LANCZOS)
    img.save(OUT, "PNG", optimize=True)
    # the theme and background pickers cache thumbnails until the folder mtime
    # changes, which writing files does not do
    os.utime(THEME, None)
    print(OUT)


if __name__ == "__main__":
    main()
