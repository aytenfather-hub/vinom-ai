"""Shared helpers for the Fruit Box SVG layouts.
All shapes/text are live vectors; the logo itself is the ORIGINAL raster artwork,
linked as a PNG (it has no vector source)."""
import os

C = dict(brown='#8A3D1F', cocoa='#602713', teal='#71BCA8', red='#C1232C', pink='#F39A99',
         yellow='#FCD82F', green='#5F973E', cream='#FDF8F3', oat='#F4EADF', ink='#2B1A12',
         mint='#E3F2EE', blush='#FDE9E6', orange='#F08A24', deep='#1E1410')

LOGO = '01-logo/fruitbox-logo-original-transparent.png'      # 648 x 522
LOGO_DARK = '01-logo/fruitbox-logo-dark-bg-version-transparent.png'  # 674 x 548
ICON = '02-app-icon/fruitbox-app-icon-rounded.svg'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def rel(target, out_dir):
    return os.path.relpath(os.path.join(ROOT, target), os.path.join(ROOT, out_dir)).replace(os.sep, '/')


class Doc:
    def __init__(self, w, h, out_dir, bg=None, title=''):
        self.w, self.h, self.out_dir, self.parts = w, h, out_dir, []
        self.title = title
        if bg:
            self.parts.append(f'<rect id="background" width="{w}" height="{h}" fill="{bg}"/>')

    def add(self, s):
        self.parts.append(s); return self

    def logo(self, cx, cy, w, dark=False, id_='logo'):
        """Place the original logo centred on (cx,cy) with width w (aspect kept)."""
        src, ar = (LOGO_DARK, 674 / 548) if dark else (LOGO, 648 / 522)
        h = w / ar
        return (f'<image id="{id_}" href="{rel(src, self.out_dir)}" x="{cx - w / 2:.1f}" y="{cy - h / 2:.1f}" '
                f'width="{w:.1f}" height="{h:.1f}" preserveAspectRatio="xMidYMid meet"/>')

    def icon(self, x, y, s):
        return f'<image href="{rel(ICON, self.out_dir)}" x="{x}" y="{y}" width="{s}" height="{s}"/>'

    def svg(self):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
                f'width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}">\n'
                f'<title>{self.title}</title>\n'
                f'<!-- Editable layout: vectors + live text (fonts: Cairo, Poppins in /fonts). '
                f'The Fruit Box logo is the original raster artwork linked as PNG. -->\n'
                f'<defs>{DEFS}</defs>\n' + '\n'.join(self.parts) + '\n</svg>\n')

    def save(self, name):
        d = os.path.join(ROOT, self.out_dir); os.makedirs(d, exist_ok=True)
        p = os.path.join(d, name)
        open(p, 'w', encoding='utf-8').write(self.svg())
        return os.path.join(self.out_dir, name)


DEFS = f'''
<filter id="shadow" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#3B1A0C" flood-opacity=".22"/></filter>
<filter id="shadowS" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="6" stdDeviation="8" flood-color="#3B1A0C" flood-opacity=".22"/></filter>
<filter id="blur40"><feGaussianBlur stdDeviation="40"/></filter>
<filter id="blur12"><feGaussianBlur stdDeviation="12"/></filter>
<radialGradient id="floor" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#3B1A0C" stop-opacity=".35"/><stop offset="1" stop-color="#3B1A0C" stop-opacity="0"/></radialGradient>
<linearGradient id="smoothie" x1="0" x2="1"><stop offset="0" stop-color="#F7B3AE"/><stop offset=".55" stop-color="#F08C8C"/><stop offset="1" stop-color="#D9606A"/></linearGradient>
<linearGradient id="clear" x1="0" x2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".55"/><stop offset=".3" stop-color="#ffffff" stop-opacity=".12"/><stop offset=".8" stop-color="#ffffff" stop-opacity=".05"/><stop offset="1" stop-color="#ffffff" stop-opacity=".4"/></linearGradient>
<linearGradient id="paper" x1="0" x2="1"><stop offset="0" stop-color="#E9DDCD"/><stop offset=".25" stop-color="#FDF8F3"/><stop offset=".7" stop-color="#F6EEE3"/><stop offset="1" stop-color="#DCCBB6"/></linearGradient>
<linearGradient id="kraft" x1="0" x2="1"><stop offset="0" stop-color="#E6D6C1"/><stop offset=".5" stop-color="#F4EADF"/><stop offset="1" stop-color="#E0CDB5"/></linearGradient>
<linearGradient id="cocoaG" x1="0" x2="1"><stop offset="0" stop-color="#4E1F0F"/><stop offset=".45" stop-color="#6E2E17"/><stop offset="1" stop-color="#4A1D0E"/></linearGradient>
<linearGradient id="tealG" x1="0" x2="1"><stop offset="0" stop-color="#5EAE99"/><stop offset=".5" stop-color="#7CC6B2"/><stop offset="1" stop-color="#5AA792"/></linearGradient>
<linearGradient id="glassWin" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#CFE9E2"/><stop offset=".5" stop-color="#A9D6CA"/><stop offset="1" stop-color="#8CC3B5"/></linearGradient>
<linearGradient id="fadeDown" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".1"/></linearGradient>
<pattern id="dots" width="44" height="44" patternUnits="userSpaceOnUse"><circle cx="6" cy="6" r="3" fill="{C['teal']}" opacity=".35"/><circle cx="28" cy="28" r="3" fill="{C['pink']}" opacity=".45"/></pattern>
<pattern id="stripes" width="120" height="10" patternUnits="userSpaceOnUse"><rect width="60" height="10" fill="{C['teal']}"/><rect x="60" width="60" height="10" fill="{C['cream']}"/></pattern>
'''


def T(x, y, text, size, fill, weight=700, anchor='middle', font='Cairo', rtl=True, extra=''):
    """anchor: 'right' | 'left' | 'middle' (Arabic RTL aware)."""
    if rtl:
        a = {'right': 'start', 'left': 'end', 'middle': 'middle'}[anchor]
        d = ' direction="rtl"'
    else:
        a = {'right': 'end', 'left': 'start', 'middle': 'middle'}[anchor]
        d = ''
    fam = "Cairo, 'Noto Sans Arabic', sans-serif" if font == 'Cairo' else "Poppins, Arial, sans-serif"
    return (f'<text x="{x}" y="{y}" font-family="{fam}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill}" text-anchor="{a}"{d} {extra}>{text}</text>')


def strawberry(x, y, s=1.0, rot=0):
    return f'''<g transform="translate({x} {y}) rotate({rot}) scale({s})">
<path d="M0 -78 C70 -86 118 -52 112 6 C106 70 46 118 0 132 C-46 118 -106 70 -112 6 C-118 -52 -70 -86 0 -78 Z" fill="{C['red']}"/>
<path d="M-70 -40 C-60 -70 -20 -76 10 -72 C-30 -60 -56 -30 -64 10 Z" fill="#fff" opacity=".22"/>
<g fill="#FFE9A8"><ellipse cx="-50" cy="-10" rx="6" ry="9"/><ellipse cx="-12" cy="-22" rx="6" ry="9"/><ellipse cx="30" cy="-12" rx="6" ry="9"/><ellipse cx="66" cy="-4" rx="6" ry="9"/><ellipse cx="-66" cy="30" rx="6" ry="9"/><ellipse cx="-28" cy="22" rx="6" ry="9"/><ellipse cx="12" cy="26" rx="6" ry="9"/><ellipse cx="52" cy="32" rx="6" ry="9"/><ellipse cx="-36" cy="66" rx="6" ry="9"/><ellipse cx="4" cy="70" rx="6" ry="9"/><ellipse cx="36" cy="72" rx="6" ry="9"/></g>
<path d="M0 -70 L-70 -104 L-34 -64 L-96 -52 L-24 -48 Z M0 -70 L70 -104 L34 -64 L96 -52 L24 -48 Z M-10 -60 L0 -124 L10 -60 Z" fill="{C['green']}"/></g>'''


def orange_slice(x, y, r, col=None):
    col = col or C['orange']
    segs = ''.join(f'<path d="M0 0 L{r*0.8*__import__("math").cos(a):.1f} {r*0.8*__import__("math").sin(a):.1f}" stroke="#FFF4DA" stroke-width="{r*0.05:.1f}"/>'
                   for a in [i * 3.14159 / 4 for i in range(8)])
    return (f'<g transform="translate({x} {y})"><circle r="{r}" fill="{col}"/><circle r="{r*0.86}" fill="#FFF4DA"/>'
            f'<circle r="{r*0.8}" fill="{"#FFB44D" if col == C["orange"] else "#FFE680"}"/>{segs}<circle r="{r*0.08}" fill="#FFF4DA"/></g>')


def kiwi(x, y, r):
    import math
    seeds = ''.join(f'<ellipse cx="{r*0.42*math.cos(i*math.pi/7):.1f}" cy="{r*0.42*math.sin(i*math.pi/7):.1f}" rx="{r*0.04:.1f}" ry="{r*0.08:.1f}" transform="rotate({i*180/7+90:.0f} {r*0.42*math.cos(i*math.pi/7):.1f} {r*0.42*math.sin(i*math.pi/7):.1f})" fill="#2B1A12"/>' for i in range(14))
    return (f'<g transform="translate({x} {y})"><circle r="{r}" fill="#7A5A2E"/><circle r="{r*0.9}" fill="#8CC63F"/>'
            f'<circle r="{r*0.3}" fill="#E8F5C8"/>{seeds}</g>')


def leaf(x, y, s=1, rot=0, col=None):
    col = col or C['green']
    return (f'<g transform="translate({x} {y}) rotate({rot}) scale({s})"><path d="M0 0 C20 -40 70 -50 100 -30 C80 10 30 20 0 0 Z" fill="{col}"/>'
            f'<path d="M4 -2 C40 -20 70 -28 96 -30" stroke="#fff" stroke-opacity=".35" stroke-width="3" fill="none"/></g>')


def glass(x, y, s=1.0, c1='#F7B3AE', c2='#D9606A', topping='strawberry', ribbon=True, straw=True):
    """Smoothie glass illustration (same drawing language as the app icon).
    (x,y) = centre-bottom of the glass. Native size ~ 500 x 700."""
    gid = f'g{abs(hash((x, y, s, c1, c2, topping))) % 10**8}'
    top = ''
    if topping == 'strawberry':
        top = strawberry(-42, -610, 0.8)
    elif topping == 'orange':
        top = orange_slice(-50, -560, 80)
    elif topping == 'kiwi':
        top = kiwi(-50, -560, 78)
    elif topping == 'mint':
        top = leaf(-80, -540, 1.1, -20) + leaf(-40, -560, 0.9, -80)
    st = (f'<g transform="rotate(28 128 -486)"><rect x="108" y="-750" width="44" height="420" rx="22" fill="{C["red"]}"/>'
          f'<rect x="118" y="-734" width="10" height="380" rx="5" fill="#fff" opacity=".45"/></g>') if straw else ''
    rb = (f'<path d="M-336 -198 L-220 -210 L-220 -94 L-336 -82 L-298 -140 Z" fill="{C["cocoa"]}"/>'
          f'<path d="M336 -198 L220 -210 L220 -94 L336 -82 L298 -140 Z" fill="{C["cocoa"]}"/>'
          f'<path d="M-260 -228 Q0 -258 260 -228 L260 -112 Q0 -142 -260 -112 Z" fill="{C["brown"]}"/>'
          f'<path d="M-180 -178 Q0 -198 180 -178" stroke="{C["cream"]}" stroke-width="16" stroke-linecap="round" fill="none" opacity=".9"/>') if ribbon else ''
    return f'''<g transform="translate({x} {y}) scale({s})">
<defs><linearGradient id="{gid}" x1="0" x2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient></defs>
<ellipse cx="0" cy="6" rx="240" ry="26" fill="url(#floor)"/>
{st}
<path d="M-232 -456 H232 L190 -46 Q186 0 140 0 H-140 Q-186 0 -190 -46 Z" fill="url(#{gid})"/>
<path d="M-190 -426 L-160 -56" stroke="#fff" stroke-width="26" stroke-linecap="round" opacity=".5"/>
<path d="M-250 -444 C-262 -516 -194 -546 -152 -528 C-140 -584 -62 -602 -20 -564 C18 -610 106 -600 124 -542 C178 -560 258 -528 248 -444 Q248 -422 226 -422 H-226 Q-250 -422 -250 -444 Z" fill="{c1}"/>
<path d="M-250 -444 C-262 -516 -194 -546 -152 -528 C-140 -584 -62 -602 -20 -564" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="10" stroke-linecap="round"/>
{top}{rb}</g>'''
