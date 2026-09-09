from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "release" / "google_play_assets"
OUT.mkdir(parents=True, exist_ok=True)


def font(size: int, bold: bool = False):
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/SFNSDisplay-Bold.otf" if bold else "/System/Library/Fonts/SFNSDisplay-Regular.otf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default()


def gradient(size, left, right, vertical=False):
    w, h = size
    im = Image.new("RGB", size)
    px = im.load()
    for y in range(h):
        for x in range(w):
            t = y / max(1, h - 1) if vertical else x / max(1, w - 1)
            px[x, y] = tuple(round(left[i] * (1 - t) + right[i] * t) for i in range(3))
    return im


def make_icon():
    src = Image.open(ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png").convert("RGBA")
    src.thumbnail((350, 350), Image.Resampling.LANCZOS)
    base = gradient((512, 512), (15, 23, 42), (37, 99, 235), vertical=True).convert("RGBA")
    # Google Play accepts a full 512px square. Keep the mark centered with generous safe area.
    rounded = Image.new("L", (512, 512), 0)
    ImageDraw.Draw(rounded).rounded_rectangle((0, 0, 511, 511), radius=116, fill=255)
    base.putalpha(rounded)
    x = (512 - src.width) // 2
    y = (512 - src.height) // 2
    base.alpha_composite(src, (x, y))
    # Add a subtle inner highlight so the icon remains legible on Play surfaces.
    overlay = Image.new("RGBA", (512, 512), (255, 255, 255, 0))
    ImageDraw.Draw(overlay).rounded_rectangle((3, 3, 508, 508), radius=113, outline=(255, 255, 255, 40), width=3)
    base.alpha_composite(overlay)
    base.convert("RGB").save(OUT / "bpay-icon-512.png", optimize=True)


def rounded_image(im, size, radius):
    im = im.resize(size, Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    im.putalpha(mask)
    return im


def make_feature():
    w, h = 1024, 500
    canvas = gradient((w, h), (10, 24, 61), (37, 99, 235))
    canvas = canvas.convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    # Soft decorative circles.
    deco = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dd = ImageDraw.Draw(deco)
    dd.ellipse((600, -300, 1080, 180), outline=(255, 255, 255, 38), width=2)
    dd.ellipse((665, -230, 1140, 250), outline=(255, 255, 255, 28), width=2)
    dd.ellipse((-180, 280, 210, 670), fill=(6, 182, 212, 35))
    canvas.alpha_composite(deco)

    # Brand mark and copy.
    icon = Image.open(OUT / "bpay-icon-512.png").convert("RGBA").resize((104, 104), Image.Resampling.LANCZOS)
    canvas.alpha_composite(icon, (65, 54))
    draw = ImageDraw.Draw(canvas)
    draw.text((192, 62), "BPay", fill="white", font=font(54, bold=True))
    draw.text((195, 127), "Moliyaviy platforma", fill=(219, 234, 254), font=font(24))
    draw.text((67, 226), "Your money.\nYour decisions.", fill="white", font=font(45, bold=True), spacing=6)
    draw.text((69, 354), "MyID verification • QR access • Smart finance", fill=(219, 234, 254), font=font(21))
    draw.rounded_rectangle((67, 407, 360, 454), radius=23, fill=(255, 255, 255), outline=(255, 255, 255), width=1)
    draw.text((91, 419), "Secure financial platform", fill=(30, 64, 175), font=font(17, bold=True))

    # Use the dashboard render as a product preview.
    dashboard = Image.open(OUT / "phone-02-dashboard.png").convert("RGBA")
    phone = rounded_image(dashboard, (240, 426), 26)
    shadow = Image.new("RGBA", (300, 470), (0, 0, 0, 0))
    shadow_box = Image.new("RGBA", (240, 426), (0, 0, 0, 95)).filter(ImageFilter.GaussianBlur(18))
    shadow.alpha_composite(shadow_box, (30, 28))
    canvas.alpha_composite(shadow, (716, 44))
    canvas.alpha_composite(phone, (746, 28))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((744, 26, 987, 456), radius=28, outline=(255, 255, 255, 110), width=2)

    canvas.convert("RGB").save(OUT / "bpay-feature-1024x500.png", optimize=True)


if __name__ == "__main__":
    make_icon()
    make_feature()
