"""Build a dependency-free GitHub Pages guide from executed R examples."""
import html
import json
import shutil
import csv
from pathlib import Path

root = Path(__file__).resolve().parents[1]
data = json.loads((root / "output/scientific-audit/guide.json").read_text(encoding="utf-8"))
docs = root / "docs"
fence = chr(96) * 3
setup = 'source("tools/example-cases.R")\nload_drdesign()'
esc = lambda value: html.escape(str(value if value is not None else "NA"))


def rows(value):
    return value if isinstance(value, list) else [value]


def table(value):
    value = rows(value) if value else []
    if not value:
        return '<p class="muted">No rows to report.</p>'
    columns = list(value[0])
    head = "".join(f'<th scope="col">{esc(x)}</th>' for x in columns)
    body = "".join("<tr>" + "".join(f"<td>{esc(r.get(c))}</td>" for c in columns) + "</tr>" for r in value)
    return f'<div class="table-scroll" tabindex="0"><table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table></div>'


def markdown_table(value):
    value = rows(value) if value else []
    if not value:
        return "No rows to report."
    columns = list(value[0])
    cell = lambda v: str(v if v is not None else "NA").replace("|", r"\|").replace("\n", " ")
    result = ["| " + " | ".join(columns) + " |", "| " + " | ".join(["---"] * len(columns)) + " |"]
    result += ["| " + " | ".join(cell(r.get(c)) for c in columns) + " |" for r in value[:10]]
    if len(value) > 10:
        result += ["", "First 10 rows shown. Download the CSV for every row."]
    return "\n".join(result)


def nav(prefix=""):
    content = f'<nav aria-label="Guide sections"><a class="brand" href="{prefix}index.html">DrDesign<span>Research guide</span></a>'
    for group, keys in data["groups"].items():
        content += f"<details open><summary>{esc(group)}</summary>"
        content += "".join(f'<a href="{prefix}examples/{key}.html">{esc(data["modules"][key]["label"])}</a>' for key in keys)
        content += "</details>"
    return content + f'<a href="{prefix}validation.html">Validation & reporting</a></nav>'


def page(title, content, prefix=""):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{esc(title)} | DrDesign</title><link rel="stylesheet" href="{prefix}assets/guide.css"></head><body><a class="skip" href="#main">Skip to content</a>{nav(prefix)}<main id="main">{content}<footer>DrDesign · Saurav Singla · Example calculations regenerated from source. <a href="https://github.com/s00singla/DrDesign">Source repository</a>.</footer></main></body></html>'


cards = []
readme = ["# DrDesign research guide", "", "Start with the [data preparation tutorial](examples/data-preparation.md).", ""]
for group, keys in data["groups"].items():
    readme += [f"## {group}", ""]
    for key in keys:
        spec = data["modules"][key]
        notes = data["notes"][key]
        examples = {k: v for k, v in data["examples"].items() if v["module"] == key}
        assert examples and len(notes) == 4
        readme.append(f'- [{spec["label"]}](examples/{key}.md)')
        cards.append(f'<a class="card" data-search="{esc((spec["label"]+" "+spec["description"]).lower())}" href="examples/{key}.html"><h3>{esc(spec["label"])}</h3><p>{esc(spec["description"])}</p><span>{len(examples)} worked examples →</span></a>')
        content = f'<header><p class="eyebrow">Worked analysis · {len(examples)} executable examples</p><h1>{esc(spec["label"])}</h1><p class="lede">{esc(notes[0])}</p></header><section><h2>Question and data</h2><p>{esc(notes[1])}</p><h2>Read and report the results</h2><p>{esc(notes[2])}</p><aside><h3>Scope and assumptions</h3><p>{esc(notes[3])}</p></aside><h2>Run the examples</h2><p>From the repository root, restore the locked dependencies and load the app functions. These are source-checkout examples, not an installed package API.</p><pre><code>{esc(setup)}</code></pre><p>In Shiny, select this module from its workflow heading, upload the example CSV, map the columns, review observations and run. Each R example states the analysis options to reproduce.</p></section>'
        md = [f'# {spec["label"]}', "", notes[0], "", "## Question and data", notes[1], "", "## Read and report the results", notes[2], "", "## Scope and assumptions", notes[3], "", "## Setup", fence+"r", setup, fence]
        rmd = ["---", f'title: "{spec["label"]}"', "output:", "  html_document:", "    toc: true", "---", "", notes[0], "", "## Question and data", notes[1], "", "## Reporting and assumptions", notes[2], "", notes[3], "", fence+'{r setup, include=FALSE}', 'roots <- c(".","..","../..")', 'root <- roots[file.exists(file.path(roots,"tools","example-cases.R"))][1]', 'stopifnot(!is.na(root))', 'knitr::opts_knit$set(root.dir=normalizePath(root))', fence, "", fence+'{r load, message=FALSE, warning=FALSE}', setup, fence]
        for identifier, example in examples.items():
            code = example["code"]
            (docs / "code" / f"{identifier}.R").write_text("# Run from the DrDesign repository root.\n"+setup+"\n"+code+"\n", encoding="utf-8")
            content += f'<section id="{identifier}"><h2>{esc(identifier)}</h2><p><a class="button" href="../data/{identifier}.csv" download>Example CSV</a><a href="../code/{identifier}.R" download>R script</a></p><p class="muted">Synthetic teaching data; not evidence from a field experiment.</p><h3>Input</h3>{table(example["input"])}<p class="muted">Showing up to 8 of {example["rows"]} observations. The CSV contains every row.</p><h3>Analysis</h3><pre><code>{esc(code)}</code></pre><h3>Computed output</h3>'
            md += ["", f"## {identifier}", "", f"[Example CSV](../data/{identifier}.csv) · [R script](../code/{identifier}.R)", "", "Synthetic teaching data; not observations from a field experiment.", "", fence+"r", code, fence]
            rmd += ["", f"## {identifier}", "", "Synthetic teaching data.", "", fence+f'{{r {identifier}, message=FALSE, warning=TRUE}}', code, fence, "", fence+f'{{r {identifier}-tables, echo=FALSE, results="asis"}}', "tables <- example_tables(result)", 'for (nm in names(tables)) {', '  cat("\\n\\n### ",nm,"\\n\\n",sep="")', '  report_kable(tables[[nm]])', "}", fence, "", fence+f'{{r {identifier}-plots, echo=FALSE}}', 'for (p in example_plots(result)) { if (is.function(p)) p() else print(p) }', fence]
            for number, (name, values) in enumerate(example["tables"].items(), 1):
                filename = f"{identifier}-table-{number}.csv"
                count = len(values) if isinstance(values, list) else 1
                content += f'<details class="output"{" open" if number == 1 else ""}><summary>{esc(name)} <span>{count} rows</span></summary><p><a href="../data/{filename}" download>Full-precision CSV</a></p>{table(values)}</details>'
                md += ["", f"### {name}", "", f"[Full-precision CSV](../data/{filename})", "", markdown_table(values)]
                table_notes = example.get("table_notes", {}).get(name, [])
                for note in rows(table_notes) if table_notes else []:
                    content += f'<p class="muted">{esc(note)}</p>'
                    md += ["", str(note)]
            if isinstance(example["plots"], dict):
                for name, filename in example["plots"].items():
                    path = root / filename
                    shutil.copy2(path, docs / "assets" / path.name)
                    content += f'<figure><img loading="lazy" src="../assets/{path.name}" alt="{esc(name)}"><figcaption>{esc(name)}</figcaption></figure>'
                    md += ["", f"![{name}](../assets/{path.name})"]
            notes_out = example.get("diagnostics")
            if notes_out:
                content += '<aside><h3>Example diagnostics and model notes</h3><ul>'+"".join(f"<li>{esc(x)}</li>" for x in rows(notes_out))+"</ul></aside>"
                md += ["", "### Diagnostics and model notes", ""]+["- "+x for x in rows(notes_out)]
            content += "</section>"
        content += f'<section><h2>Reporting conventions</h2><p>{esc(data["conventions"])}</p><p><a href="../validation.html">Validation record and limitations</a>.</p></section>'
        (docs / "examples" / f"{key}.html").write_text(page(spec["label"], content, "../"), encoding="utf-8")
        (docs / "examples" / f"{key}.md").write_text("\n".join(md+["", "## Reporting conventions", data["conventions"], "", "[Validation and limitations](../VALIDATION.md)"])+"\n", encoding="utf-8")
        (root / "vignettes/articles" / f"{key}.Rmd").write_text("\n".join(rmd)+"\n", encoding="utf-8")
    readme.append("")

landing = '<header><p class="eyebrow">Agricultural experiments · Plant breeding · Reproducible reporting</p><h1>From fieldbook<br>to defensible results.</h1><p class="lede">A practical guide to DrDesign. Start with the design, run a worked example, examine the results and report the analysis with its assumptions.</p><a class="button" href="examples/data-preparation.html">Start with your data</a><a href="validation.html">Review the validation</a></header><section class="intro-grid"><div><h2>One workflow, three records</h2><p>Retain the input data, analysis settings and complete output. These examples link all three and can be rerun from the source checkout.</p></div><div><h2>Built for careful interpretation</h2><p>Estimated means, uncertainty and model diagnostics travel together. A small p-value does not replace a sound experimental design.</p></div></section><section><h2>Choose your analysis</h2><label for="search">Find an example</label><input id="search" type="search" placeholder="Try: split plot, heritability, PCA…"><div class="cards">'+"".join(cards)+'</div></section><section><h2>Run the Shiny application</h2><pre><code>renv::restore()\nshiny::runApp(".")</code></pre><p>Use R 4.5.3 for the validated dependency lock. On this Windows workspace, tools/run-local.ps1 selects it explicitly. The repository is currently a source-based Shiny suite; a future installable package will expose a dedicated app launcher.</p><h2>About this guide</h2><p>Prepared for DrDesign, authored by Saurav Singla. Organization is inspired by the example-led <a href="https://tiagoolivoto.github.io/metan/">metan documentation by Tiago Olivoto</a>; the DrDesign explanations and examples are original. Underlying statistical packages are credited in the validation notes.</p></section><script>document.getElementById("search").addEventListener("input",function(){const q=this.value.toLowerCase();document.querySelectorAll(".card").forEach(c=>c.hidden=!c.dataset.search.includes(q));});</script>'
(docs / "index.html").write_text(page("Research guide", landing), encoding="utf-8")
(docs / ".nojekyll").write_text("")
readme += ["## Rebuild", "", fence+"r", 'source("tests/scientific-audit.R")', 'source("tools/prepare-guide.R")', fence, "", fence+"sh", "python tools/build-guide.py", fence, "", "Open docs/index.html for the styled site. To publish with GitHub Pages, select the reviewed branch and /docs folder in repository Pages settings. This build does not publish the repository or claim a live URL.", "", "Vignette sources are in vignettes/articles/. They currently load source-checkout functions; replace the setup with exported package functions when packaging is completed.", "", "[Validation and limitations](VALIDATION.md)"]
(docs / "README.md").write_text("\n".join(readme)+"\n", encoding="utf-8")
for filename in ["checks.csv", "inventory.csv", "session-info.txt"]:
    shutil.copy2(root / "output/scientific-audit" / filename, docs / "data" / filename)
changes = [
    "Corrected two-sample and paired t-test differences and aligned one-sample confidence intervals with the difference from the null mean.",
    "Separated display rounding from calculation. Small p-values are displayed as <0.001 and raw values retain numerical precision.",
    "Used the fitted error and t limits for CRD/RCBD mean intervals.",
    "Retained full interactions rather than selecting an additive model from a preliminary interaction test.",
    "Corrected split-plot SE(d) labels, column mapping, balanced-design validation and cross-stratum approximate degrees of freedom.",
    "Disabled silent AMMI/GGE imputation and automatic substitute stability formulas.",
    "Stopped discarding nonpositive values in harmonic stability calculations.",
    "Replaced generic genetic BLUP limits with clearly labelled conditional genotypic-effect intervals.",
    "Corrected report section titles, removed duplicate tables, repeated PDF headers and preserved literal formula labels in Word.",
]
refs = [
    ("R t-test definitions", "https://stat.ethz.ch/R-manual/R-devel/library/stats/html/t.test.html"),
    ("emmeans comparisons and contrasts", "https://rvlenth.github.io/emmeans/articles/comparisons.html"),
    ("metan models and examples", "https://tiagoolivoto.github.io/metan/"),
    ("agricolae experimental designs", "https://cran.r-project.org/package=agricolae"),
    ("SpATS spatial analysis", "https://cran.r-project.org/package=SpATS"),
    ("DiallelAnalysisR", "https://cran.r-project.org/package=DiallelAnalysisR"),
    ("Generation-mean parameterization in a published analysis", "https://academicjournals.org/journal/JPBCS/article-full-text/A8E7C2D53630"),
]
validation = f'<header><p class="eyebrow">Quality record · 27 October 2026</p><h1>Validation and reporting</h1><p class="lede">{len(data["checks"])} checks across {len(data["examples"])} executable cases. See what was tested and where the conclusions stop.</p></header><section><h2>Evidence</h2><p><a href="data/checks.csv">Check results</a> · <a href="data/inventory.csv">Output inventory</a> · <a href="data/session-info.txt">R and package versions</a></p>{table(data["checks"])}<h2>What a pass means</h2><p>The audit combines independent scalar, matrix, ANOVA and SVD calculations, integration tests, edge cases and checks on generated tables and figures. A shared-library comparison verifies integration; it is not an independent implementation of REML, SpATS or MGIDI. Rendering checks do not prove that every possible dataset produces an interpretable graphic.</p><p>These results support the documented examples and assumptions. They do not establish universal correctness or replace methodological review before publication. Each inventory row records the scope of the check.</p><h2>Corrections in this review</h2><ul>'+"".join(f"<li>{esc(x)}</li>" for x in changes)+f'</ul><h2>Reporting conventions</h2><p>{esc(data["conventions"])}</p><p>SS and MS denote sums and mean squares. Mixed-model denominator df may be noninteger. Raw CSVs retain original field identifiers and precision. Wide Word/PDF tables repeat a table-row key so compound identifiers remain traceable. Preserve model notes and comparison adjustments with the results.</p><h2>Primary method documentation</h2><ul>'+"".join(f'<li><a href="{url}">{esc(label)}</a></li>' for label, url in refs)+"</ul></section>"
(docs / "validation.html").write_text(page("Validation", validation), encoding="utf-8")
(docs / "VALIDATION.md").write_text("\n".join(["# Validation record", "", "27 October 2026.", "", f'{len(data["checks"])} checks across {len(data["examples"])} executable cases passed.', "", "[Check results](data/checks.csv) · [Output inventory](data/inventory.csv) · [Package versions](data/session-info.txt)", "", "Independent formula checks, integration checks and rendering checks have different evidential strength. These examples do not certify every possible dataset. Inspect experimental assumptions and model diagnostics before publication.", "", "## Corrections", ""]+["- "+x for x in changes]+["", "## Reporting conventions", data["conventions"], "", "## References", ""]+[f"- [{label}]({url})" for label, url in refs])+"\n", encoding="utf-8")
qa_sources = [
    ("Research and interface checks", "output/research-tests/checks.csv", "research-checks.csv"),
    ("Legacy module checks", "output/module-audit-results.csv", "module-checks.csv"),
    ("Runnable vignette articles", "output/vignette-checks/checks.csv", "vignette-checks.csv"),
    ("Word table value checks", "output/scientific-audit/word-content-checks.csv", "word-content-checks.csv"),
    ("PDF page boundary checks", "output/scientific-audit/pdf-layout-checks.csv", "pdf-layout-checks.csv"),
]
qa = []
for label, source, filename in qa_sources:
    source_path = root/source
    if not source_path.exists():
        continue
    with source_path.open(encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    assert records and all(row["Result"] == "PASS" for row in records), f"Failed QA record: {source}"
    shutil.copy2(source_path, docs/"data"/filename)
    qa.append((label, len(records), filename))
if qa:
    extra = '<section><h2>Additional verification</h2><ul>' + "".join(f'<li><a href="data/{name}">{esc(label)}</a>: {count} passed</li>' for label, count, name in qa) + '</ul><p>Page boundary and text checks complement representative visual review; they do not certify every possible export layout.</p></section>'
    (docs/"validation.html").write_text(page("Validation", validation+extra), encoding="utf-8")
    with (docs/"VALIDATION.md").open("a", encoding="utf-8") as stream:
        stream.write("\n## Additional verification\n\n" + "\n".join(f"- [{label}](data/{name}): {count} passed" for label, count, name in qa) + "\n")
print(f'Built {len(cards)} module articles with {len(data["examples"])} executable examples.')
