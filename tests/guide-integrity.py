"""Check every local target in the generated GitHub Pages guide."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

root = Path(__file__).resolve().parents[1] / "docs"
failures = []
links = 0

class Targets(HTMLParser):
    def handle_starttag(self, tag, attrs):
        global links
        for name, value in attrs:
            if name not in ("href", "src") or not value:
                continue
            url = urlsplit(value)
            if url.scheme or url.netloc or not url.path:
                continue
            links += 1
            target = (self.path.parent / unquote(url.path)).resolve()
            if not target.is_file():
                failures.append(f"{self.path.name}: missing {value}")

for path in root.rglob("*.html"):
    parser = Targets()
    parser.path = path
    content = path.read_text(encoding="utf-8")
    assert not any(ord(c) < 32 and c not in "\n\r\t" for c in content), f"Invalid control character in {path}"
    parser.feed(content)
assert len(list((root / "examples").glob("*.html"))) == 23
assert len(list((root / "code").glob("*.R"))) == 52
assert "Heterosis is 100 \u00d7 (hybrid/reference \u2212 1)" in (root/"examples/heterosis.html").read_text(encoding="utf-8")
assert not failures, "\n".join(failures)
print(f"PASS: {links} local links/assets across 25 HTML pages; 23 modules and 52 scripts.")
