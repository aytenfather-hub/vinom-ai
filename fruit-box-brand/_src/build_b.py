"""Applications part B (storefront, business card, menu, Instagram, banners)."""
import json
from lib import Doc, C, T, strawberry, orange_slice, kiwi, leaf, glass

jobs = []
TAG = 'فاكهتك على مزاجك'


def done(doc, name, scale=2):
    p = doc.save(name)
    jobs.append({'src': p, 'out': p.replace('.svg', '.png'), 'w': doc.w, 'h': doc.h, 'scale': scale})


# ---------------------------------------------------------------- 06 storefront
d = Doc(1920, 1200, '03-applications/06-storefront', '#CFE7E0', 'Fruit Box storefront')
d.add('<rect width="1920" height="1200" fill="url(#fadeDown)"/>')
d.add(f'<rect x="160" y="120" width="1600" height="900" fill="{C["cream"]}"/><rect x="160" y="120" width="1600" height="900" fill="url(#dots)" opacity=".35"/>')
# sign box
d.add(f'<g filter="url(#shadow)"><rect x="240" y="150" width="1440" height="250" rx="18" fill="{C["cocoa"]}"/></g>')
d.add(f'<rect x="256" y="166" width="1408" height="218" rx="12" fill="none" stroke="{C["brown"]}" stroke-width="4"/>')
d.add(d.logo(1500, 275, 290, dark=True))
d.add(T(1320, 268, 'فروت بوكس', 110, C['cream'], 900, 'right'))
d.add(T(1320, 352, TAG + ' • عصائر وسموذي وفواكه طازجة', 42, C['teal'], 700, 'right'))
# awning (scalloped)
sc = ''.join(f'<path d="M{200+i*80} 450 q40 60 80 0 Z" fill="{C["teal"] if i % 2 == 0 else C["cream"]}"/>' for i in range(19))
d.add(f'<path d="M160 400 H1760 L1800 450 H120 Z" fill="url(#stripes)" transform=""/>')
d.add(''.join(f'<rect x="{120+i*84.2:.1f}" y="400" width="42.1" height="50" fill="{C["teal"]}"/>' for i in range(20)))
d.add(f'<rect x="120" y="400" width="1680" height="50" fill="{C["cream"]}" opacity="0"/>' + sc)
d.add('<rect x="120" y="400" width="1680" height="50" fill="url(#fadeDown)"/>')
# windows
for wx in (240, 1180):
    d.add(f'<rect x="{wx}" y="540" width="500" height="400" fill="{C["cocoa"]}"/><rect x="{wx+14}" y="554" width="472" height="372" fill="url(#glassWin)"/>')
    d.add(f'<path d="M{wx+40} 560 L{wx+200} 560 L{wx+60} 920 L{wx+14} 920 Z" fill="#fff" opacity=".25"/>')
d.add(glass(410, 900, 0.42, '#F7B3AE', '#D9606A', 'strawberry') + glass(560, 900, 0.36, '#FFE680', '#F4A340', 'orange'))
d.add(f'<rect x="1230" y="600" width="400" height="290" rx="14" fill="{C["cream"]}" opacity=".95"/>')
d.add(T(1430, 668, 'عرض اليوم', 48, C['red'], 900) + T(1430, 740, 'سموذي الفراولة', 40, C['cocoa'], 800) + T(1430, 800, 'الحبة الثانية بنصف السعر', 30, C['brown'], 700))
d.add(f'<rect x="1330" y="822" width="200" height="46" rx="23" fill="{C["teal"]}"/>' + T(1430, 855, 'اطلب الآن', 26, C['cream'], 800))
# door
d.add(f'<rect x="800" y="520" width="320" height="500" fill="{C["cocoa"]}"/><rect x="818" y="538" width="284" height="482" fill="url(#glassWin)"/>')
d.add(f'<path d="M830 545 L960 545 L850 1010 L818 1010 Z" fill="#fff" opacity=".22"/><rect x="1070" y="740" width="14" height="120" rx="7" fill="{C["brown"]}"/>')
d.add(f'<rect x="880" y="600" width="160" height="60" rx="10" fill="{C["red"]}"/>' + T(960, 642, 'مفتوح', 34, C['cream'], 900))
d.add(d.icon(900, 700, 120))
# planters + pavement
d.add('<rect y="1020" width="1920" height="180" fill="#BFA98F"/><rect y="1020" width="1920" height="14" fill="#A68E73"/>')
for px in (180, 1740):
    d.add(f'<circle cx="{px}" cy="900" r="80" fill="{C["green"]}"/><circle cx="{px-40}" cy="940" r="60" fill="#4E8233"/><circle cx="{px+45}" cy="945" r="58" fill="#6FA64B"/>'
          f'<path d="M{px-70} 960 H{px+70} L{px+54} 1060 H{px-54} Z" fill="{C["brown"]}"/>')
done(d, 'fruitbox-storefront.svg')

# ---------------------------------------------------------------- 07 business card (85 x 55 mm)
d = Doc(1800, 1200, '03-applications/07-business-card', C['mint'], 'Fruit Box business card')
d.add(f'<circle cx="1600" cy="1100" r="420" fill="#fff" opacity=".45"/>')
cw, ch = 850, 550
fx, fy = 140, 200
d.add(f'<g transform="rotate(-4 {fx+cw/2} {fy+ch/2})"><g filter="url(#shadow)"><rect x="{fx}" y="{fy}" width="{cw}" height="{ch}" rx="18" fill="{C["cream"]}"/></g>'
      f'<rect x="{fx}" y="{fy+ch-40}" width="{cw}" height="40" fill="{C["teal"]}"/><rect x="{fx}" y="{fy+ch-52}" width="{cw}" height="12" fill="{C["brown"]}"/>'
      + d.logo(fx+cw/2, fy+ch/2-26, 420) + '</g>')
bx, by = 820, 560
back = f'<g transform="rotate(5 {bx+cw/2} {by+ch/2})"><g filter="url(#shadow)"><rect x="{bx}" y="{by}" width="{cw}" height="{ch}" rx="18" fill="{C["cocoa"]}"/></g>'
back += f'<rect x="{bx}" y="{by}" width="{cw}" height="{ch}" rx="18" fill="url(#dots)" opacity=".25"/>'
back += d.logo(bx+170, by+150, 230, dark=True)
back += T(bx+cw-60, by+120, 'اسم الموظف', 54, C['cream'], 900, 'right')
back += T(bx+cw-60, by+172, 'المسمى الوظيفي', 30, C['teal'], 700, 'right')
back += f'<rect x="{bx+cw-360}" y="{by+210}" width="300" height="4" rx="2" fill="{C["pink"]}"/>'
rows = [('+000 00 000 0000', 'جوال'), ('name@fruitbox.example', 'بريد'), ('fruitbox.example', 'موقع'), ('العنوان: الحي، الشارع، المدينة', '')]
for i, (v, k) in enumerate(rows):
    y = by + 290 + i * 58
    back += f'<circle cx="{bx+cw-76}" cy="{y-12}" r="16" fill="{C["teal"]}"/>'
    if i < 3:
        back += T(bx+cw-110, y, v, 28, C['cream'], 600, 'right', font='Poppins', rtl=False)
    else:
        back += T(bx+cw-110, y, v, 28, C['cream'], 600, 'right')
back += T(bx+60, by+ch-50, TAG, 30, C['pink'], 800, 'left') + '</g>'
d.add(back)
d.add(T(1720, 110, 'بطاقة العمل • ٨٥ × ٥٥ مم', 30, C['cocoa'], 700, 'right', extra='opacity=".7"'))
done(d, 'fruitbox-business-card-front-back.svg')

# print-ready flat artboards (85x55 mm + 3 mm bleed, 1 px = 0.1 mm)
for side in ('front', 'back'):
    f = Doc(910, 610, '03-applications/07-business-card', None, f'Business card {side} 91x61mm incl. 3mm bleed')
    if side == 'front':
        f.add(f'<rect width="910" height="610" fill="{C["cream"]}"/><rect y="540" width="910" height="70" fill="{C["teal"]}"/><rect y="528" width="910" height="12" fill="{C["brown"]}"/>')
        f.add(f.logo(455, 280, 420))
    else:
        f.add(f'<rect width="910" height="610" fill="{C["cocoa"]}"/><rect width="910" height="610" fill="url(#dots)" opacity=".25"/>')
        f.add(f.logo(200, 180, 230, dark=True))
        f.add(T(850, 150, 'اسم الموظف', 54, C['cream'], 900, 'right') + T(850, 202, 'المسمى الوظيفي', 30, C['teal'], 700, 'right'))
        f.add(f'<rect x="550" y="240" width="300" height="4" rx="2" fill="{C["pink"]}"/>')
        for i, (v, k) in enumerate(rows):
            y = 320 + i * 58
            f.add(f'<circle cx="834" cy="{y-12}" r="16" fill="{C["teal"]}"/>')
            f.add(T(800, y, v, 28, C['cream'], 600, 'right', font='Poppins' if i < 3 else 'Cairo', rtl=(i == 3)))
        f.add(T(60, 560, TAG, 30, C['pink'], 800, 'left'))
    f.add('<rect x="30" y="30" width="850" height="550" fill="none" stroke="#00AEEF" stroke-width="1" stroke-dasharray="6 6" id="trim-guide-hide-before-print"/>')
    done(f, f'fruitbox-business-card-{side}-print-91x61mm-bleed.svg', 3)

# ---------------------------------------------------------------- 08 menu (A3 portrait ratio)
d = Doc(1240, 1754, '03-applications/08-product-menu', C['cream'], 'Fruit Box menu')
d.add(f'<rect width="1240" height="430" fill="{C["mint"]}"/><path d="M0 430 Q620 500 1240 430 V0 H0 Z" fill="{C["mint"]}"/>')
d.add(d.logo(620, 220, 400))
d.add(T(620, 470, 'قائمة المنتجات', 64, C['cocoa'], 900) + T(620, 520, TAG, 34, C['red'], 700))
sections = [
    ('عصائر طازجة', C['orange'], [('برتقال طازج', 'معصور عند الطلب', '١٢'), ('فراولة', 'فراولة طازجة وحليب', '١٤'), ('مانجو', 'مانجو ناضجة ١٠٠٪', '١٥'), ('ليمون بالنعناع', 'منعش ومبرّد', '١٢'), ('رمّان', 'حبات رمان طازجة', '١٦')]),
    ('سموذي', C['pink'], [('فراولة وموز', 'فراولة، موز، زبادي', '١٨'), ('توت مشكّل', 'توت أزرق، توت أحمر، عسل', '٢٠'), ('مانجو وأناناس', 'استوائي ومنعش', '١٩'), ('أخضر', 'سبانخ، تفاح، كيوي', '١٩')]),
    ('كاسات وبوكسات الفواكه', C['teal'], [('كاسة فواكه', 'تشكيلة موسمية', '١٥'), ('بوكس فواكه مشكّل', 'يكفي شخصين', '٢٩'), ('بوكس العائلة', 'يكفي ٤–٥ أشخاص', '٥٩'), ('سلطة فواكه بالقشطة', 'مع عسل ومكسرات', '٢٢')]),
    ('إضافات', C['yellow'], [('عسل طبيعي', '', '٣'), ('مكسرات', '', '٤'), ('شوفان', '', '٣'), ('آيس كريم فانيلا', '', '٥')]),
]
cols = [(1160, 640), (560, 640)]
positions = [(0, 600), (0, 1110), (1, 600), (1, 1110)]
for (title, col, items), (ci, y0) in zip(sections, positions):
    xr = cols[ci][0]; w = 520
    d.add(f'<rect x="{xr-w}" y="{y0-44}" width="{w}" height="62" rx="31" fill="{col}"/>')
    d.add(T(xr-30, y0, title, 34, C['cocoa'] if col in (C['yellow'], C['pink'], C['teal']) else C['cream'], 900, 'right'))
    for i, (n, desc, p) in enumerate(items):
        y = y0 + 76 + i * (84 if desc else 62)
        d.add(T(xr-20, y, n, 32, C['cocoa'], 800, 'right'))
        if desc:
            d.add(T(xr-20, y+36, desc, 22, C['brown'], 500, 'right', extra='opacity=".75"'))
        d.add(f'<line x1="{xr-w+90}" y1="{y-10}" x2="{xr-270}" y2="{y-10}" stroke="{C["brown"]}" stroke-width="2" stroke-dasharray="2 8" opacity=".5"/>')
        d.add(f'<circle cx="{xr-w+44}" cy="{y-12}" r="32" fill="{C["blush"]}"/>' + T(xr-w+44, y, p, 28, C['red'], 900))
d.add(glass(1060, 1695, 0.19, '#F7B3AE', '#D9606A', 'strawberry', ribbon=False) + glass(950, 1695, 0.19, '#FFE680', '#F4A340', 'orange', ribbon=False) + glass(840, 1695, 0.19, '#C9E68A', '#7DB547', 'kiwi', ribbon=False))
d.add(f'<rect x="80" y="1600" width="560" height="90" rx="20" fill="{C["cocoa"]}"/>' + d.icon(96, 1612, 66) + T(610, 1640, 'اطلب من تطبيق Fruit Box', 28, C['cream'], 800, 'right') + T(610, 1674, 'توصيل طازج • تتبّع طلبك لحظة بلحظة', 20, C['teal'], 600, 'right'))
d.add(T(620, 1735, 'الأسعار أمثلة للعرض ويمكن تعديلها في الملف المصدري', 18, C['brown'], 500, extra='opacity=".6"'))
done(d, 'fruitbox-product-menu-A3.svg')

# ---------------------------------------------------------------- 09 Instagram post 1080x1080
d = Doc(1080, 1080, '03-applications/09-instagram-post', C['mint'], 'Fruit Box Instagram post')
d.add(f'<circle cx="540" cy="600" r="420" fill="#fff" opacity=".6"/><rect width="1080" height="1080" fill="url(#dots)" opacity=".4"/>')
d.add(d.logo(540, 150, 230))
d.add(T(540, 360, 'سموذي الفراولة', 96, C['cocoa'], 900) + T(540, 440, 'خصم ٢٠٪ على طلبك الأول من التطبيق', 44, C['red'], 800))
d.add(glass(500, 985, 0.62, '#F7B3AE', '#D9606A', 'strawberry'))
d.add(strawberry(170, 860, 0.7, -20) + strawberry(900, 900, 0.6, 20) + leaf(840, 760, 1.2, -30) + leaf(160, 650, 1.2, 200))
d.add(f'<rect x="760" y="600" width="290" height="96" rx="48" fill="{C["cocoa"]}"/>' + T(905, 662, 'كود: FRESH20', 34, C['cream'], 800))
d.add(f'<rect y="1000" width="1080" height="80" fill="{C["cocoa"]}"/>' + T(540, 1052, TAG + ' • اطلب الآن', 34, C['cream'], 800))
done(d, 'fruitbox-instagram-post-1080x1080.svg')

# ---------------------------------------------------------------- 10 Instagram story 1080x1920
d = Doc(1080, 1920, '03-applications/10-instagram-story', C['cocoa'], 'Fruit Box Instagram story')
d.add(f'<rect width="1080" height="1920" fill="url(#dots)" opacity=".18"/><circle cx="540" cy="1020" r="520" fill="{C["teal"]}" opacity=".25"/>')
d.add(d.logo(540, 300, 380, dark=True))
d.add(T(540, 600, 'بوكس الفواكه اليومي', 92, C['cream'], 900) + T(540, 690, 'فواكه موسمية مقطّعة وجاهزة • تصلك باردة', 40, C['teal'], 700))
d.add(f'<g filter="url(#shadow)"><rect x="190" y="800" width="700" height="520" rx="40" fill="{C["cream"]}"/></g>')
d.add(f'<rect x="230" y="840" width="620" height="440" rx="26" fill="#F7EFE4"/>')
fr = [strawberry(340, 960, 0.5, -10), orange_slice(500, 950, 70), kiwi(680, 960, 72), kiwi(360, 1150, 66), strawberry(540, 1150, 0.5, 15), orange_slice(720, 1150, 68)]
d.add(''.join(fr) + '<path d="M230 1060 H850" stroke="#E0CDB5" stroke-width="6"/><path d="M540 840 V1280" stroke="#E0CDB5" stroke-width="6" opacity="0"/>')
d.add(f'<rect x="390" y="1290" width="300" height="70" rx="12" fill="{C["brown"]}"/>' + T(540, 1338, 'ابتداءً من ٢٩', 40, C['cream'], 900))
d.add(T(540, 1460, TAG, 64, C['pink'], 900))
d.add(f'<rect x="240" y="1620" width="600" height="120" rx="60" fill="{C["teal"]}"/>' + T(540, 1698, 'اسحب للأعلى واطلب الآن', 44, C['cocoa'], 900))
d.add(f'<path d="M510 1590 L540 1560 L570 1590" stroke="{C["cream"]}" stroke-width="8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
done(d, 'fruitbox-instagram-story-1080x1920.svg', 1)

# ---------------------------------------------------------------- 11 web / app banners
d = Doc(1920, 640, '03-applications/11-web-app-banner', C['cream'], 'Fruit Box web hero banner')
d.add(f'<path d="M0 0 H900 Q760 320 900 640 H0 Z" fill="{C["mint"]}"/><rect width="1920" height="640" fill="url(#dots)" opacity=".3"/>')
d.add(glass(450, 600, 0.72, '#F7B3AE', '#D9606A', 'strawberry') + glass(200, 600, 0.45, '#FFE680', '#F4A340', 'orange', ribbon=False) + glass(700, 600, 0.45, '#C9E68A', '#7DB547', 'kiwi', ribbon=False))
d.add(d.logo(1640, 170, 260))
d.add(T(1800, 360, 'فاكهتك على مزاجك', 92, C['cocoa'], 900, 'right'))
d.add(T(1800, 430, 'عصائر وسموذي وبوكسات فواكه طازجة، تُحضَّر عند الطلب وتصلك باردة.', 30, C['brown'], 600, 'right'))
d.add(f'<rect x="1500" y="480" width="300" height="84" rx="42" fill="{C["red"]}"/>' + T(1650, 534, 'اطلب الآن', 38, C['cream'], 900))
d.add(f'<rect x="1170" y="480" width="300" height="84" rx="42" fill="none" stroke="{C["cocoa"]}" stroke-width="4"/>' + T(1320, 534, 'تصفّح القائمة', 34, C['cocoa'], 800))
done(d, 'fruitbox-web-hero-banner-1920x640.svg')

d = Doc(1080, 540, '03-applications/11-web-app-banner', C['teal'], 'Fruit Box in-app banner')
d.add(f'<circle cx="220" cy="300" r="300" fill="#fff" opacity=".22"/>')
d.add(glass(230, 520, 0.62, '#F7B3AE', '#D9606A', 'strawberry'))
d.add(f'<rect x="760" y="60" width="260" height="60" rx="30" fill="{C["cocoa"]}"/>' + T(890, 101, 'عرض محدود', 30, C['cream'], 800))
d.add(T(1020, 230, 'الحبة الثانية', 76, C['cocoa'], 900, 'right') + T(1020, 320, 'بنصف السعر', 76, C['cream'], 900, 'right'))
d.add(T(1020, 384, 'على جميع أنواع السموذي حتى نهاية الأسبوع', 30, C['cocoa'], 700, 'right'))
d.add(f'<rect x="760" y="420" width="260" height="76" rx="38" fill="{C["red"]}"/>' + T(890, 470, 'اطلب الآن', 34, C['cream'], 900))
done(d, 'fruitbox-in-app-banner-1080x540.svg')

json.dump(jobs, open('_work/jobs_b.json', 'w'), indent=1)
print(len(jobs), 'svg written')
