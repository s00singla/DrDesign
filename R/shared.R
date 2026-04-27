library(shiny)
library(htmltools)
library(readxl)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || identical(x, "")) y else x
}

app_catalog <- list(
  list(key = "portal", label = "Portal", path = "/"),
  list(key = "design-analyzer", label = "Design Analyzer", path = "/design-analyzer/"),
  list(key = "crd-rbd", label = "CRD / RBD", path = "/crd-rbd/"),
  list(key = "factorial-design", label = "Factorial Design", path = "/factorial-design/"),
  list(key = "pooled-anova", label = "Pooled ANOVA", path = "/pooled-anova/"),
  list(key = "split-plot", label = "Split Plot", path = "/split-plot/"),
  list(key = "correlation-regression", label = "Correlation & Regression", path = "/correlation-regression/"),
  list(key = "descriptive-statistics", label = "Descriptive Statistics", path = "/descriptive-statistics/"),
  list(key = "compare-means", label = "Compare Means", path = "/compare-means/")
)

local_app_catalog <- list(
  list(key = "portal", label = "Portal", path = "./"),
  list(key = "design-analyzer", label = "Design Analyzer", path = "?app=design-analyzer"),
  list(key = "crd-rbd", label = "CRD / RBD", path = "?app=crd-rbd"),
  list(key = "factorial-design", label = "Factorial Design", path = "?app=factorial-design"),
  list(key = "pooled-anova", label = "Pooled ANOVA", path = "?app=pooled-anova"),
  list(key = "split-plot", label = "Split Plot", path = "?app=split-plot"),
  list(key = "correlation-regression", label = "Correlation & Regression", path = "?app=correlation-regression"),
  list(key = "descriptive-statistics", label = "Descriptive Statistics", path = "?app=descriptive-statistics"),
  list(key = "compare-means", label = "Compare Means", path = "?app=compare-means")
)

research_station_styles <- HTML("
  body { background: linear-gradient(180deg, #eef4ef 0%, #f8f5ec 100%); color: #21352b; font-family: 'Segoe UI', Tahoma, sans-serif; }
  .station-hero { background: linear-gradient(135deg, #1f4d3b 0%, #547d43 100%); color: #fff; padding: 28px 30px; border-radius: 18px; margin-bottom: 20px; box-shadow: 0 18px 40px rgba(31, 77, 59, 0.18); }
  .station-hero h1, .station-hero h2 { margin-top: 0; font-weight: 700; }
  .station-nav { display: flex; gap: 10px; flex-wrap: wrap; margin: 16px 0 22px; }
  .station-nav a { display: inline-block; padding: 9px 14px; border-radius: 999px; text-decoration: none; background: #dfe9df; color: #244130; font-weight: 600; }
  .station-nav a.active { background: #244130; color: #fff; }
  .station-panel { background: rgba(255,255,255,0.92); border-radius: 18px; padding: 20px; box-shadow: 0 12px 35px rgba(48, 60, 50, 0.08); margin-bottom: 18px; }
  .station-card { background: rgba(255,255,255,0.92); border-radius: 18px; padding: 18px; min-height: 220px; box-shadow: 0 12px 35px rgba(48, 60, 50, 0.08); margin-bottom: 18px; }
  .station-muted { color: #56675d; font-size: 13px; }
  .station-help { background: #f3f8f1; border-left: 5px solid #547d43; padding: 12px 14px; border-radius: 12px; margin-bottom: 14px; }
  .btn-primary, .btn-success { border: 0; border-radius: 12px; font-weight: 600; }
")

nav_links <- function(active_key, catalog = app_catalog) {
  tags$div(
    class = "station-nav",
    lapply(catalog, function(app) {
      tags$a(class = if (identical(active_key, app$key)) "active" else "", href = app$path, app$label)
    })
  )
}

station_page <- function(title, subtitle, active_key, sidebar, body, nav_catalog = app_catalog) {
  fluidPage(
    tags$head(tags$style(research_station_styles)),
    div(class = "station-hero", h1(title), p(subtitle, class = "lead"), nav_links(active_key, nav_catalog)),
    fluidRow(column(4, div(class = "station-panel", sidebar)), column(8, body))
  )
}

analysis_tabs <- function(...) {
  div(class = "station-panel", tabsetPanel(...))
}

normalize_columns <- function(df) {
  names(df) <- trimws(names(df))
  df
}

read_pasted_table <- function(text) {
  text <- trimws(text)
  validate(need(nchar(text) > 0, "Paste a table or upload a file to continue."))
  try_tab <- tryCatch(read.table(text = text, header = TRUE, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
  if (!is.null(try_tab) && ncol(try_tab) > 1) {
    return(normalize_columns(try_tab))
  }
  try_csv <- tryCatch(read.csv(text = text, stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
  validate(need(!is.null(try_csv), "The pasted data could not be parsed as tabular text."))
  normalize_columns(try_csv)
}

read_uploaded_table <- function(path) {
  ext <- tolower(tools::file_ext(path))
  df <- switch(
    ext,
    csv = read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    txt = read.delim(path, stringsAsFactors = FALSE, check.names = FALSE),
    tsv = read.delim(path, stringsAsFactors = FALSE, check.names = FALSE),
    xlsx = as.data.frame(readxl::read_excel(path), stringsAsFactors = FALSE),
    xls = as.data.frame(readxl::read_excel(path), stringsAsFactors = FALSE),
    stop("Unsupported upload type. Use CSV, TSV, TXT, XLS, or XLSX.")
  )
  normalize_columns(df)
}

read_dataset_input <- function(file_input, pasted_text) {
  if (!is.null(file_input) && nzchar(file_input$datapath)) {
    return(read_uploaded_table(file_input$datapath))
  }
  read_pasted_table(pasted_text)
}

metrics_table <- function(named_values, digits = 4) {
  values <- unname(unlist(named_values))
  data.frame(Metric = names(named_values), Value = ifelse(is.numeric(values), round(values, digits), as.character(values)), stringsAsFactors = FALSE)
}

save_html_report <- function(title, sections, file) {
  section_tags <- lapply(sections, function(section) {
    div(
      h3(section$title),
      if (!is.null(section$subtitle)) p(section$subtitle, class = "station-muted"),
      if (!is.null(section$table)) tags$table(
        class = "table table-bordered table-striped",
        tags$thead(tags$tr(lapply(names(section$table), tags$th))),
        tags$tbody(lapply(seq_len(nrow(section$table)), function(i) tags$tr(lapply(section$table[i, , drop = FALSE], function(cell) tags$td(as.character(cell))))))
      ),
      if (!is.null(section$text)) p(section$text)
    )
  })

  htmltools::save_html(
    tagList(
      tags$html(
        tags$head(
          tags$title(title),
          tags$style("body { font-family: 'Segoe UI', Tahoma, sans-serif; margin: 32px; color: #1f2d22; } h1, h2, h3 { color: #244130; } .table { border-collapse: collapse; width: 100%; margin-bottom: 24px; } .table th, .table td { border: 1px solid #cdd8d0; padding: 8px 10px; text-align: left; } .table th { background: #edf3eb; } .station-muted { color: #5a6a5e; }")
        ),
        tags$body(h1(title), p(sprintf("Generated on %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")), class = "station-muted"), section_tags)
      )
    ),
    file = file
  )
}

build_help_box <- function(title, lines) {
  div(class = "station-help", tags$b(title), tags$ul(lapply(lines, tags$li)))
}
