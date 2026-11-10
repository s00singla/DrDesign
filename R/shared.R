library(shiny)
library(htmltools)
library(readxl)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || identical(x, "")) y else x
}

registry_candidates <- file.path(c(".", "..", "../.."), "R", "module_registry.R")
registry_path <- registry_candidates[file.exists(registry_candidates)][1]
if (is.na(registry_path)) stop("Cannot locate the DrDesign module registry.")
source(registry_path, local = TRUE)
source(file.path(dirname(registry_path),"reporting.R"), local = TRUE)
app_catalog <- module_catalog()
local_app_catalog <- app_catalog
research_station_styles <- HTML("
  body { background: linear-gradient(180deg, #eef4ef 0%, #f8f5ec 100%); color: #21352b; font-family: 'Segoe UI', Tahoma, sans-serif; }
  .station-hero { background: linear-gradient(135deg, #1f4d3b 0%, #547d43 100%); color: #fff; padding: 28px 30px; border-radius: 18px; margin-bottom: 20px; box-shadow: 0 18px 40px rgba(31, 77, 59, 0.18); }
  .station-hero h1, .station-hero h2 { margin-top: 0; font-weight: 700; }
  .station-nav { display: flex; gap: 10px; flex-wrap: wrap; margin: 16px 0 22px; }
  .station-nav a { display: inline-block; padding: 9px 14px; border-radius: 999px; text-decoration: none; background: #dfe9df; color: #244130; font-weight: 600; }
  .station-nav a.active { background: #244130; color: #fff; }
  .station-nav { align-items: flex-start; margin-bottom: 0; }
  .station-nav details { position: relative; color: #21352b; }
  .station-nav summary { cursor: pointer; padding: 9px 14px; background: #dfe9df; border-radius: 9px; font-weight: 600; }
  .station-nav .nav-current summary { background: #fff; box-shadow: inset 0 -3px #a4bf79; }
  .station-nav .nav-menu { position: absolute; top: 44px; left: 0; min-width: 240px; z-index: 1000; padding: 8px; background: white; border: 1px solid #ccd9cf; border-radius: 10px; box-shadow: 0 8px 24px #19362430; }
  .station-nav .nav-menu a { display: block; border-radius: 5px; background: white; font-weight: 400; }
  .station-nav .nav-menu a:hover, .station-nav .nav-menu a:focus { background: #edf3ea; }
  .station-nav .nav-menu a.active { background: #244130; color: white; }
  table { font-variant-numeric: tabular-nums; }
  .report-note { color: #536258; font-size: 12px; margin: 10px 0; }
  @media(max-width: 700px) { .station-hero { padding: 18px; } .station-nav .nav-menu { position: static; min-width: 0; } }
  .station-panel { background: rgba(255,255,255,0.92); border-radius: 18px; padding: 20px; box-shadow: 0 12px 35px rgba(48, 60, 50, 0.08); margin-bottom: 18px; }
  .station-card { background: rgba(255,255,255,0.92); border-radius: 18px; padding: 18px; min-height: 220px; box-shadow: 0 12px 35px rgba(48, 60, 50, 0.08); margin-bottom: 18px; }
  .station-muted { color: #56675d; font-size: 13px; }
  .station-help { background: #f3f8f1; border-left: 5px solid #547d43; padding: 12px 14px; border-radius: 12px; margin-bottom: 14px; }
  .btn-primary, .btn-success { border: 0; border-radius: 12px; font-weight: 600; }
  .output-section { background: #ffffff; border: 1px solid #dce6de; border-radius: 14px; padding: 16px 18px; margin-top: 14px; margin-bottom: 16px; box-shadow: 0 4px 14px rgba(31, 77, 59, 0.04); overflow-x: auto; }
  .output-section-title { font-size: 15px; font-weight: 700; color: #1f4d3b; margin: 0 0 10px 0; padding-bottom: 6px; border-bottom: 2px solid #eef4ef; }
  .output-section-subtitle { margin: -4px 0 10px 0; }
  .station-panel .nav-tabs { border-bottom: 2px solid #dce6de; margin-bottom: 14px; }
  .station-panel .nav-tabs > li > a { color: #244130; font-weight: 600; border-radius: 10px 10px 0 0; padding: 10px 16px; }
  .station-panel .nav-tabs > li.active > a, .station-panel .nav-tabs > li.active > a:hover, .station-panel .nav-tabs > li.active > a:focus { color: #1f4d3b; background-color: #f3f8f1; border-color: #dce6de #dce6de transparent; border-bottom: 3px solid #244130; }
  .station-panel .shiny-html-output { overflow-x: auto; }
  .station-panel table.table { width: 100%; border-collapse: collapse; border-top: 2px solid #244130; border-bottom: 2px solid #244130; margin-bottom: 10px; font-size: 13.5px; }
  .station-panel table.table thead th { background: #f2f7f2; color: #1f4d3b; font-weight: 700; border-bottom: 1.5px solid #8ba88e; padding: 8px 10px; white-space: nowrap; }
  .station-panel table.table tbody td { padding: 7px 10px; border-top: 1px solid #e4ece5; vertical-align: middle; }
  .station-panel table.table tbody tr:hover { background-color: #f8fbf8; }
  .station-panel table.table th[align='right'], .station-panel table.table td[align='right'] { text-align: right; }
  .station-panel table.table caption { caption-side: bottom; color: #56675d; font-size: 12px; padding-top: 6px; text-align: left; }
  .station-panel pre.shiny-text-output { background: #f6faf6; border: 1px solid #d5e3d7; border-left: 4px solid #547d43; border-radius: 10px; padding: 12px 14px; font-size: 13px; color: #21352b; white-space: pre-wrap; margin-top: 8px; }
")

nav_links <- function(active_key, catalog = app_catalog) {
  by_key <- setNames(catalog,vapply(catalog,`[[`,character(1),"key"))
  link <- function(key) {app<-by_key[[key]];if(is.null(app)) return(NULL);tags$a(class=if(identical(active_key,key)) "active" else "",href=app$path,`aria-current`=if(identical(active_key,key)) "page" else NULL,app$label)}
  tags$nav(class="station-nav",`aria-label`="Analysis workflows",link("portal"),
    lapply(names(module_groups),function(group) tags$details(class=if(active_key %in% module_groups[[group]]) "nav-current" else "",
      tags$summary(group),tags$div(class="nav-menu",lapply(module_groups[[group]],link)))))
}

station_page <- function(title, subtitle, active_key, sidebar, body, nav_catalog = app_catalog) {
  fluidPage(
    tags$head(tags$style(research_station_styles)),
    div(class = "station-hero", h1(title), p(subtitle, class = "lead"), nav_links(active_key, nav_catalog)),
    fluidRow(column(4, div(class = "station-panel", sidebar)), column(8, tags$p(class="report-note",reporting_note()),body))
  )
}

analysis_tabs <- function(...) {
  div(class = "station-panel", tabsetPanel(...))
}

output_section <- function(title = NULL, ..., subtitle = NULL) {
  div(
    class = "output-section",
    if (!is.null(title) && nzchar(title)) tags$h4(class = "output-section-title", title),
    if (!is.null(subtitle) && nzchar(subtitle)) tags$p(class = "station-muted output-section-subtitle", subtitle),
    ...
  )
}

normalize_columns <- function(df) {
  names(df) <- trimws(names(df))
  if (any(!nzchar(names(df))) || anyDuplicated(names(df))) stop("Column names must be nonempty and unique.")
  df
}

safe_model_formula <- function(response, predictors) {
  rhs <- Reduce(function(a, b) call("+", a, b), lapply(predictors, as.name))
  as.formula(call("~", as.name(response), rhs), env = parent.frame())
}

capture_analysis_health <- function(fun) {
  force(fun)
  function(...) {
    notes <- character()
    result <- withCallingHandlers(fun(...), warning = function(w) {
      notes <<- c(notes, conditionMessage(w)); invokeRestart("muffleWarning")
    }, message = function(m) {
      if (grepl("singular|converg|misleading|estimab", conditionMessage(m), ignore.case = TRUE)) notes <<- c(notes, conditionMessage(m))
    })
    if (is.list(result)) {
      result$warnings <- unique(c(result$warnings, notes))
      result$model_status <- if (length(result$warnings)) "Review diagnostics" else "Completed"
      if (length(result$warnings)) result$report_note <- paste(result$report_note, "Diagnostics:", paste(result$warnings, collapse = " | "))
    }
    result
  }
}

# Event-driven analyses retain their snapshot, but cannot export stale results.
stable_input_signature <- function(inputs, ignored = character(), pattern = "^$") {
  signature <- shiny::reactiveVal(NULL)
  shiny::observe({
    values <- shiny::reactiveValuesToList(inputs)
    values <- values[!names(values) %in% ignored & !grepl(pattern,names(values))]
    values <- values[sort(names(values))]
    # reactiveVal suppresses identical updates. Without this boundary, newly
    # created table controls repeatedly invalidate and rebuild their own UI.
    signature(serialize(values,NULL))
  },priority=1000)
  signature
}

guarded_event_reactive <- function(eventExpr, valueExpr, ..., env = parent.frame()) {
  event <- substitute(eventExpr); body <- substitute(valueExpr)
  inputs <- get("input", envir = env)
  ignored <- c("csv_table", "pooled_split_csv_table", "met_csv_table", "met_batch_view_trait", "met_sel_env", "plot_type", "corr_method", "corr_order", "corr_palette", "corr_type", "corr_sig_filter")
  signature <- stable_input_signature(inputs,ignored,"download|_rows_|_columns_|_search$|_cell_clicked$|^research_table|^DataTables_")
  cached <- shiny::eventReactive(event, {
    result <- eval(body, envir = env)
    if (is.list(result) && length(result$warnings)) shiny::showNotification(paste(unique(result$warnings), collapse = "\n"), type = "warning", duration = NULL)
    list(result = result, signature = signature())
  }, ..., event.quoted = TRUE, event.env = env)
  shiny::reactive({
    value <- cached()
    shiny::validate(shiny::need(identical(value$signature, signature()), "Inputs changed. Run analysis again before using or exporting results."))
    value$result
  })
}

observation_issues <- function(data, numeric_columns, id_columns = character()) {
  required <- unique(c(numeric_columns, id_columns))
  if (!all(required %in% names(data))) stop("Missing required columns: ", paste(setdiff(required, names(data)), collapse = ", "))
  reasons <- lapply(seq_len(nrow(data)), function(i) {
    bad <- required[vapply(required, function(nm) {
      value <- data[[nm]][i]
      if (nm %in% numeric_columns) !is.finite(suppressWarnings(as.numeric(as.character(value)))) else is.na(value) || !nzchar(trimws(as.character(value)))
    }, logical(1))]
    paste(bad, collapse = ", ")
  })
  reason <- unlist(reasons, use.names = FALSE)
  bad <- which(nzchar(reason))
  data.frame(Observation = bad, Reason = if (length(bad)) paste("Missing or invalid:", reason[bad]) else character(), stringsAsFactors = FALSE)
}

review_observations <- function(data, numeric_columns, id_columns = character(), exclude_missing = FALSE) {
  data <- normalize_columns(as.data.frame(data))
  issues <- observation_issues(data, numeric_columns, id_columns)
  if (nrow(issues) && !isTRUE(exclude_missing)) stop("Review missing/invalid observations ", paste(issues$Observation, collapse = ", "), ". Correct the data or explicitly exclude the listed observations.")
  rows <- setdiff(seq_len(nrow(data)), issues$Observation)
  out <- data[rows, , drop = FALSE]
  rownames(out) <- NULL
  if (!nrow(out)) stop("No observations remain after review.")
  for (nm in numeric_columns) out[[nm]] <- as.numeric(as.character(out[[nm]]))
  for (nm in id_columns) out[[nm]] <- factor(trimws(as.character(out[[nm]])))
  list(data = out, rows = rows, exclusions = issues)
}

read_pasted_table <- function(text) {
  text <- trimws(text)
  validate(need(nchar(text) > 0, "Paste a table or upload a file to continue."))

  try_tab <- tryCatch(read.table(text = text, header = TRUE, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
  if (!is.null(try_tab) && ncol(try_tab) > 1) {
    return(normalize_columns(try_tab))
  }

  try_space <- tryCatch(read.table(text = text, header = TRUE, sep = "", stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
  if (!is.null(try_space) && ncol(try_space) > 1) {
    return(normalize_columns(try_space))
  }

  try_csv <- tryCatch(read.csv(text = text, stringsAsFactors = FALSE, check.names = FALSE), error = function(e) NULL)
  if (!is.null(try_csv) && ncol(try_csv) > 1) {
    return(normalize_columns(try_csv))
  }

  stop("The pasted data could not be parsed as a table. Use tabs, spaces, commas, or upload a file.")
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

metrics_table <- function(named_values, digits = 3) {
  flat_values <- unlist(named_values, recursive = TRUE, use.names = TRUE)
  if (length(flat_values) == 0) {
    return(data.frame(Metric = character(0), Value = character(0), stringsAsFactors = FALSE))
  }

  metric_names <- names(flat_values)
  if (is.null(metric_names)) {
    metric_names <- rep("", length(flat_values))
  }

  if (any(metric_names == "")) {
    empty_idx <- which(metric_names == "")
    metric_names[empty_idx] <- paste0("Metric ", empty_idx)
  }

  metric_names <- gsub("\\.+", " ", metric_names)
  metric_names <- gsub("^\\s+|\\s+$", "", metric_names)

  formatted_values <- vapply(flat_values, function(value) {
    if (is.numeric(value)) {
      format(round(value, digits), trim = TRUE, scientific = FALSE)
    } else {
      as.character(value)
    }
  }, character(1))

  data.frame(Metric = metric_names, Value = unname(formatted_values), row.names = NULL, stringsAsFactors = FALSE)
}

resolve_report_template <- function(template_name = "analysis-report-template.Rmd") {
  search_roots <- c(
    getwd(),
    file.path(getwd(), "."),
    file.path(getwd(), ".."),
    file.path(getwd(), "..", "..")
  )
  candidates <- unique(c(file.path(search_roots, template_name), template_name))

  for (path in candidates) {
    if (file.exists(path)) {
      return(normalizePath(path, winslash = "/", mustWork = TRUE))
    }
  }

  stop(sprintf("Could not find report template '%s'.", template_name))
}

render_parameterized_report <- function(output_file, output_format, params, template_name = "analysis-report-template.Rmd") {
  template_path <- resolve_report_template(template_name)
  render_input <- tempfile(fileext = ".Rmd")
  ok <- file.copy(template_path, render_input, overwrite = TRUE)
  if (!ok) {
    stop("Could not prepare the report template for rendering.")
  }

  output_dir <- dirname(output_file)
  rendered_path <- rmarkdown::render(
    input = render_input,
    output_format = output_format,
    output_file = basename(output_file),
    output_dir = output_dir,
    params = params,
    # Shiny sources app.R into its own environment. Globalenv does not contain
    # the reporting helpers there, even though standalone export tests may.
    envir = new.env(parent = environment(render_parameterized_report)),
    quiet = TRUE
  )

  if (!file.exists(output_file) && file.exists(rendered_path)) {
    if(!file.copy(rendered_path, output_file, overwrite = TRUE)) stop("Could not prepare the generated report for download.")
  }
  if(!file.exists(output_file) || file.info(output_file)$size == 0) stop("Report generation did not produce a downloadable file.")

  invisible(output_file)
}

save_html_report <- function(title, sections, file) {
  render_html_plot <- function(plot_obj) {
    if (!inherits(plot_obj, "ggplot") && !is.function(plot_obj)) {
      return(NULL)
    }

    plot_file <- tempfile(fileext = ".png")
    on.exit(unlink(plot_file), add = TRUE)
    tryCatch(
      {
        if (is.function(plot_obj)) {
          png(plot_file, width = 1152, height = 720, res = 144)
          tryCatch(plot_obj(), finally = dev.off())
        } else ggplot2::ggsave(plot_file, plot = plot_obj, width = 8, height = 5, dpi = 144)
        tags$img(
          src = knitr::image_uri(plot_file),
          class = "img-responsive",
          style = "max-width: 100%; height: auto; margin: 0 0 24px 0;"
        )
      },
      error = function(e) NULL
    )
  }

  section_tags <- lapply(sections, function(section) {
    notes <- report_table_notes(section$table)
    if (!is.null(section$table)) section$table <- publication_table(section$table)
    div(
      h3(section$title),
      if (!is.null(section$subtitle)) p(section$subtitle, class = "station-muted"),
      if (!is.null(section$table)) tags$table(
        class = "table table-striped",
        tags$thead(tags$tr(lapply(names(section$table), tags$th))),
        tags$tbody(lapply(seq_len(nrow(section$table)), function(i) tags$tr(lapply(section$table[i, , drop = FALSE], function(cell) tags$td(as.character(cell))))))
      ),
      if(length(notes)) lapply(notes,function(note) tags$p(note,class="station-muted")),
      if (!is.null(section$text)) p(section$text),
      if (!is.null(section$plot)) render_html_plot(section$plot)
    )
  })

  htmltools::save_html(
    tagList(
      tags$html(
        tags$head(
          tags$title(title),
          tags$style("body { font-family: 'Segoe UI', Tahoma, sans-serif; margin: 32px; color: #1f2d22; } h1, h2, h3 { color: #244130; } .table { border-collapse: collapse; width: 100%; margin-bottom: 24px; } .table th, .table td { border: 1px solid #cdd8d0; padding: 8px 10px; text-align: left; } .table th { background: #edf3eb; } .station-muted { color: #5a6a5e; }")
        ),
        tags$body(h1(title), p(sprintf("Generated on %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")), class = "station-muted"),p(reporting_note()), section_tags)
      )
    ),
    file = file
  )
}

build_help_box <- function(title, lines) {
  div(class = "station-help", tags$b(title), tags$ul(lapply(lines, tags$li)))
}
