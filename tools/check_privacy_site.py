"""Check links, publication completeness and absence of trackers in the privacy site."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import argparse
import json
import re

ROOT=Path(__file__).resolve().parents[1]/'website'
class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links=[]; self.ids=[]; self.tags=[]; self.lang=None; self.headings=0
    def handle_starttag(self, tag, attributes):
        attrs=dict(attributes)
        self.tags.append(tag)
        if tag=='html': self.lang=attrs.get('lang')
        if tag=='h1': self.headings+=1
        if 'id' in attrs: self.ids.append(attrs['id'])
        assert not any(k.startswith('on') for k in attrs), 'Inline event handler'
        for key in ['href','src']:
            if key in attrs: self.links.append((tag,key,attrs[key]))

def check(allow_draft=False):
    meta=json.loads((ROOT/'publication.json').read_text(encoding='utf-8'))
    if not allow_draft:
        assert meta['ready_for_review'] and meta['contact_email'], 'Public email still pending'
    pages=list(ROOT.rglob('*.html'))
    assert len(pages)==4, 'Expected root and three language pages'
    langs=set()
    count=0
    for path in pages:
        source=path.read_text(encoding='utf-8')
        page=Page(); page.feed(source)
        langs.add(page.lang)
        assert page.headings==1, f'Expected one h1: {path}'
        assert len(page.ids)==len(set(page.ids))==12, f'Missing/duplicate sections: {path}'
        assert not ({'script','iframe','form','object','embed'} & set(page.tags)), f'Unexpected active content: {path}'
        assert 'Arenis: Sand Sort Challenge' in source and '2026-11-12' in source
        assert not re.search(r'\{(?:email|ads|google|delete|github|partners)\}',source)
        if not allow_draft:
            assert meta['contact_email'] in source and 'mailto:' in source
            assert 'class="draft"' not in source and 'noindex,nofollow' not in source
        for tag,key,url in page.links:
            parsed=urlsplit(url)
            if parsed.scheme:
                assert parsed.scheme in ['https','mailto'], f'Unsafe link: {url}'
                assert not (key=='src' or (tag=='link' and 'stylesheet' in url)), f'External asset: {url}'
            elif parsed.path:
                target=(path.parent/unquote(parsed.path)).resolve()
                assert target.is_relative_to(ROOT.resolve()), f'Path outside site: {url}'
                if target.is_dir(): target=target/'index.html'
                assert target.is_file(), f'Broken local link: {path} -> {url}'
            count+=1
    assert langs=={'pt-BR','en','es-419'}
    css=(ROOT/'styles.css').read_text(encoding='utf-8')
    assert 'http:' not in css and 'https:' not in css and '@import' not in css
    assert '(prefers-color-scheme:dark)' in css and '(max-width:620px)' in css
    assert (ROOT/'fonts/Manrope.ttf').is_file() and (ROOT/'fonts/OFL.txt').is_file()
    print(f'Privacy site: {len(pages)} pages, 12 sections each, 3 languages, {count} links checked; no scripts/forms/remote assets; draft={not meta["ready_for_review"]}.')

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--allow-draft',action='store_true')
    args=parser.parse_args()
    check(args.allow_draft)
