#!/usr/bin/env python3
"""Render unlock.png — the Plymouth boot-screen wordmark for this theme.

Same treatment as the stock themes: Omarchy's own wordmark recolored to the
theme accent, transparent background, 800x188. Reading /usr/share/omarchy is
fine; we copy, never modify.
"""
import os
import tomllib
from pathlib import Path

from PIL import Image

THEME = Path(__file__).resolve().parent.parent
OUT = THEME / "unlock.png"
SRC = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "default/plymouth/logo.png"


def main():
    c = tomllib.loads((THEME / "colors.toml").read_text())
    accent = tuple(int(c["accent"].lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))

    logo = Image.open(SRC).convert("RGBA")
    a = logo.getchannel("A")
    solid = Image.new("RGBA", logo.size, accent + (0,))
    solid.putalpha(a)
    solid.save(OUT, "PNG", optimize=True)
    # pickers cache until the folder mtime changes
    os.utime(THEME, None)
    print(OUT)


if __name__ == "__main__":
    main()
