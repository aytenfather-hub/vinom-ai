"""Builds data/seed_menu_new_shahama.json and data/seed_branches.json from the
observed menu (tools/menu_source.txt) and validates it against the counts the
owner supplied. Money is stored in fils (1 AED = 100 fils) to avoid float errors.

Nothing is invented: items marked "?" get price_mode=by_selection and a null
price; names are kept exactly as observed (spelling_review=pending).
Run: python3 tools/build_seed.py
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'tools', 'menu_source.txt')
SOURCE_URL = 'https://www.talabat.com/ar/uae/restaurant/743405/fruit-box-new-shahama?aid=1495'
OBSERVED_AT = '2026-09-29'

EXPECTED = {'categories': 14, 'items': 110, 'fixed': 38, 'by_selection': 72}
EXPECTED_PER_CATEGORY = [14, 1, 5, 2, 5, 9, 11, 7, 14, 7, 9, 9, 9, 8]
BRANCHES = ['الخالدية غرب 9', 'آل نهيان', 'السمحة', 'الشهامة الجديدة', 'بني ياس', 'سوق بلدية خليفة',
            'شارع السلام', 'محوي', 'مدينة الرياض', 'مدينة خليفة', 'مول الشامخة']


def fils(txt):
    return int(round(float(txt) * 100))


def parse():
    cats = []
    for raw in open(SRC, encoding='utf-8'):
        line = raw.strip()
        if not line or (line.startswith('#') and not line.startswith('## ')):
            continue
        if line.startswith('## '):
            cats.append({'name_ar_observed': line[3:].strip(), 'items': []})
            continue
        name, price = [p.strip() for p in line.rsplit('|', 1)]
        item = {'name_ar_observed': name}
        if price == '?':
            item.update(price_mode='by_selection', base_price_fils=None)
        else:
            m = re.fullmatch(r'([\d.]+)(?:\s+was\s+([\d.]+))?', price)
            if not m:
                sys.exit(f'bad price: {line}')
            item.update(price_mode='fixed', base_price_fils=fils(m.group(1)))
            if m.group(2):
                item['observed_offer'] = {'offer_price_fils': fils(m.group(1)), 'previous_price_fils': fils(m.group(2)),
                                          'status': 'pending_approval',
                                          'note': 'Temporary offer observed on Talabat; must be approved and scheduled before launch.'}
                item['base_price_fils'] = fils(m.group(2))  # regular price; the offer is a separate, unapproved record
        cats[-1]['items'].append(item)
    return cats


def build():
    cats = parse()
    out = {'source': {'url': SOURCE_URL, 'observed_at': OBSERVED_AT, 'branch': 'الشهامة الجديدة', 'currency': 'AED',
                      'money_unit': 'fils', 'status': 'observed_reference_not_approved'},
           'issues': [], 'categories': []}
    for ci, c in enumerate(cats, 1):
        cid = f'cat_{ci:02d}'
        cat = {'id': cid, 'sort': ci, 'name_ar_observed': c['name_ar_observed'], 'name_en': None,
               'spelling_review': 'pending', 'items': []}
        for ii, it in enumerate(c['items'], 1):
            it = {'id': f'{cid}_item_{ii:02d}', 'sort': ii, **it, 'name_en': None, 'description_ar': None,
                  'description_en': None, 'image': None, 'sizes': [], 'addons': [], 'allergens': None,
                  'spelling_review': 'pending', 'content_status': 'awaiting_owner_approval'}
            cat['items'].append(it)
        out['categories'].append(cat)
    # recorded data conflicts (kept as observed, not "fixed" by guessing)
    c2 = out['categories'][1]
    out['issues'].append({'type': 'category_price_conflict', 'category_id': c2['id'],
                          'item_id': c2['items'][0]['id'],
                          'detail': 'Category name says 19 AED but the observed item price is 72 AED. Kept as observed; needs owner decision.'})
    for c in out['categories']:
        for it in c['items']:
            if it['name_ar_observed'].endswith(':'):
                out['issues'].append({'type': 'spelling', 'item_id': it['id'],
                                      'detail': f"Observed name ends with a colon: '{it['name_ar_observed']}'."})
    out['issues'].append({'type': 'offer_pending', 'category_id': out['categories'][12]['id'],
                          'detail': '9 dessert items show 22.50 AED (was 45.00). Stored as a pending offer, not as the price.'})
    return out


def validate(m):
    items = [i for c in m['categories'] for i in c['items']]
    got = {'categories': len(m['categories']), 'items': len(items),
           'fixed': sum(i['price_mode'] == 'fixed' for i in items),
           'by_selection': sum(i['price_mode'] == 'by_selection' for i in items)}
    per = [len(c['items']) for c in m['categories']]
    errors = []
    if got != EXPECTED: errors.append(f'counts {got} != {EXPECTED}')
    if per != EXPECTED_PER_CATEGORY: errors.append(f'per-category {per} != {EXPECTED_PER_CATEGORY}')
    for i in items:
        if i['price_mode'] == 'by_selection' and i['base_price_fils'] is not None: errors.append(f'invented price {i["id"]}')
        if i['price_mode'] == 'fixed' and not i['base_price_fils']: errors.append(f'missing price {i["id"]}')
    ids = [i['id'] for i in items]
    if len(set(ids)) != len(ids): errors.append('duplicate ids')
    prices = sorted({i['base_price_fils'] / 100 for i in items if i['base_price_fils']})
    return got, per, prices, errors


if __name__ == '__main__':
    menu = build()
    got, per, prices, errors = validate(menu)
    os.makedirs(os.path.join(ROOT, 'data'), exist_ok=True)
    json.dump(menu, open(os.path.join(ROOT, 'data', 'seed_menu_new_shahama.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    branches = [{'id': f'br_{i:02d}', 'name_ar_observed': n, 'name_en': None, 'address': None, 'lat': None, 'lng': None,
                 'phone': None, 'opening_hours': None, 'services': [], 'status': 'pending_owner_data',
                 'menu_source': 'observed_reference' if n == 'الشهامة الجديدة' else None}
                for i, n in enumerate(BRANCHES, 1)]
    json.dump({'branches': branches}, open(os.path.join(ROOT, 'data', 'seed_branches.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('counts', got)
    print('per category', per)
    print('distinct fixed/base prices AED', prices)
    print('issues', len(menu['issues']))
    for e in menu['issues']: print('  -', e['type'], ':', e['detail'])
    print('VALID' if not errors else 'INVALID: ' + '; '.join(errors))
    sys.exit(1 if errors else 0)
