"""Logo lockups + applications part A (cups, box, bag, stickers, uniform)."""
import json
from lib import Doc, C, T, strawberry, orange_slice, kiwi, leaf, glass

jobs = []


def done(doc, name, scale=2):
    p = doc.save(name)
    jobs.append({'src': p, 'out': p.replace('.svg', '.png'), 'w': doc.w, 'h': doc.h, 'scale': scale})


TAG = 'فاكهتك على مزاجك'

# ---------------------------------------------------------------- logo: horizontal lockup
for dark in (False, True):
    d = Doc(1800, 640, '01-logo', None if not dark else C['cocoa'], 'Fruit Box horizontal lockup')
    txt = C['cream'] if dark else C['cocoa']
    d.add(d.logo(1450, 320, 640, dark=dark))
    d.add(f'<rect x="1080" y="170" width="6" height="300" rx="3" fill="{C["teal"]}"/>')
    d.add(T(1020, 318, 'فروت بوكس', 150, txt, 900, 'right'))
    d.add(T(1020, 420, TAG, 70, C['teal'] if dark else C['red'], 700, 'right'))
    d.add(T(1020, 486, 'عصائر • سموذي • فواكه طازجة', 38, txt, 600, 'right', extra='opacity=".75"'))
    done(d, f'fruitbox-logo-horizontal-{"dark" if dark else "light"}.svg', 2 if not dark else 2)
    if not dark:
        jobs[-1]['transparent'] = True

# ---------------------------------------------------------------- logo: avatar / profile picture
d = Doc(1080, 1080, '01-logo', None, 'Fruit Box profile avatar')
d.add(f'<circle cx="540" cy="540" r="540" fill="{C["cream"]}"/>')
d.add(f'<circle cx="540" cy="540" r="518" fill="none" stroke="{C["teal"]}" stroke-width="10" opacity=".55"/>')
d.add(d.logo(540, 552, 830))
done(d, 'fruitbox-logo-profile-avatar-1080.svg', 1)
jobs[-1]['transparent'] = True

# ---------------------------------------------------------------- 01 cups
d = Doc(1800, 1300, '03-applications/01-juice-cups', C['oat'], 'Fruit Box juice cups')
d.add(f'<circle cx="900" cy="560" r="520" fill="{C["mint"]}"/>')
d.add(f'<rect y="1010" width="1800" height="290" fill="#E9DCCB"/>')
# A: clear PET cup with pink smoothie + dome lid
def pet_cup(cx, base, s):
    g = f'<g transform="translate({cx} {base}) scale({s})">'
    g += '<ellipse cx="0" cy="8" rx="230" ry="30" fill="url(#floor)"/>'
    g += (f'<g transform="rotate(14 0 -700)"><rect x="-18" y="-1040" width="36" height="420" rx="18" fill="{C["red"]}"/>'
          '<rect x="-10" y="-1024" width="9" height="380" rx="4" fill="#fff" opacity=".45"/></g>')
    g += '<path d="M-220 -640 H220 L176 -30 Q172 0 140 0 H-140 Q-172 0 -176 -30 Z" fill="url(#smoothie)"/>'
    g += '<path d="M-220 -640 H220 L214 -560 C120 -600 -60 -520 -214 -570 Z" fill="#FFD3CE" opacity=".8"/>'
    g += '<path d="M-220 -640 H220 L176 -30 Q172 0 140 0 H-140 Q-172 0 -176 -30 Z" fill="url(#clear)"/>'
    g += '<path d="M-236 -640 Q0 -900 236 -640 Z" fill="#ffffff" opacity=".35"/><path d="M-236 -640 Q0 -900 236 -640" fill="none" stroke="#fff" stroke-width="6" opacity=".8"/>'
    g += '<rect x="-246" y="-656" width="492" height="26" rx="13" fill="#fff" opacity=".85"/>'
    g += '<path d="M-180 -600 L-146 -60" stroke="#fff" stroke-width="20" stroke-linecap="round" opacity=".55"/>'
    g += '</g>'
    return g
d.add(pet_cup(470, 1080, 1.0))
d.add(f'<g filter="url(#shadowS)"><ellipse cx="470" cy="760" rx="150" ry="150" fill="{C["cream"]}"/></g>')
d.add(d.logo(470, 764, 270))
# B: paper cup cream with teal band
def paper_cup(cx, base, s, body, band, logo_dark=False):
    g = f'<g transform="translate({cx} {base}) scale({s})">'
    g += '<ellipse cx="0" cy="8" rx="220" ry="30" fill="url(#floor)"/>'
    g += f'<path d="M-200 -700 H200 L160 -20 Q158 0 136 0 H-136 Q-158 0 -160 -20 Z" fill="{body}"/>'
    g += f'<path d="M-176 -290 H176 L160 -20 Q158 0 136 0 H-136 Q-158 0 -160 -20 Z" fill="{band}"/>'
    g += f'<path d="M-178 -290 Q0 -330 178 -290 L176 -262 Q0 -302 -176 -262 Z" fill="{C["brown"]}"/>'
    g += '<path d="M-200 -700 H200 L160 -20 Q158 0 136 0 H-136 Q-158 0 -160 -20 Z" fill="url(#fadeDown)"/>'
    g += '<path d="M-200 -700 L-160 -20 L-120 -20 L-156 -700 Z" fill="#fff" opacity=".18"/><path d="M200 -700 L160 -20 L120 -20 L150 -700 Z" fill="#000" opacity=".08"/>'
    g += f'<rect x="-216" y="-744" width="432" height="56" rx="18" fill="{C["cocoa"]}"/><rect x="-196" y="-770" width="392" height="34" rx="14" fill="{C["brown"]}"/>'
    g += '</g>'
    return g
d.add(paper_cup(1030, 1080, 0.95, C['cream'], C['teal']))
d.add(d.logo(1030, 650, 330))
d.add(T(1030, 930, TAG, 34, C['cream'], 800))
d.add(paper_cup(1440, 1080, 0.72, C['cocoa'], C['pink']))
d.add(d.logo(1440, 730, 240, dark=True))
d.add(T(1440, 920, 'Fruit Box', 26, C['cocoa'], 700, font='Poppins', rtl=False))
d.add(strawberry(220, 1080, 0.45, -20) + strawberry(1650, 1110, 0.4, 25) + orange_slice(1650, 990, 55) + leaf(150, 1020, 0.9, -30))
done(d, 'fruitbox-juice-cups.svg')

# ---------------------------------------------------------------- 02 fruit box package (isometric) + bottle
d = Doc(1800, 1300, '03-applications/02-fruit-box-package', C['mint'], 'Fruit Box package')
d.add(f'<circle cx="1500" cy="200" r="380" fill="#fff" opacity=".45"/><rect y="1040" width="1800" height="260" fill="#CFE7E0"/>')
L, D, H = 620, 400, 400
ox, oy = 300, 520
u = (0.866, 0.5); v = (0.866, -0.5)
d.add(f'<ellipse cx="{ox + (L*u[0]+D*v[0])/2:.0f}" cy="{oy + H + 180}" rx="560" ry="80" fill="url(#floor)"/>')
# left (front) face
d.add(f'<g transform="translate({ox} {oy}) matrix({u[0]} {u[1]} 0 1 0 0)">'
      f'<rect width="{L}" height="{H}" fill="url(#kraft)"/><rect width="{L}" height="{H}" fill="#000" opacity=".03"/>'
      f'<rect y="{H-70}" width="{L}" height="70" fill="{C["teal"]}"/>'
      f'<image href="../../01-logo/fruitbox-logo-original-transparent.png" x="150" y="40" width="320" height="258"/>'
      + T(L/2, H-24, 'بوكس فواكه طازجة • يُحضّر يومياً', 30, C['cream'], 800) + '</g>')
# right face
d.add(f'<g transform="translate({ox + L*u[0]:.1f} {oy + L*u[1]:.1f}) matrix({v[0]} {v[1]} 0 1 0 0)">'
      f'<rect width="{D}" height="{H}" fill="#E3D2BD"/><rect width="{D}" height="{H}" fill="#000" opacity=".07"/>'
      f'<rect y="{H-70}" width="{D}" height="70" fill="#5EA491"/>'
      + T(D/2, 120, TAG, 44, C['cocoa'], 900) + T(D/2, 180, 'فواكه موسمية مختارة بعناية', 26, C['brown'], 600)
      + T(D/2, 222, 'حفظ مبرّد • ٠–٤ °م', 24, C['brown'], 600)
      + strawberry(120, 300, 0.33) + orange_slice(200, 300, 38) + kiwi(280, 300, 36) + '</g>')
# top face
d.add(f'<g transform="translate({ox} {oy}) matrix({u[0]} {u[1]} {v[0]} {v[1]} 0 0)">'
      f'<rect width="{L}" height="{D}" fill="#F7EFE4"/><rect width="{L}" height="{D}" fill="url(#dots)" opacity=".7"/>'
      f'<rect x="{L/2-60}" width="120" height="{D}" fill="{C["brown"]}"/><rect x="{L/2-60}" width="10" height="{D}" fill="{C["cocoa"]}"/><rect x="{L/2+50}" width="10" height="{D}" fill="{C["cocoa"]}"/>'
      f'<circle cx="{L/2}" cy="{D/2}" r="92" fill="{C["cream"]}" stroke="{C["teal"]}" stroke-width="10"/>'
      f'<image href="../../01-logo/fruitbox-logo-original-transparent.png" x="{L/2-72}" y="{D/2-58}" width="144" height="116"/></g>')
# bottle
bx, by = 1450, 1120
d.add(f'<ellipse cx="{bx}" cy="{by+6}" rx="170" ry="26" fill="url(#floor)"/>')
d.add(f'<path d="M{bx-120} {by} Q{bx-140} {by} {bx-140} {by-30} V{by-520} Q{bx-140} {by-600} {bx-60} {by-640} V{by-700} H{bx+60} V{by-640} Q{bx+140} {by-600} {bx+140} {by-520} V{by-30} Q{bx+140} {by} {bx+120} {by} Z" fill="#F4A340"/>')
d.add(f'<path d="M{bx-140} {by-520} Q{bx-140} {by-600} {bx-60} {by-640} V{by-700} H{bx+60} V{by-640} Q{bx+140} {by-600} {bx+140} {by-520} V{by-30} Q{bx+140} {by} {bx+120} {by} H{bx-120} Q{bx-140} {by} {bx-140} {by-30} Z" fill="url(#clear)"/>')
d.add(f'<rect x="{bx-74}" y="{by-760}" width="148" height="80" rx="14" fill="{C["cocoa"]}"/><rect x="{bx-74}" y="{by-740}" width="148" height="8" fill="{C["brown"]}"/>')
d.add(f'<rect x="{bx-140}" y="{by-470}" width="280" height="330" fill="{C["cream"]}"/><rect x="{bx-140}" y="{by-190}" width="280" height="50" fill="{C["teal"]}"/>')
d.add(d.logo(bx, by-370, 230) + T(bx, by-156, 'برتقال طازج ١٠٠٪', 26, C['cream'], 800) + T(bx, by-206, '٣٣٠ مل', 22, C['brown'], 700))
d.add(f'<path d="M{bx-110} {by-560} L{bx-104} {by-60}" stroke="#fff" stroke-width="16" stroke-linecap="round" opacity=".45"/>')
d.add(strawberry(260, 1120, 0.5, -15) + leaf(1080, 1110, 1.1, -10) + orange_slice(1180, 1150, 62))
done(d, 'fruitbox-package-box-and-bottle.svg')

# ---------------------------------------------------------------- 03 delivery bag
d = Doc(1800, 1300, '03-applications/03-delivery-bag', C['blush'], 'Fruit Box delivery bags')
d.add(f'<circle cx="300" cy="260" r="300" fill="#fff" opacity=".5"/><rect y="1090" width="1800" height="210" fill="#F4D6CF"/>')
def bag(x, base, w, h, body, band, dark_logo, side):
    g = f'<ellipse cx="{x+w/2+30}" cy="{base+6}" rx="{w*0.65}" ry="34" fill="url(#floor)"/>'
    g += f'<path d="M{x+w*0.25} {base-h} C{x+w*0.25} {base-h-w*0.55} {x+w*0.75} {base-h-w*0.55} {x+w*0.75} {base-h}" fill="none" stroke="{C["cocoa"]}" stroke-width="16"/>'
    g += f'<path d="M{x+w} {base-h} L{x+w+w*0.22} {base-h+20} L{x+w+w*0.22} {base-10} L{x+w} {base} Z" fill="{side}"/>'
    g += f'<rect x="{x}" y="{base-h}" width="{w}" height="{h}" fill="{body}"/>'
    g += f'<rect x="{x}" y="{base-h*0.24}" width="{w}" height="{h*0.24}" fill="{band}"/>'
    g += f'<path d="M{x} {base-h*0.24} Q{x+w/2} {base-h*0.29} {x+w} {base-h*0.24} V{base-h*0.21} Q{x+w/2} {base-h*0.26} {x} {base-h*0.21} Z" fill="{C["brown"]}"/>'
    g += f'<rect x="{x}" y="{base-h}" width="{w}" height="{h}" fill="url(#fadeDown)"/><rect x="{x}" y="{base-h}" width="{w}" height="26" fill="#000" opacity=".06"/>'
    return g
d.add(bag(260, 1120, 640, 820, C['cream'], C['teal'], False, '#E2D5C4'))
d.add(d.logo(580, 620, 480))
d.add(T(580, 868, TAG, 52, C['cocoa'], 900) + T(580, 1062, 'اطلب من التطبيق • توصيل طازج لباب بيتك', 30, C['cream'], 700))
d.add(bag(1100, 1120, 440, 580, C['cocoa'], C['pink'], True, '#3E170A'))
d.add(d.logo(1320, 800, 340, dark=True))
d.add(T(1320, 1010, 'Fresh • Daily • Fruit Box', 26, C['cocoa'], 700, font='Poppins', rtl=False))
d.add(strawberry(1640, 1150, 0.45, 18) + leaf(140, 1080, 1.0, -40))
done(d, 'fruitbox-delivery-bags.svg')

# ---------------------------------------------------------------- 04 seal stickers
d = Doc(1800, 1300, '03-applications/04-seal-sticker', C['oat'], 'Fruit Box seal stickers')
d.add(f'<rect x="0" y="0" width="1800" height="1300" fill="url(#dots)" opacity=".5"/>')
cx, cy, R = 560, 620, 380
d.add(f'<g filter="url(#shadow)"><circle cx="{cx}" cy="{cy}" r="{R}" fill="{C["teal"]}"/></g>')
d.add(f'<circle cx="{cx}" cy="{cy}" r="{R-80}" fill="{C["cream"]}"/><circle cx="{cx}" cy="{cy}" r="{R-18}" fill="none" stroke="{C["cream"]}" stroke-width="4" stroke-dasharray="2 12" stroke-linecap="round"/>')
d.add(f'<path id="ring" d="M{cx-R+42} {cy} A{R-42} {R-42} 0 1 1 {cx+R-42} {cy} A{R-42} {R-42} 0 1 1 {cx-R+42} {cy}" fill="none"/>')
d.add(f'<text font-family="Poppins" font-weight="700" font-size="36" letter-spacing="6" fill="{C["cream"]}"><textPath href="#ring" startOffset="0">FRESH • SEALED WITH CARE • FRUIT BOX • FRESH • SEALED WITH CARE • FRUIT BOX •</textPath></text>')
d.add(d.logo(cx, cy-10, 480))
d.add(T(cx, cy+210, 'مختوم بعناية', 40, C['cocoa'], 900))
# seal strip
sx, sy = 1080, 360
d.add(f'<g filter="url(#shadowS)" transform="rotate(-6 {sx+300} {sy+90})"><rect x="{sx}" y="{sy}" width="600" height="180" rx="16" fill="{C["cocoa"]}"/>'
      f'<rect x="{sx+10}" y="{sy+10}" width="580" height="160" rx="10" fill="none" stroke="{C["cream"]}" stroke-width="2" stroke-dasharray="8 8" opacity=".6"/>'
      f'<image href="../../01-logo/fruitbox-logo-dark-bg-version-transparent.png" x="{sx+400}" y="{sy+14}" width="186" height="151"/>'
      + T(sx+380, sy+86, 'طازج ومختوم لأجلك', 44, C['cream'], 900, 'right') + T(sx+380, sy+136, 'لا تستخدمه إذا كان الختم مفتوحاً', 26, C['pink'], 600, 'right') + '</g>')
# small round
for i, (x, y, col, t1, t2) in enumerate([(1180, 860, C['red'], 'طازج', '١٠٠٪'), (1530, 900, C['yellow'], 'بدون', 'سكر مضاف')]):
    tc = C['cream'] if col == C['red'] else C['cocoa']
    d.add(f'<g filter="url(#shadowS)"><circle cx="{x}" cy="{y}" r="150" fill="{col}"/></g><circle cx="{x}" cy="{y}" r="132" fill="none" stroke="{tc}" stroke-width="3" opacity=".6"/>')
    d.add(T(x, y-6, t1, 54, tc, 900) + T(x, y+56, t2, 40, tc, 800))
done(d, 'fruitbox-seal-stickers.svg')

# ---------------------------------------------------------------- 05 staff uniform
d = Doc(1800, 1300, '03-applications/05-staff-uniform', '#EDE3D6', 'Fruit Box staff uniform')
d.add(f'<rect y="1120" width="1800" height="180" fill="#E0D2C0"/>')
# T-shirt
tx, ty = 520, 200
shirt = (f'M{tx-150} {ty} Q{tx} {ty+70} {tx+150} {ty} L{tx+360} {ty+90} L{tx+300} {ty+330} L{tx+230} {ty+300} L{tx+230} {ty+880} '
         f'Q{tx} {ty+910} {tx-230} {ty+880} L{tx-230} {ty+300} L{tx-300} {ty+330} L{tx-360} {ty+90} Z')
d.add(f'<g filter="url(#shadow)"><path d="{shirt}" fill="{C["cocoa"]}"/></g>')
d.add(f'<path d="M{tx-150} {ty} Q{tx} {ty+70} {tx+150} {ty} Q{tx} {ty+110} {tx-150} {ty} Z" fill="#3E170A"/>')
d.add(f'<path d="M{tx-150} {ty} Q{tx} {ty+74} {tx+150} {ty}" fill="none" stroke="{C["teal"]}" stroke-width="14"/>')
d.add(f'<path d="M{tx+230} {ty+300} L{tx+300} {ty+330}" stroke="{C["teal"]}" stroke-width="14"/><path d="M{tx-230} {ty+300} L{tx-300} {ty+330}" stroke="{C["teal"]}" stroke-width="14"/>')
d.add(f'<path d="M{tx-230} {ty+300} L{tx-230} {ty+880} Q{tx-200} {ty+885} {tx-170} {ty+888} L{tx-170} {ty+280} Z" fill="#000" opacity=".12"/>')
d.add(d.logo(tx+100, ty+290, 190, dark=True))
d.add(T(tx, ty+800, TAG, 34, C['pink'], 800))
# apron
ax, ay = 1270, 170
d.add(f'<path d="M{ax-120} {ay+20} Q{ax} {ay-120} {ax+120} {ay+20}" fill="none" stroke="{C["brown"]}" stroke-width="22"/>')
apron = f'M{ax-150} {ay} H{ax+150} L{ax+170} {ay+330} L{ax+290} {ay+360} L{ax+270} {ay+960} Q{ax} {ay+990} {ax-270} {ay+960} L{ax-290} {ay+360} L{ax-170} {ay+330} Z'
d.add(f'<g filter="url(#shadow)"><path d="{apron}" fill="{C["teal"]}"/></g>')
d.add(f'<path d="M{ax-290} {ay+360} L{ax-420} {ay+400}" stroke="{C["brown"]}" stroke-width="20" stroke-linecap="round"/><path d="M{ax+290} {ay+360} L{ax+420} {ay+400}" stroke="{C["brown"]}" stroke-width="20" stroke-linecap="round"/>')
d.add(f'<rect x="{ax-200}" y="{ay+640}" width="400" height="190" rx="18" fill="#5EA491"/><path d="M{ax} {ay+640} V{ay+830}" stroke="#4D8F7D" stroke-width="4"/>')
d.add(f'<circle cx="{ax}" cy="{ay+330}" r="190" fill="{C["cream"]}"/>')
d.add(d.logo(ax, ay+335, 320))
d.add(T(ax, ay+600, 'فريق Fruit Box', 36, C['cream'], 800))
# cap + name badge
d.add(f'<g transform="translate(1640 860)" filter="url(#shadowS)"><path d="M-110 0 A110 110 0 0 1 110 0 Z" fill="{C["cream"]}"/><path d="M-110 0 H160 Q170 26 130 30 H-110 Z" fill="{C["brown"]}"/>'
      f'<image href="../../02-app-icon/fruitbox-app-icon-rounded.svg" x="-40" y="-86" width="80" height="80"/></g>')
d.add(f'<g filter="url(#shadowS)"><rect x="1540" y="340" width="220" height="110" rx="16" fill="{C["cream"]}"/></g><rect x="1540" y="340" width="220" height="30" rx="16" fill="{C["teal"]}"/><rect x="1540" y="356" width="220" height="14" fill="{C["teal"]}"/>'
      + T(1650, 412, 'اسم الموظف', 28, C['cocoa'], 800) + T(1650, 440, 'فريق الخدمة', 18, C['brown'], 600))
done(d, 'fruitbox-staff-uniform.svg')

json.dump(jobs, open('_work/jobs_a.json', 'w'), indent=1)
print(len(jobs), 'svg written')
