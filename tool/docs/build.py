#!/usr/bin/env python3
"""Builds docs/index.html from content.py.

    python3 tool/docs/build.py                 # writes docs/index.html
    python3 tool/docs/build.py --check FILE    # writes all examples to FILE.dart
                                               # for `flutter analyze`
    python3 tool/docs/build.py --fragment FILE # page without <html>/<head> wrapper
"""
import html
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from content import SECTIONS, VERSION  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

# --------------------------------------------------------------------------
# Dart syntax highlighting (build time, so the page needs no JavaScript for it)
# --------------------------------------------------------------------------
KEYWORDS = set('''abstract as assert async await break case catch class const continue
covariant default do dynamic else enum extends extension external factory false final
finally for get if implements import in is late library mixin new null on operator
part required rethrow return set show static super switch sync this throw true try
typedef var void when while with yield'''.split())

TOKEN = re.compile(r'''
  (?P<comment>//[^\n]*)
| (?P<string>r?'(?:[^'\\\n]|\\.)*'|r?"(?:[^"\\\n]|\\.)*")
| (?P<annotation>@[A-Za-z_]\w*)
| (?P<number>\b\d+(?:\.\d+)?\b|\b0x[0-9A-Fa-f]+\b)
| (?P<word>[A-Za-z_]\w*)
| (?P<other>[\s\S])
''', re.X)


def highlight(code):
    out = []
    tokens = list(TOKEN.finditer(code))
    for i, m in enumerate(tokens):
        kind = m.lastgroup
        text = html.escape(m.group())
        if kind == 'word':
            word = m.group()
            nxt = tokens[i + 1].group() if i + 1 < len(tokens) else ''
            if word in KEYWORDS:
                out.append(f'<span class="k">{text}</span>')
            elif word[0].isupper():
                out.append(f'<span class="t">{text}</span>')
            elif nxt in ('(', '<'):
                out.append(f'<span class="f">{text}</span>')
            else:
                out.append(text)
        elif kind == 'comment':
            out.append(f'<span class="c">{text}</span>')
        elif kind == 'string':
            out.append(f'<span class="s">{text}</span>')
        elif kind == 'annotation':
            out.append(f'<span class="a">{text}</span>')
        elif kind == 'number':
            out.append(f'<span class="n">{text}</span>')
        else:
            out.append(text)
    return ''.join(out)


def code_block(code, label='Example'):
    return (
        f'<figure class="code"><figcaption><span>{label}</span>'
        f'<button type="button" class="copy" aria-label="Copy code">Copy</button></figcaption>'
        f'<pre><code>{highlight(code)}</code></pre></figure>'
    )


def output_block(text):
    return (
        '<figure class="out"><figcaption>Output</figcaption>'
        f'<pre>{html.escape(text)}</pre></figure>'
    )


def table(rows, cls='grid'):
    head, *body = rows
    th = ''.join(f'<th>{c}</th>' for c in head)
    trs = ''.join('<tr>' + ''.join(f'<td>{c}</td>' for c in r) + '</tr>' for r in body)
    return f'<div class="scroll"><table class="{cls}"><thead><tr>{th}</tr></thead><tbody>{trs}</tbody></table></div>'


def params(rows):
    trs = ''.join(
        f'<tr><td><code class="p">{html.escape(n)}</code></td>'
        f'<td><code class="ty">{html.escape(t)}</code></td><td>{d}</td></tr>'
        for n, t, d in rows
    )
    return (
        '<div class="scroll"><table class="params"><thead><tr><th>Parameter</th>'
        f'<th>Type</th><th>What it does</th></tr></thead><tbody>{trs}</tbody></table></div>'
    )


KIND_LABEL = {'constructor': 'constructor', 'method': 'method', 'class': 'class',
              'enum': 'enum', 'guide': 'guide'}


def badge(item):
    verb = item.get('verb')
    if verb:
        return f'<span class="verb v-{verb.lower()}">{verb}</span>'
    kind = item.get('kind')
    if kind:
        return f'<span class="kind">{KIND_LABEL[kind]}</span>'
    return ''


def render_item(item):
    parts = [f'<article class="item" id="{item["id"]}" data-name="{html.escape(item["name"].lower())}">']
    parts.append(
        f'<h3><a class="anchor" href="#{item["id"]}">{html.escape(item["name"])}</a>{badge(item)}</h3>'
    )
    if 'sig' in item:
        parts.append(f'<pre class="sig"><code>{highlight(item["sig"])}</code></pre>')
    if 'text' in item:
        parts.append(f'<p>{item["text"]}</p>')
    if 'shell' in item:
        parts.append(
            '<figure class="code shell"><figcaption><span>Terminal</span>'
            '<button type="button" class="copy" aria-label="Copy command">Copy</button></figcaption>'
            f'<pre><code>{html.escape(item["shell"])}</code></pre></figure>'
        )
    if 'params' in item:
        parts.append(params(item['params']))
    if 'table' in item:
        parts.append(table(item['table']))
    if 'text2' in item:
        parts.append(f'<p>{item["text2"]}</p>')
    if 'code' in item:
        parts.append(code_block(item['code']))
    if 'code2' in item:
        parts.append(code_block(item['code2'], 'Usage'))
    if 'output' in item:
        parts.append(output_block(item['output']))
    parts.append('</article>')
    return '\n'.join(parts)


def render_nav():
    groups = []
    for sec in SECTIONS:
        links = ''.join(
            f'<li><a href="#{it["id"]}" data-name="{html.escape(it["name"].lower())}">'
            f'{html.escape(it["name"])}'
            + (f'<span class="dot v-{it["verb"].lower()}" aria-hidden="true"></span>' if it.get('verb') else '')
            + '</a></li>'
            for it in sec['items']
        )
        groups.append(f'<li class="group"><a class="gtitle" href="#{sec["id"]}">{sec["title"]}</a><ul>{links}</ul></li>')
    return '\n'.join(groups)


CSS = r'''
/* Layout: sticky index on the left, one reading column on the right.
   Signatures sit in a quiet panel; examples are dark terminal-style panels. */
:root {
  --bg: #f6f7f9;
  --surface: #ffffff;
  --ink: #131a26;
  --muted: #586174;
  --line: #dde2ea;
  --accent: #1f56d6;
  --accent-soft: #e6edfc;
  --code-bg: #111827;
  --code-ink: #e6e9ef;
  --code-line: #273145;
  --out-bg: #f0f3f7;
  --hl-k: #c792ea; --hl-t: #7dd3fc; --hl-s: #a5d6a7; --hl-c: #7b869a; --hl-f: #ffd580; --hl-n: #f9a87b; --hl-a: #f48fb1;
  --get: #0d7f57; --post: #1f56d6; --put: #9a5b00; --patch: #6d45c9; --delete: #b8322b; --head: #4b5568; --any: #4b5568;
  --font-display: 'Bricolage Grotesque', 'Segoe UI', system-ui, sans-serif;
  --font-body: 'IBM Plex Sans', 'Segoe UI', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, 'SFMono-Regular', Menlo, Consolas, monospace;
  --step--1: .8125rem; --step-0: 1rem; --step-1: 1.25rem; --step-2: 1.6rem; --step-3: 2.4rem;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #0c1018; --surface: #121826; --ink: #e7eaf0; --muted: #98a2b5; --line: #232c3d;
    --accent: #8cb0ff; --accent-soft: #18233a; --code-bg: #0a0e15; --code-ink: #e6e9ef; --code-line: #1c2433;
    --out-bg: #151c2a;
    --get: #4fd1a1; --post: #8cb0ff; --put: #f2b45c; --patch: #b79cff; --delete: #ff8a80; --head: #a3adbf; --any: #a3adbf;
    color-scheme: dark;
  }
}
:root[data-theme="dark"] {
  --bg: #0c1018; --surface: #121826; --ink: #e7eaf0; --muted: #98a2b5; --line: #232c3d;
  --accent: #8cb0ff; --accent-soft: #18233a; --code-bg: #0a0e15; --code-ink: #e6e9ef; --code-line: #1c2433;
  --out-bg: #151c2a;
  --get: #4fd1a1; --post: #8cb0ff; --put: #f2b45c; --patch: #b79cff; --delete: #ff8a80; --head: #a3adbf; --any: #a3adbf;
  color-scheme: dark;
}
* { box-sizing: border-box; }
html { scroll-behavior: smooth; scroll-padding-top: 16px; }
@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } }
body { background: var(--bg); color: var(--ink); font: 400 var(--step-0)/1.65 var(--font-body); margin: 0; }
a { color: var(--accent); text-underline-offset: 3px; }
a:focus-visible, button:focus-visible, input:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; border-radius: 4px; }
code { font-family: var(--font-mono); font-size: .88em; }
p code, td code, li code { background: var(--accent-soft); padding: .1em .35em; border-radius: 4px; }

.shell-wrap { display: grid; grid-template-columns: 272px minmax(0, 1fr); gap: 48px; max-width: 1240px; margin: 0 auto; padding-inline: 24px; }

/* Sidebar index */
.side { position: sticky; top: env(safe-area-inset-top, 0px); align-self: start; max-height: 100vh; overflow-y: auto; padding-block: 28px 40px; }
.brand { display: flex; align-items: baseline; gap: 10px; text-decoration: none; color: var(--ink); }
.brand b { font: 700 1.5rem/1 var(--font-display); letter-spacing: -.02em; }
.brand span { font: 500 var(--step--1) var(--font-mono); color: var(--muted); }
.search { margin-block: 18px 14px; }
.search label { display: block; font-size: var(--step--1); color: var(--muted); margin-bottom: 4px; }
.search input { width: 100%; font: inherit; font-size: .95rem; padding: 8px 10px; border: 1px solid var(--line); border-radius: 8px; background: var(--surface); color: var(--ink); }
.side ul { list-style: none; margin: 0; padding: 0; }
.group { margin-top: 14px; }
.gtitle { display: block; font: 600 var(--step--1)/1.4 var(--font-body); text-transform: uppercase; letter-spacing: .08em; color: var(--muted); text-decoration: none; margin-bottom: 4px; }
.group ul a { display: flex; align-items: center; justify-content: space-between; gap: 8px; padding: 3px 8px; margin-inline: -8px; border-radius: 6px; color: var(--ink); text-decoration: none; font-size: .93rem; }
.group ul a:hover { background: var(--accent-soft); }
.group ul a.on { background: var(--accent-soft); color: var(--accent); font-weight: 600; }
.dot { width: 7px; height: 7px; border-radius: 50%; background: currentColor; flex: none; }
.empty { color: var(--muted); font-size: .9rem; margin-top: 12px; }
.mobile-nav { display: none; }

/* Main column */
main { min-width: 0; padding-block: 28px 96px; }
.hero { padding-block: 20px 36px; border-bottom: 1px solid var(--line); }
.hero .eyebrow { font: 500 var(--step--1) var(--font-mono); color: var(--muted); margin: 0; }
.hero h1 { font: 700 var(--step-3)/1.08 var(--font-display); letter-spacing: -.03em; margin: 10px 0 12px; text-wrap: balance; }
.hero p.lede { font-size: 1.12rem; max-width: 62ch; margin: 0 0 20px; color: var(--muted); }
.chips { display: flex; flex-wrap: wrap; gap: 8px; margin: 0; padding: 0; list-style: none; }
.chips li { font-size: var(--step--1); border: 1px solid var(--line); border-radius: 999px; padding: 3px 10px; background: var(--surface); }
.quick { display: grid; grid-template-columns: minmax(0, 2fr) minmax(0, 5fr); align-items: start; gap: 16px; margin-top: 26px; }
.quick figure { margin: 0; }
.quick > * { min-width: 0; }
.verbs { display: flex; flex-wrap: wrap; gap: 6px; margin: 14px 0 0; }

section.group-sec { padding-top: 40px; }
section.group-sec > h2 { font: 700 var(--step-2)/1.2 var(--font-display); letter-spacing: -.02em; margin: 0 0 4px; text-wrap: balance; }
.item { padding-block: 26px; border-bottom: 1px solid var(--line); max-width: 860px; }
.item:last-child { border-bottom: 0; }
.item > p { max-width: 70ch; margin: 12px 0; }
.item h3 { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; font: 600 var(--step-1)/1.3 var(--font-mono); margin: 0; letter-spacing: -.01em; }
.anchor { color: var(--ink); text-decoration: none; }
.anchor:hover { color: var(--accent); }
.kind { font: 500 .72rem/1 var(--font-body); text-transform: uppercase; letter-spacing: .08em; color: var(--muted); border: 1px solid var(--line); border-radius: 5px; padding: 4px 6px; }
.verb { font: 700 .72rem/1 var(--font-mono); letter-spacing: .04em; padding: 5px 7px; border-radius: 5px; color: var(--surface); }
.v-get { background: var(--get); color: var(--get); } .verb.v-get { color: var(--surface); }
.v-post { background: var(--post); color: var(--post); } .verb.v-post { color: var(--surface); }
.v-put { background: var(--put); color: var(--put); } .verb.v-put { color: var(--surface); }
.v-patch { background: var(--patch); color: var(--patch); } .verb.v-patch { color: var(--surface); }
.v-delete { background: var(--delete); color: var(--delete); } .verb.v-delete { color: var(--surface); }
.v-head, .v-any { background: var(--head); color: var(--head); } .verb.v-head, .verb.v-any { color: var(--surface); }

pre { margin: 0; overflow-x: auto; font: 400 .86rem/1.6 var(--font-mono); tab-size: 2; }
.sig { background: var(--surface); border: 1px solid var(--line); border-radius: 10px; padding: 14px 16px; margin-top: 14px; color: var(--ink); }
.sig .k { color: var(--patch); } .sig .t { color: var(--post); } .sig .s { color: var(--get); } .sig .c { color: var(--muted); } .sig .f { color: var(--ink); font-weight: 600; } .sig .n { color: var(--put); } .sig .a { color: var(--delete); }
figure { margin: 16px 0 0; }
.code { background: var(--code-bg); border-radius: 10px; overflow: hidden; border: 1px solid var(--code-line); }
.code figcaption { display: flex; justify-content: space-between; align-items: center; padding: 7px 10px 7px 16px; border-bottom: 1px solid var(--code-line); font: 500 .72rem/1 var(--font-body); text-transform: uppercase; letter-spacing: .08em; color: var(--hl-c); }
.code pre { padding: 14px 16px; color: var(--code-ink); }
.code .k { color: var(--hl-k); } .code .t { color: var(--hl-t); } .code .s { color: var(--hl-s); } .code .c { color: var(--hl-c); font-style: italic; } .code .f { color: var(--hl-f); } .code .n { color: var(--hl-n); } .code .a { color: var(--hl-a); }
.copy { font: 500 .75rem/1 var(--font-body); color: var(--code-ink); background: transparent; border: 1px solid var(--code-line); border-radius: 6px; padding: 5px 9px; cursor: pointer; }
.copy:hover { border-color: var(--hl-c); }
.out { border: 1px dashed var(--line); border-radius: 10px; background: var(--out-bg); }
.out figcaption { font: 500 .72rem/1 var(--font-body); text-transform: uppercase; letter-spacing: .08em; color: var(--muted); padding: 8px 14px 0; }
.out pre { padding: 8px 14px 12px; color: var(--ink); }

.scroll { overflow-x: auto; margin-top: 14px; border: 1px solid var(--line); border-radius: 10px; background: var(--surface); }
table { border-collapse: collapse; width: 100%; font-size: .92rem; }
th { text-align: left; font: 600 var(--step--1) var(--font-body); text-transform: uppercase; letter-spacing: .06em; color: var(--muted); padding: 9px 12px; border-bottom: 1px solid var(--line); white-space: nowrap; }
td { padding: 9px 12px; border-bottom: 1px solid var(--line); vertical-align: top; }
tr:last-child td { border-bottom: 0; }
td code.p { background: none; padding: 0; font-weight: 600; white-space: nowrap; }
td code.ty { background: none; padding: 0; color: var(--muted); white-space: nowrap; }

footer { color: var(--muted); font-size: .9rem; padding-top: 40px; }
[hidden] { display: none !important; }

@media (max-width: 900px) {
  .shell-wrap { display: block; padding-inline: 16px; }
  .side { display: none; }
  .mobile-nav { display: block; position: sticky; top: env(safe-area-inset-top, 0px); z-index: 2; background: var(--bg); padding-block: 10px; border-bottom: 1px solid var(--line); }
  .mobile-nav details { background: var(--surface); border: 1px solid var(--line); border-radius: 10px; }
  .mobile-nav summary { padding: 10px 14px; cursor: pointer; font-weight: 600; }
  .mobile-nav .inner { max-height: 60vh; overflow-y: auto; padding: 0 14px 14px; }
  .hero h1 { font-size: 1.9rem; }
  .quick { grid-template-columns: minmax(0, 1fr); }
}
'''

JS = r'''
(function () {
  // Copy buttons
  document.querySelectorAll('.copy').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var code = btn.closest('figure').querySelector('pre').innerText;
      var done = function () { btn.textContent = 'Copied'; setTimeout(function () { btn.textContent = 'Copy'; }, 1500); };
      try {
        navigator.clipboard.writeText(code).then(done, function () { select(btn); });
      } catch (e) { select(btn); }
    });
  });
  function select(btn) {
    var range = document.createRange();
    range.selectNodeContents(btn.closest('figure').querySelector('pre'));
    var sel = window.getSelection(); sel.removeAllRanges(); sel.addRange(range);
    btn.textContent = 'Press Ctrl+C';
  }

  // Search filters the index and the page
  function bindSearch(input) {
    input.addEventListener('input', function () {
      var q = input.value.trim().toLowerCase();
      document.querySelectorAll('.search input').forEach(function (other) { if (other !== input) other.value = input.value; });
      document.querySelectorAll('nav .group').forEach(function (group) {
        var any = false;
        group.querySelectorAll('ul a').forEach(function (a) {
          var hit = !q || a.dataset.name.indexOf(q) !== -1;
          a.parentElement.hidden = !hit; if (hit) any = true;
        });
        group.hidden = !any;
      });
      document.querySelectorAll('article.item').forEach(function (art) {
        art.hidden = !!q && art.dataset.name.indexOf(q) === -1 && art.textContent.toLowerCase().indexOf(q) === -1;
      });
      document.querySelectorAll('section.group-sec').forEach(function (sec) {
        sec.hidden = !sec.querySelector('article.item:not([hidden])');
      });
      document.querySelectorAll('.empty').forEach(function (e) {
        e.hidden = !q || !!document.querySelector('nav .group:not([hidden])');
      });
    });
  }
  document.querySelectorAll('.search input').forEach(bindSearch);

  // Close the mobile index after choosing a link
  document.querySelectorAll('.mobile-nav a').forEach(function (a) {
    a.addEventListener('click', function () { a.closest('details').open = false; });
  });

  // Highlight the item in view
  if ('IntersectionObserver' in window) {
    var links = {};
    document.querySelectorAll('.side .group ul a').forEach(function (a) { links[a.getAttribute('href').slice(1)] = a; });
    var obs = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting && links[e.target.id]) {
          Object.keys(links).forEach(function (k) { links[k].classList.remove('on'); });
          links[e.target.id].classList.add('on');
        }
      });
    }, { rootMargin: '0px 0px -75% 0px' });
    document.querySelectorAll('article.item').forEach(function (a) { obs.observe(a); });
  }
})();
'''

FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
         '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
         '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,700'
         '&family=IBM+Plex+Sans:wght@400;500;600&family=JetBrains+Mono:wght@400;500;600;700&display=swap">')


def page_body():
    nav = render_nav()
    sections = '\n'.join(
        f'<section class="group-sec" id="{s["id"]}"><h2>{s["title"]}</h2>'
        + '\n'.join(render_item(it) for it in s['items']) + '</section>'
        for s in SECTIONS
    )
    search = ('<div class="search"><label for="{id}">Find a class or function</label>'
              '<input id="{id}" type="search" placeholder="e.g. retry, upload, cancel" autocomplete="off"></div>')
    count = sum(len(s['items']) for s in SECTIONS)
    hero_code = """final htpio = HtpioClient(baseUrl: 'https://api.example.com');

final res  = await htpio.get('/users/1');
final user = await htpio.get<User>('/users/1', fromJson: User.fromJson);
await htpio.post('/users', data: {'name': 'Ada'});"""
    return f'''
<title>htpio Documentation</title>
<style>{CSS}</style>
{FONTS}
<div class="shell-wrap">
  <aside class="side">
    <a class="brand" href="#top"><b>htpio</b><span>v{VERSION}</span></a>
    {search.format(id='q-side')}
    <nav aria-label="Documentation index"><ul>{nav}</ul></nav>
    <p class="empty" hidden>Nothing matches. Try another word.</p>
  </aside>
  <main id="top">
    <div class="mobile-nav">
      <details><summary>Contents ({count} topics)</summary><div class="inner">
        {search.format(id='q-mobile')}
        <nav aria-label="Documentation index (mobile)"><ul>{nav}</ul></nav>
        <p class="empty" hidden>Nothing matches. Try another word.</p>
      </div></details>
    </div>
    <header class="hero">
      <p class="eyebrow">package:htpio · v{VERSION} · MIT</p>
      <h1>The easy HTTP client for Flutter</h1>
      <p class="lede">Simple requests, typed JSON, interceptors, retry, token refresh, caching, an offline queue, uploads, downloads and mocking, all in one package. Every class and function is on this page with an example you can copy.</p>
      <ul class="chips" aria-label="Supported platforms"><li>Android</li><li>iOS</li><li>Web</li><li>macOS</li><li>Windows</li><li>Linux</li><li>WASM</li></ul>
      <div class="quick">
        <figure class="code shell"><figcaption><span>1 · Install</span><button type="button" class="copy" aria-label="Copy command">Copy</button></figcaption><pre><code>flutter pub add htpio</code></pre></figure>
        <figure class="code"><figcaption><span>2 · Use</span><button type="button" class="copy" aria-label="Copy code">Copy</button></figcaption><pre><code>{highlight(hero_code)}</code></pre></figure>
      </div>
      <div class="verbs" aria-label="HTTP methods">
        <a class="verb v-get" href="#get">GET</a><a class="verb v-post" href="#post">POST</a><a class="verb v-put" href="#put">PUT</a><a class="verb v-patch" href="#patch">PATCH</a><a class="verb v-delete" href="#delete">DELETE</a><a class="verb v-head" href="#head">HEAD</a>
      </div>
    </header>
    {sections}
    <footer>
      <p>htpio {VERSION} · <a href="https://pub.dev/packages/htpio">pub.dev</a> · <a href="https://github.com/TamoorMunawar/htpio">GitHub</a> · <a href="https://github.com/TamoorMunawar/htpio/issues">Report a problem</a></p>
    </footer>
  </main>
</div>
<script>{JS}</script>
'''


def full_page():
    return ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
            '<meta name="description" content="Documentation for htpio, the easy HTTP client for Flutter and Dart.">\n'
            '</head>\n<body>\n' + page_body() + '\n</body>\n</html>\n')


# --------------------------------------------------------------------------
# Example compile check
# --------------------------------------------------------------------------
PRELUDE = '''// GENERATED by tool/docs/build.py --check. Do not edit.
// ignore_for_file: avoid_print, unused_local_variable, unused_element, unused_import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:htpio/htpio.dart';

class _Storage { Future<String?> read(String key) async => null; }
final secureStorage = _Storage();
final htpio = HtpioClient(baseUrl: 'https://api.example.com');
'''


def check_file(path):
    top, body, standalone = [], [], []
    user_defined = False
    for s in SECTIONS:
        for it in s['items']:
            for key in ('code', 'code2'):
                code = it.get(key)
                if not code or code.startswith('import '):
                    continue
                if it.get('standalone'):
                    standalone.append((it['id'], code))
                elif it.get('top') and key == 'code':
                    if 'class User ' in code:
                        user_defined = True
                    top.append(f'// --- {it["id"]}\n{code}\n')
                else:
                    body.append(f'// --- {it["id"]} ({key})\n{{\n{code}\n}}\n')
    assert user_defined
    fn = ('Future<void> _examples(String token, String refreshToken, String text, String url, '
          'File file, Directory dir, List<int> pickedBytes) async {\n' + '\n'.join(body) + '\n}\n')
    src = PRELUDE.replace("import 'package:htpio/htpio.dart';",
                          "import 'dart:io';\nimport 'package:htpio/htpio.dart';") + '\n'.join(top) + '\n' + fn
    with open(path, 'w') as f:
        f.write(src)
    for name, code in standalone:
        with open(path.replace('.dart', f'_{name.replace("-", "_")}.dart'), 'w') as f:
            f.write('// GENERATED by tool/docs/build.py --check. Do not edit.\n' + code + '\n')


if __name__ == '__main__':
    if len(sys.argv) == 3 and sys.argv[1] == '--check':
        check_file(sys.argv[2])
    elif len(sys.argv) == 3 and sys.argv[1] == '--fragment':
        with open(sys.argv[2], 'w') as f:
            f.write(page_body())
    else:
        os.makedirs(os.path.join(ROOT, 'docs'), exist_ok=True)
        with open(os.path.join(ROOT, 'docs', 'index.html'), 'w') as f:
            f.write(full_page())
        print('wrote docs/index.html')
