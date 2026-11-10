"""Check PDF text stays on the page; visual review is still required."""
import csv
from pathlib import Path
import pdfplumber

root = Path(__file__).resolve().parents[1]
paths = list((root/"output/legacy-reports").glob("*.pdf")) + list((root/"output/research-reports").glob("*.pdf"))
checks = []
for path in paths:
    outside = []
    markup = []
    with pdfplumber.open(path) as pdf:
        for number, page in enumerate(pdf.pages, 1):
            text = page.extract_text() or ""
            if r"\begin{longtable}" in text:
                markup.append(number)
            for word in page.extract_words():
                if word["x0"] < -1 or word["x1"] > page.width+1 or word["top"] < -1 or word["bottom"] > page.height+1:
                    outside.append((number, word["text"]))
        checks.append([str(path.relative_to(root)), len(pdf.pages), "PASS" if not outside and not markup else repr((outside, markup))])
with (root/"output/scientific-audit/pdf-layout-checks.csv").open("w", newline="") as output:
    writer = csv.writer(output)
    writer.writerow(["Report", "Pages", "Result"])
    writer.writerows(checks)
failures = [row for row in checks if row[2] != "PASS"]
for row in failures:
    print(row)
assert len(checks) == 27, "Expected 10 legacy and 17 research reports."
assert not failures, "PDF layout check failed."
print(f"PASS: {len(checks)} reports, {sum(row[1] for row in checks)} pages within page boundaries.")
