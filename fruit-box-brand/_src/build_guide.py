"""Generates 05-brand-guidelines/fruitbox-brand-guidelines-ar.html (A4 landscape, RTL).
Rendered to PDF by render.cjs."""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PAL = [  # name, role, hex, source
    ('بني الشريط', 'Ribbon Brown — أساسي', '#8A3D1F', 'مستخرج من الشريط'),
    ('كاكاو داكن', 'Deep Cocoa — أساسي', '#602713', 'ظلّ الشريط'),
    ('نعناعي', 'Mint Teal — أساسي', '#71BCA8', 'الدائرة خلف الفواكه'),
    ('أحمر الفراولة', 'Strawberry Red — مميز', '#C1232C', 'الفراولة والشفاطة'),
    ('وردي السموذي', 'Smoothie Pink — مساند', '#F39A99', 'كوب السموذي'),
    ('أصفر الموز', 'Banana Yellow — مساند', '#FCD82F', 'الموز'),
    ('أخضر الورق', 'Leaf Green — مساند', '#5F973E', 'أوراق الفواكه'),
    ('كريمي', 'Cream — محايد', '#FDF8F3', 'حروف Fruit Box'),
]
NEUTRAL = [('شوفان', 'Oat', '#F4EADF'), ('نعناعي فاتح', 'Mint tint', '#E3F2EE'), ('وردي فاتح', 'Blush tint', '#FDE9E6'), ('حبر', 'Ink text', '#2B1A12')]


def rgb(h):
    h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def cmyk(h):
    r, g, b = [x / 255 for x in rgb(h)]
    k = 1 - max(r, g, b)
    if k >= 1: return (0, 0, 0, 100)
    c, m, y = [(1 - x - k) / (1 - k) for x in (r, g, b)]
    return tuple(round(v * 100) for v in (c, m, y, k))


def lum(h):
    def ch(v):
        v /= 255; return v / 12.92 if v <= .03928 else ((v + .055) / 1.055) ** 2.4
    r, g, b = rgb(h); return .2126 * ch(r) + .7152 * ch(g) + .0722 * ch(b)


def contrast(a, b):
    la, lb = sorted([lum(a), lum(b)], reverse=True); return (la + .05) / (lb + .05)


L = '../01-logo/fruitbox-logo-original-transparent.png'
LD = '../01-logo/fruitbox-logo-dark-bg-version-transparent.png'
I = '_img/'
pages = []


def page(body, cls='', num=True, title=None, kicker=None):
    head = f'<div class="ph"><span class="k">{len(pages)+1:02d}</span><h2>{title}</h2></div>' if title else ''
    pages.append(f'<section class="page {cls}">{head}{body}' + (f'<div class="pn"><span>Fruit Box • دليل الهوية البصرية</span><span class="en">{len(pages)+1:02d}</span></div>' if num else '') + '</section>')


# 1 cover
page(f'''<div class="cover"><div class="cv-l"><img src="{L}" class="cv-logo"></div>
<div class="cv-r"><div class="k">دليل الهوية البصرية • الإصدار ١٫٠ • ٢٠٢٦</div><h1>Fruit Box</h1><p class="tag">فاكهتك على مزاجك</p>
<p class="lead">القواعد الأساسية لاستخدام الشعار والألوان والخطوط والتطبيقات المطبوعة والرقمية، لتظهر العلامة طازجة وشهية ومتّسقة في كل مكان.</p></div></div>''', 'p-cover', num=False)

# 2 contents + source audit
toc_pages = [3,4,5,6,7,8,9,10,11,12,13,14,16,17,18]
toc = ['فكرة العلامة', 'شخصية العلامة ونبرة الصوت', 'الشعار الأساسي', 'نسخ الشعار', 'المساحة الآمنة والأحجام', 'الخلفيات المسموحة', 'الاستخدامات الممنوعة', 'لوحة الألوان', 'الخطوط', 'العناصر المساندة', 'أيقونة التطبيق', 'التطبيقات المطبوعة', 'التطبيقات الرقمية', 'الواجهة الرقمية', 'ملاحظات فنية وتسليم الملفات']
page(f'''<div class="cols2"><div><ol class="toc">{''.join(f'<li><span class="en">{toc_pages[i]:02d}</span>{t}</li>' for i, t in enumerate(toc))}</ol></div>
<div class="box warn"><h3>فحص ملف الشعار المستلم</h3>
<table class="spec"><tr><td>الملف</td><td class="en">JPEG (progressive)، ‏RGB، ‏8-bit</td></tr><tr><td>الأبعاد</td><td class="en">767 × 717 px</td></tr>
<tr><td>مساحة الرسم الفعلية</td><td class="en">≈ 624 × 498 px</td></tr><tr><td>الخلفية</td><td>بيضاء صافية (‎#FFFFFF‎) — لا توجد شفافية</td></tr>
<tr><td>النوع</td><td>رسم نقطي (Raster) بتفاصيل تصويرية؛ لا توجد نسخة متجهية</td></tr>
<tr><td>أقصى طباعة جيدة</td><td>≈ ٥٫٥ سم عرضاً بدقة ٣٠٠ نقطة/إنش، ≈ ١١ سم بدقة ١٥٠</td></tr></table>
<p>تم فصل الشعار عن الخلفية البيضاء دون أي تعديل على الرسم، وتم إنتاج نسخة شفافة ونسخة للخلفيات الداكنة. <b>الملف صغير نسبياً</b>: يكفي للشاشات والمطبوعات الصغيرة، أما اللافتات والواجهات والطباعة الكبيرة فتحتاج إلى الملف الأصلي عالي الدقة من المصمم، أو إعادة رسم احترافية مطابقة للشعار.</p></div></div>''',
     title='المحتويات', kicker='00')

# 3 idea
page(f'''<div class="cols2"><div><p class="big">صندوق مليء بالفواكه الطازجة، وكوب سموذي في قلبه.</p>
<p>تقوم فكرة <b class="en">Fruit Box</b> على الوفرة والطزاجة: فواكه ملوّنة تحيط بكوب سموذي وردي، وشريط بني دافئ يحمل الاسم كختم جودة. الوعد بسيط: كل طلب يُحضَّر من فاكهة حقيقية، وفق ذوق العميل.</p>
<p>الشعار غني بالتفاصيل، لذلك تعتمد الهوية على <b>مساحات هادئة وألوان مستخرجة من الشعار</b> حتى يبقى الشعار نجم التصميم.</p>
<div class="pill-row"><span class="pill" style="background:#71BCA8">طازج</span><span class="pill" style="background:#F39A99">شهي</span><span class="pill" style="background:#FCD82F">مرح</span><span class="pill" style="background:#602713;color:#FDF8F3">احترافي</span></div></div>
<div class="imgcard"><img src="{I}fruitbox-juice-cups.jpg"></div></div>
<div class="box mint"><b>الشعار التسويقي المقترح:</b> «فاكهتك على مزاجك» — يُستخدم بجانب الشعار أو في الحملات، <u>وليس جزءاً من الشعار الأصلي</u> ولا يوضع داخله.</div>''',
     title='فكرة العلامة', kicker='01')

# 4 personality
traits = [('طازجة', 'نتحدث عن الفاكهة كما هي: حقيقية، موسمية، مُحضّرة الآن.', '#71BCA8'), ('شهية', 'صور وأوصاف تجعل العميل يتذوّق قبل أن يطلب.', '#F39A99'),
          ('مرحة', 'لغة خفيفة وودودة، بدون مبالغة أو تهريج.', '#FCD82F'), ('موثوقة', 'وضوح في الأسعار والمكوّنات ومواعيد التوصيل.', '#8A3D1F')]
page(f'''<div class="grid4">{''.join(f'<div class="trait" style="border-top:10px solid {c}"><h3>{t}</h3><p>{d}</p></div>' for t, d, c in traits)}</div>
<div class="cols2" style="margin-top:8mm"><div class="box"><h3>نقول ✓</h3><ul><li>«سموذي الفراولة جاهز على مزاجك»</li><li>«فواكه اليوم وصلت، طلبك يُقطّع الآن»</li><li>«طلبك في الطريق، ١٢ دقيقة وتوصلك باردة»</li></ul></div>
<div class="box"><h3>نتجنّب ✗</h3><ul><li>المبالغات الطبية: «يعالج» أو «يحرق الدهون»</li><li>العامية الثقيلة أو السخرية من العملاء</li><li>الخلط بين الأرقام الهندية والعربية داخل النص الواحد</li></ul></div></div>''',
     title='شخصية العلامة ونبرة الصوت', kicker='02')

# 5 primary logo
page(f'''<div class="cols2" style="align-items:center"><div class="logo-stage checker"><img src="{L}" style="width:80%"></div>
<div><p class="big">الشعار الأصلي كما هو.</p><p>تكوين الفواكه، كوب العصير، الألوان، الشريط البني وكتابة <span class="en">Fruit Box</span> عناصر ثابتة لا تُعدّل ولا يُعاد رسمها ولا يُغيَّر ترتيبها.</p>
<table class="spec"><tr><td>الملف المعتمد</td><td class="en">fruitbox-logo-original-transparent.png</td></tr><tr><td>الأبعاد</td><td class="en">648 × 522 px • PNG شفاف</td></tr>
<tr><td>النسبة</td><td class="en">1.24 : 1</td></tr><tr><td>الاستخدام</td><td>كل التطبيقات على خلفيات فاتحة وهادئة</td></tr></table></div></div>''',
     title='الشعار الأساسي', kicker='03')

# 6 versions
page(f'''<div class="grid4 v">
<div class="vcard"><div class="vs" style="background:#fff"><img src="{L}"></div><h4>الأصلي</h4><p>للخلفيات البيضاء والفاتحة</p></div>
<div class="vcard"><div class="vs" style="background:#602713"><img src="{LD}"></div><h4>للخلفيات الداكنة</h4><p>نفس الرسم مع إطار كريمي خارجي يفصله عن الخلفية</p></div>
<div class="vcard"><div class="vs" style="background:#F4EADF"><img src="{I}fruitbox-logo-profile-avatar-1080.jpg" style="border-radius:50%;width:70%"></div><h4>مصغّرة للصور الشخصية</h4><p>دائرة كريمية، الشعار كاملاً داخلها</p></div>
<div class="vcard"><div class="vs" style="background:#E3F2EE"><img src="../02-app-icon/fruitbox-app-icon-rounded.svg" style="width:55%"></div><h4>أيقونة التطبيق</h4><p>رمز مستقل، <b>ليس</b> بديلاً عن الشعار</p></div></div>
<div class="wide"><img src="{I}fruitbox-logo-horizontal-light.jpg"></div>
<p class="note"><b>النسخة الأفقية:</b> رسم الشعار متداخل (الشريط يعلو الفواكه)، لذلك لا يمكن فصل الشريط عن الفواكه دون تغيير الرسم. الحل المعتمد: الشعار كاملاً بدون تعديل + كتلة نصية جانبية (الاسم بالعربية «فروت بوكس» والشعار التسويقي). الاسم العربي نقل حرفي مقترح يمكن حذفه.</p>''',
     title='نسخ الشعار', kicker='04')

# 7 clear space & sizes
page(f'''<div class="cols2" style="grid-template-columns:110mm 1fr"><div><div class="cs"><div class="cs-in"><img src="{L}"></div>
<span class="x t">x</span><span class="x b">x</span><span class="x r">x</span><span class="x l">x</span></div>
<p><b>المساحة الآمنة = x</b> حيث x يساوي ارتفاع الجزء الأوسط من الشريط البني (≈ سُدس ارتفاع الشعار). لا يدخل هذه المساحة أي نص أو صورة أو حافة.</p></div>
<div><h3>الأحجام</h3><div class="sizes"><div><img src="{L}" style="width:30mm"><span>٣٠ مم<br>الحد الأدنى للطباعة</span></div><div><img src="{L}" style="width:40mm"><span>٤٠ مم<br>مُوصى به</span></div><div><img src="{L}" style="width:55mm"><span>٥٥ مم<br>أقصى حجم بجودة ٣٠٠dpi</span></div></div>
<table class="spec"><tr><td>أصغر عرض رقمي</td><td class="en">120 px</td></tr><tr><td>أصغر عرض مطبوع</td><td>٣٠ مم (أصغر من ذلك تختفي كتابة الاسم)</td></tr>
<tr><td>أقل من ذلك</td><td>استخدم أيقونة التطبيق أو الاسم مكتوباً</td></tr><tr><td>أكبر من ١١ سم مطبوعاً</td><td>يتطلب ملفاً عالي الدقة (انظر الملاحظات الفنية)</td></tr></table></div></div>''',
     title='المساحة الآمنة والأحجام', kicker='05')

# 8 backgrounds
bgs = [('#FFFFFF', L, 'أبيض', True), ('#FDF8F3', L, 'كريمي', True), ('#E3F2EE', L, 'نعناعي فاتح', True), ('#FDE9E6', L, 'وردي فاتح', True),
       ('#602713', LD, 'كاكاو + نسخة الداكن', True), ('#1E1410', LD, 'داكن جداً + نسخة الداكن', True), ('#71BCA8', L, 'نعناعي كامل — يتعارض مع الدائرة', False), ('#C1232C', L, 'أحمر — يطغى على الفاكهة', False)]
page(f'''<div class="grid4 bg">{''.join(f'<div class="bgc {"ok" if ok else "no"}"><div class="vs" style="background:{c}"><img src="{src}"></div><p>{"✓" if ok else "✗"} {n}</p></div>' for c, src, n, ok in bgs)}</div>
<p class="note">على الصور الفوتوغرافية: ضع الشعار في منطقة هادئة وغير مزدحمة، واستخدم نسخة الخلفية الداكنة إذا كانت المنطقة داكنة.</p>''',
     title='الخلفيات المسموحة', kicker='06')

# 9 misuse
mis = [('style="transform:scaleX(1.45)"', 'لا تمطّ الشعار أو تضغطه'), ('style="transform:rotate(-18deg)"', 'لا تُدِر الشعار'), ('style="filter:hue-rotate(150deg)"', 'لا تغيّر الألوان'),
       ('style="filter:drop-shadow(0 0 8px #0ff) drop-shadow(0 0 14px #f0f)"', 'لا تضف مؤثرات أو توهّجاً'), ('class="busy"', 'لا تضعه على خلفية مزدحمة'), ('class="crop"', 'لا تقصّ أجزاء من الشعار'),
       ('class="dark"', 'لا تستخدم الأصلي على الداكن'), ('class="tiny"', 'لا تصغّره تحت الحد الأدنى')]
page(f'''<div class="grid4 mis">{''.join(f'<div class="mc"><div class="vs {"bb" if "busy" in a else ""} {"db" if "dark" in a else ""}"><img src="{L}" {a}><i>✕</i></div><p>{t}</p></div>' for a, t in mis)}</div>
<p class="note">كذلك: لا تُعد كتابة اسم <span class="en">Fruit Box</span> بخط آخر، ولا تضع الشعار التسويقي داخل الشريط، ولا تعد ترتيب الفواكه، ولا تستبدل الشعار بأي رسم مشابه.</p>''',
     title='الاستخدامات الممنوعة', kicker='07')

# 10 colours
sw = ''
for n, role, h, srcn in PAL:
    r = rgb(h); c = cmyk(h); dark = lum(h) < .35
    sw += (f'<div class="sw"><div class="chip" style="background:{h};color:{"#FDF8F3" if dark else "#2B1A12"}{";border:1px solid #E5D8C8" if h == "#FDF8F3" else ""}"><b>{n}</b><span class="en">{role}</span></div>'
           f'<table><tr><td>HEX</td><td class="en">{h}</td></tr><tr><td>RGB</td><td class="en">{r[0]} {r[1]} {r[2]}</td></tr><tr><td>CMYK≈</td><td class="en">{c[0]} {c[1]} {c[2]} {c[3]}</td></tr></table><small>{srcn}</small></div>')
nt = ''.join(f'<span class="nt"><i style="background:{h}"></i>{n} <span class="en">{h}</span></span>' for n, e, h in NEUTRAL)
page(f'''<div class="grid4 sws">{sw}</div><div class="neut">درجات مساندة للخلفيات والنصوص: {nt}</div>
<p class="note">الألوان مستخرجة بالقياس من ملف الشعار (متوسط البكسلات لكل لون). قيم <span class="en">CMYK</span> تقريبية (تحويل رياضي بدون ملف ICC) — اعتمد بروفة طباعة من المطبعة قبل الإنتاج. تباين النص: الكاكاو على الكريمي <span class="en">{contrast("#602713", "#FDF8F3"):.1f}:1</span>، الأحمر على الكريمي <span class="en">{contrast("#C1232C", "#FDF8F3"):.1f}:1</span>، النعناعي على الكريمي <span class="en">{contrast("#71BCA8", "#FDF8F3"):.1f}:1</span> (للزخارف والعناوين الكبيرة فقط، لا للنص الصغير).</p>''',
     title='لوحة الألوان', kicker='08')

# 11 typography
page(f'''<div class="cols2"><div class="type"><div class="k">الخط العربي</div><div class="spec-big" style="font-weight:900">Cairo</div>
<div style="font-weight:900;font-size:26pt;color:#602713">فاكهتك على مزاجك</div><div style="font-weight:700;font-size:15pt">سموذي الفراولة والموز — ١٨ ر.س</div>
<div style="font-weight:400;font-size:11pt">نص الفقرات: فواكه موسمية مختارة بعناية، تُحضَّر عند الطلب وتصلك باردة.</div>
<table class="spec"><tr><td>العناوين</td><td class="en">Black 900 / ExtraBold 800</td></tr><tr><td>العناوين الفرعية</td><td class="en">Bold 700</td></tr><tr><td>النصوص</td><td class="en">Regular 400 / SemiBold 600</td></tr></table></div>
<div class="type"><div class="k">الخط اللاتيني</div><div class="spec-big en" style="font-weight:800">Poppins</div>
<div class="en" style="font-weight:800;font-size:26pt;color:#602713" dir="ltr">Fresh. Daily. Yours.</div><div class="en" style="font-weight:600;font-size:15pt" dir="ltr">FRESH20 • #FB-2048 • 330 ml</div>
<div class="en" style="font-weight:400;font-size:11pt" dir="ltr">For codes, numbers in English UI, and bilingual materials.</div>
<table class="spec"><tr><td>الاستخدام</td><td>الأكواد، العناوين الإلكترونية، المواد ثنائية اللغة</td></tr><tr><td>الأوزان</td><td class="en">400 / 600 / 700 / 800</td></tr><tr><td>الترخيص</td><td>الخطّان مجانيان (<span class="en">SIL Open Font License</span>) ومرفقان في مجلد <span class="en">fonts</span></td></tr></table></div></div>
<p class="note">اسم <span class="en">Fruit Box</span> داخل الشعار خط يدوي خاص بالرسم الأصلي، ولا يُقلَّد بخط آخر في العناوين.</p>''',
     title='الخطوط', kicker='09')

# 12 supporting elements
page(f'''<div class="grid3">
<div class="box"><h3>الرسوم المساندة</h3><div style="display:flex;gap:4mm;justify-content:center;align-items:end;height:48mm"><img src="../04-digital-ui/assets/drink-orange.svg" style="height:34mm"><img src="../04-digital-ui/assets/drink-strawberry.svg" style="height:46mm"><img src="../04-digital-ui/assets/drink-green.svg" style="height:34mm"></div><p>أكواب سموذي مسطّحة بنفس لغة أيقونة التطبيق، تُستخدم لتمثيل المنتجات عند غياب الصور.</p></div>
<div class="box"><h3>النقش</h3><div style="height:48mm;border-radius:4mm;background:#FDF8F3 radial-gradient(circle at 6px 6px,#71BCA880 3px,transparent 3.5px) 0 0/22px 22px,radial-gradient(circle at 17px 17px,#F39A9990 3px,transparent 3.5px) 0 0/22px 22px"></div><p>نقاط نعناعية ووردية بشفافية منخفضة، للخلفيات فقط.</p></div>
<div class="box"><h3>الشريط والمنحنى</h3><div style="height:48mm;display:grid;place-items:center"><svg viewBox="0 0 300 120" width="90%"><path d="M20 40 L70 35 L70 95 L20 100 L38 68Z M280 40 L230 35 L230 95 L280 100 L262 68Z" fill="#602713"/><path d="M60 30 Q150 15 240 30 L240 90 Q150 75 60 90Z" fill="#8A3D1F"/><path d="M95 55 Q150 46 205 55" stroke="#FDF8F3" stroke-width="8" stroke-linecap="round" fill="none"/></svg></div><p>شكل الشريط المبسّط يُستخدم كإطار للعناوين والأسعار — بدون نص الشعار.</p></div></div>
<div class="wide" style="margin-top:6mm"><img src="{I}fruitbox-in-app-banner-1080x540.jpg" style="height:52mm;border-radius:4mm"></div>''',
     title='العناصر المساندة', kicker='10')

# 13 app icon
page(f'''<div class="cols2" style="grid-template-columns:1.4fr 1fr;align-items:center"><div class="imgcard"><img src="{I}preview-app-icon-light-and-dark.jpg"></div>
<div><p class="big">رمز مستقل، مبسّط للأحجام الصغيرة.</p><p>مستوحى من عناصر الشعار نفسه: الدائرة النعناعية، كوب السموذي الوردي، الشفاطة الحمراء، حبة الفراولة، والشريط البني — لكنه <b>رسم متجهي جديد مبسّط</b> وليس نسخة مصغّرة من الشعار، ولا يحتوي على نص.</p>
<table class="spec"><tr><td>المصدر</td><td class="en">SVG — vector 100%</td></tr><tr><td>التصدير</td><td class="en">1024 / 512 / 192 / 180 / 48 / 32 px</td></tr><tr><td>متى يُستخدم</td><td>أيقونة التطبيق، المفضلة في المتصفح، الإشعارات، الأختام الصغيرة</td></tr><tr><td>متى لا يُستخدم</td><td>كبديل عن الشعار في اللافتات والتغليف</td></tr></table></div></div>''',
     title='أيقونة التطبيق', kicker='11')

# 14-16 applications
def appgrid(items, cls='g2'):
    return f'<div class="apps {cls}">' + ''.join(f'<figure><img src="{I}{f}"><figcaption>{c}</figcaption></figure>' for f, c in items) + '</div>'
page(appgrid([('fruitbox-juice-cups.jpg', 'أكواب العصير: بلاستيك شفاف، ورقي فاتح، ورقي داكن'), ('fruitbox-package-box-and-bottle.jpg', 'بوكس الفواكه وعبوة العصير'), ('fruitbox-delivery-bags.jpg', 'أكياس التوصيل'), ('fruitbox-seal-stickers.jpg', 'ملصقات الإغلاق والأختام')]), title='التطبيقات المطبوعة (١)', kicker='12')
page(appgrid([('fruitbox-staff-uniform.jpg', 'زي الموظفين: قميص، مريلة، قبعة، بطاقة اسم'), ('fruitbox-storefront.jpg', 'واجهة المحل — تحتاج ملف شعار عالي الدقة للتنفيذ'), ('fruitbox-business-card-front-back.jpg', 'بطاقة العمل ٨٥×٥٥ مم'), ('fruitbox-product-menu-A3.jpg', 'قائمة المنتجات A3')]), title='التطبيقات المطبوعة (٢)', kicker='12')
page(f'''<div class="apps g3s"><figure><img src="{I}fruitbox-instagram-post-1080x1080.jpg"><figcaption>منشور Instagram ‏1080×1080</figcaption></figure>
<figure><img src="{I}fruitbox-instagram-story-1080x1920.jpg"><figcaption>قصة Instagram ‏1080×1920</figcaption></figure>
<div><figure><img src="{I}fruitbox-web-hero-banner-1920x640.jpg"><figcaption>بانر الموقع ‏1920×640</figcaption></figure><figure style="margin-top:4mm"><img src="{I}fruitbox-in-app-banner-1080x540.jpg"><figcaption>بانر داخل التطبيق ‏1080×540</figcaption></figure></div></div>''',
     title='التطبيقات الرقمية', kicker='13')
page(f'''<div class="wide"><img src="{I}preview-mobile-app-all-screens.jpg" style="border-radius:4mm"></div>
<div class="cols2" style="grid-template-columns:1fr 1.2fr;margin-top:4mm;align-items:start"><div class="imgcard" style="max-height:62mm;overflow:hidden"><img src="{I}preview-website-home-desktop-1440.jpg"></div>
<div><ul><li>تصميم <b>RTL</b> أولاً (<span class="en">dir="rtl"</span>) مع خصائص CSS منطقية.</li><li>زر الطلب الرئيسي بالأحمر دائماً، والإجراءات الثانوية بإطار كاكاو.</li><li>النعناعي للنجاح والحالات المكتملة، والأحمر للحالة الحالية في تتبّع الطلب.</li><li>زوايا دائرية ٢٢ بكسل للبطاقات، وحبوب كاملة الاستدارة للأزرار.</li><li>المصدر: <span class="en">04-digital-ui/*.html + fruitbox-ui.css</span></li></ul></div></div>''',
     title='الواجهة الرقمية', kicker='14')

# 18 technical notes
page(f'''<div class="cols2"><div class="box warn"><h3>حدود الملف المصدر — بصراحة</h3><ul>
<li>الشعار المستلم صورة <span class="en">JPEG</span> بحجم <span class="en">767×717</span> وبخلفية بيضاء؛ تم فصله بدقة لكن <b>لا يمكن استخراج تفاصيل غير موجودة</b>.</li>
<li>لا يوجد ملف متجهي للشعار. ملفات <span class="en">SVG</span> في الحزمة هي تخطيطات قابلة للتعديل (أشكال ونصوص متجهية) <b>والشعار داخلها صورة PNG مرتبطة</b> وليس رسماً متجهياً.</li>
<li>أيقونة التطبيق والرسوم المساندة متجهية بالكامل.</li>
<li>النسخة <span class="en">@2x-interpolated</span> تكبير رياضي للعرض فقط ولا تضيف دقة.</li>
<li>للواجهة، اللافتات، والطباعة فوق ١١ سم: اطلب الملف الأصلي عالي الدقة من مصمم الشعار، أو إعادة رسم احترافية مطابقة ١٠٠٪.</li></ul></div>
<div class="box"><h3>بنية الملفات</h3><pre class="en" dir="ltr">01-logo/            logo versions (PNG) + lockups (SVG)
02-app-icon/        vector icon (SVG) + PNG sizes
03-applications/    11 designs: editable SVG + PNG
04-digital-ui/      RTL HTML/CSS prototype + PNG
05-brand-guidelines/ this PDF + HTML source
fonts/              Cairo, Poppins (OFL)
_src/               generator scripts</pre>
<p>النصوص والأسعار والأرقام في التصاميم أمثلة قابلة للتعديل. العملة (ر.س) في الواجهة الرقمية مثال فقط.</p></div></div>''',
     title='ملاحظات فنية وتسليم الملفات', kicker='15')

CSS = open(os.path.join(ROOT, '_src', 'guide.css'), encoding='utf-8').read()
html = f'''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><title>Fruit Box — دليل الهوية البصرية</title><style>{CSS}</style></head><body>{''.join(pages)}</body></html>'''
open(os.path.join(ROOT, '05-brand-guidelines', 'fruitbox-brand-guidelines-ar.html'), 'w', encoding='utf-8').write(html)
print(len(pages), 'pages')
