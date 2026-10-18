"""Draws the H2Go launcher icon source images.

The mark is the app's mascot: the winking cartoon glass, half full of water,
on the blue gradient used by the splash screen. Shapes and colours follow
lib/widgets/water_glass.dart (same 200-unit design grid).

Usage (needs Pillow):
    python tool/make_icon.py assets/icon
    dart run flutter_launcher_icons

Writes icon.png (legacy, full icon), icon_background.png, icon_foreground.png
and icon_monochrome.png (adaptive icon layers), all 1024x1024.
"""
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 1024
SS = 4  # supersampling factor for smooth edges
N = S * SS

BLUE_TOP = (0x42, 0xA5, 0xF5)
BLUE_BOTTOM = (0x19, 0x76, 0xD2)
WATER_TOP = (0x42, 0xA5, 0xF5)
WATER_BOTTOM = (0x19, 0x76, 0xD2)
SKY = (0x90, 0xCA, 0xF9)
GLASS = (0xEA, 0xF5, 0xFF)
EDGE = (0xB9, 0xDD, 0xFB)
INK = (0x0B, 0x25, 0x45)
CORAL = (0xFF, 0x70, 0x43)
SHADOW = (0x0B, 0x25, 0x45)
WHITE = (255, 255, 255)

# Glass extent on the design grid (rim top to base), used to fit and centre it.
TOP, BOTTOM = 9, 230
LEVEL = 0.6  # how full the glass is


# ------------------------------------------------------------------ geometry

def quad(p0, p1, p2, steps=60):
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        yield (u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
               u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1])


def body(d):
    """Tapered tumbler outline shrunk by `d` units (see _GlassPainter._body)."""
    pts = [(12 + d, 20), (32 + d, 206 - d * 0.3)]
    pts += quad((32 + d, 206 - d * 0.3), (34.5 + d * 0.8, BOTTOM - d),
                (58 + d * 0.3, BOTTOM - d))
    pts += [(142 - d * 0.3, BOTTOM - d)]
    pts += quad((142 - d * 0.3, BOTTOM - d), (165.5 - d * 0.8, BOTTOM - d),
                (168 - d, 206 - d * 0.3))
    pts += [(188 - d, 20)]
    return pts


def densify(pts, closed, step=0.5):
    """Points every `step` units along the polyline, for round-brush strokes."""
    if closed:
        pts = pts + [pts[0]]
    out = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
        out += [(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n)
                for i in range(n)]
    return out + [pts[-1]]


class Canvas:
    """Maps design units to supersampled pixels."""

    def __init__(self, height_frac, cy_frac=0.5):
        self.k = N * height_frac / (BOTTOM - TOP)
        self.ox = N / 2 - 100 * self.k
        self.oy = N * cy_frac - (TOP + BOTTOM) / 2 * self.k

    def p(self, x, y):
        return (self.ox + x * self.k, self.oy + y * self.k)

    def pts(self, pts):
        return [self.p(x, y) for x, y in pts]

    def mask(self):
        return Image.new("L", (N, N), 0)

    def poly(self, pts):
        m = self.mask()
        ImageDraw.Draw(m).polygon(self.pts(pts), fill=255)
        return m

    def oval(self, cx, cy, w, h):
        m = self.mask()
        x0, y0 = self.p(cx - w / 2, cy - h / 2)
        x1, y1 = self.p(cx + w / 2, cy + h / 2)
        ImageDraw.Draw(m).ellipse((x0, y0, x1, y1), fill=255)
        return m

    def stroke(self, pts, width, closed=False):
        """Round-capped, round-joined stroke (PIL's wide-line joins are poor)."""
        m = self.mask()
        d = ImageDraw.Draw(m)
        r = width * self.k / 2
        for x, y in self.pts(densify(list(pts), closed)):
            d.ellipse((x - r, y - r, x + r, y + r), fill=255)
        return m

    def oval_ring(self, cx, cy, w, h, width):
        pts = [(cx + w / 2 * math.cos(a), cy + h / 2 * math.sin(a))
               for a in (2 * math.pi * i / 240 for i in range(240))]
        return self.stroke(pts, width, closed=True)

    def wave(self, phase):
        """Area under a one-cycle sine wave at the water level."""
        calm = 5
        base = BOTTOM + calm - (BOTTOM + calm - 34) * LEVEL
        pts = [(x, base + math.sin(x / 200 * 2 * math.pi + phase) * calm)
               for x in range(0, 201, 2)]
        return self.poly(pts + [(200, BOTTOM), (0, BOTTOM)])


# ------------------------------------------------------------------ painting

def solid(color, alpha=255):
    return Image.new("RGBA", (N, N), color + (alpha,))


def vertical_gradient(top, bottom, y0=0, y1=N):
    row = Image.new("RGB", (1, N))
    px = row.load()
    for y in range(N):
        t = min(max((y - y0) / max(y1 - y0, 1), 0), 1)
        px[0, y] = tuple(round(top[i] + (bottom[i] - top[i]) * t)
                         for i in range(3))
    return row.resize((N, N)).convert("RGBA")


def paint(base, fill, mask, alpha=1.0):
    """Composites `fill` (colour tuple or RGBA image) onto `base` via `mask`."""
    layer = solid(fill) if isinstance(fill, tuple) else fill.copy()
    if alpha < 1:
        mask = mask.point(lambda v: round(v * alpha))
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), mask))
    return Image.alpha_composite(base, layer)


def face_strokes(c):
    """Masks for the wink, the open eye (with its highlight) and the smile."""
    wink = c.stroke(quad((62, 128), (74, 114), (86, 128)), 6)
    smile = c.stroke(quad((82, 146), (101, 168), (120, 146)), 6)
    eye = c.oval(126, 123, 17, 21)
    shine = c.oval(129.5, 118, 7.2, 7.2)
    return wink, smile, eye, shine


def glass(c, base):
    outer = c.poly(body(0))
    inner = c.poly(body(8))
    _, y_bottom = c.p(0, BOTTOM)
    _, y_level = c.p(0, BOTTOM + 5 - (BOTTOM + 5 - 34) * LEVEL)

    # Soft drop shadow, then the floor shadow.
    shadow = outer.filter(ImageFilter.GaussianBlur(c.k * 6))
    shadow = ImageChops.offset(shadow, 0, round(c.k * 8))
    base = paint(base, SHADOW, shadow, 0.35)
    floor = c.oval(100, 236, 150, 12).filter(ImageFilter.GaussianBlur(c.k * 4))
    base = paint(base, SHADOW, floor, 0.3)

    base = paint(base, GLASS, outer)

    # Water: light back wave, gradient front wave, a few bubbles.
    base = paint(base, SKY, ImageChops.multiply(inner, c.wave(math.pi / 2)))
    front = ImageChops.multiply(inner, c.wave(0))
    base = paint(base, vertical_gradient(WATER_TOP, WATER_BOTTOM,
                                         round(y_level), round(y_bottom)),
                 front)
    for x, y, r in [(150, 196, 6), (138, 172, 3.5), (62, 204, 4)]:
        base = paint(base, WHITE,
                     ImageChops.multiply(front, c.oval(x, y, 2 * r, 2 * r)),
                     0.35)

    # Edge: pale blue outline under a white one, then the rim and shine.
    base = paint(base, EDGE, c.stroke(body(0), 9, closed=True))
    base = paint(base, WHITE, c.stroke(body(0), 6, closed=True))
    base = paint(base, WHITE, c.oval(100, 20, 176, 22), 0.55)
    base = paint(base, WHITE, c.oval_ring(100, 20, 176, 22, 5))
    base = paint(base, WHITE, c.stroke([(34, 52), (46, 168)], 9), 0.7)
    base = paint(base, WHITE, c.stroke([(48.5, 186), (49.5, 194)], 9), 0.7)

    # Face.
    wink, smile, eye, shine = face_strokes(c)
    base = paint(base, INK, wink)
    base = paint(base, INK, smile)
    base = paint(base, INK, eye)
    base = paint(base, WHITE, shine)
    base = paint(base, CORAL, c.oval(58, 146, 18, 10), 0.5)
    base = paint(base, CORAL, c.oval(142, 146, 18, 10), 0.5)
    return base


def background():
    """Splash-screen blue, lighter at the top."""
    return vertical_gradient(BLUE_TOP, BLUE_BOTTOM)


def monochrome(c):
    """White glass silhouette with the face and rim cut out (themed icons)."""
    m = ImageChops.lighter(c.poly(body(0)), c.oval(100, 20, 176, 22))
    wink, smile, eye, _ = face_strokes(c)
    for cut in (wink, smile, eye, c.oval_ring(100, 20, 150, 12, 5)):
        m = ImageChops.subtract(m, cut)
    out = solid(WHITE, 0)
    return paint(out, WHITE, m)


def down(img):
    return img.resize((S, S), Image.LANCZOS)


def main(out):
    os.makedirs(out, exist_ok=True)

    # Legacy icon: blue rounded square with a large glass.
    corner = Image.new("L", (N, N), 0)
    ImageDraw.Draw(corner).rounded_rectangle((0, 0, N - 1, N - 1),
                                             radius=N * 0.22, fill=255)
    legacy = glass(Canvas(0.66, 0.52), background())
    legacy.putalpha(corner)
    down(legacy).save(os.path.join(out, "icon.png"))

    # Adaptive layers: the system masks the background. flutter_launcher_icons
    # insets the foreground by 16% per side, and the safe zone is a 66dp
    # circle on the 108dp canvas, i.e. 90% of this image's width.
    down(background().convert("RGB")).save(
        os.path.join(out, "icon_background.png"))
    fg = Canvas(0.66, 0.51)
    down(glass(fg, solid(WHITE, 0))).save(
        os.path.join(out, "icon_foreground.png"))
    down(monochrome(fg)).save(os.path.join(out, "icon_monochrome.png"))


if __name__ == "__main__":
    main(sys.argv[1])
