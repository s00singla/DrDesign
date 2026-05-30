portal_ui <- function(catalog = app_catalog) {
  fluidPage(
    tags$head(tags$style(research_station_styles)),
    div(class = "station-hero", h1("Research Analytics Station"), p("Cloud-ready Shiny suite for agricultural and experimental data analysis."), nav_links("portal", catalog)),
    fluidRow(
      column(6, div(class = "station-card", h3("How researchers will use this suite"), p("Choose a module, upload CSV/XLSX data or paste a table, review assumptions, then export CSV tables, HTML reports, and randomized design plans where applicable."), tags$ul(tags$li("Public link access for v1."), tags$li("Shared validation and reporting patterns across modules."), tags$li("Deployment assets included for Docker, nginx, and Shiny Server.")))),
      column(6, div(class = "station-card", h3("Support"), p("Version 1.0 deployment scaffold"), p("Recommended host: single cloud VM with Docker Compose."), p("Update this section with station support contacts before production."), p("Modules are linked below.")))
    ),
    fluidRow(lapply(catalog[-1], function(app) {
      column(6, div(class = "station-card", h3(app$label), p(switch(app$key, "design-analyzer" = "Generate randomized field layouts and allocation tables for CRD, RBD, factorial CRD/RBD, split-plot, strip-plot, and augmented RCBD experiments.", "crd-rbd" = "Single-factor CRD and RBD analysis with ANOVA, configurable post-hoc tests, and treatment plots.", "factorial-design" = "Two-factor factorial CRD and RBD analysis with EDA, diagnostics, emmeans, and post-hoc comparisons.", "pooled-anova" = "Pool trials across years or seasons after homogeneity checks.", "split-plot" = "Analyze split-plot experiments with correct strata.", "correlation-regression" = "Explore correlation, simple regression, and multiple regression.", "descriptive-statistics" = "Summarize variables, inspect distributions, and run normality diagnostics.", "compare-means" = "Run one-sample, two-sample, Welch and paired t-tests with visual comparison charts.", "met-stability" = "Multi-environment trial stability analysis: AMMI, GGE, WAASB, WAASBY, BLUP-based stability indices, individual and combined ANOVA, and simultaneous selection indices.")), tags$a(class = "btn btn-success", href = app$path, "Open Module")))
    }))
  )
}

portal_server <- function(input, output, session) {}

design_analyzer_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "Design Randomizer",
    "Generate randomized layout plans for common agricultural experiments and export the allocation table.",
    "design-analyzer",
    tagList(
      selectInput("design_type", "Design type", choices = c("CRD", "RBD", "Factorial CRD", "Factorial RBD", "Split Plot", "Augmented RCBD", "Strip Plot")),
      conditionalPanel("input.design_type == 'CRD' || input.design_type == 'RBD'",
        numericInput("trt", "Number of treatments", value = 4, min = 2)
      ),
      conditionalPanel("input.design_type == 'Factorial CRD' || input.design_type == 'Factorial RBD'",
        numericInput("factor_a_trt", "Factor A levels", value = 2, min = 2),
        numericInput("factor_b_trt", "Factor B levels", value = 2, min = 2)
      ),
      conditionalPanel("input.design_type == 'CRD' || input.design_type == 'RBD' || input.design_type == 'Factorial CRD' || input.design_type == 'Factorial RBD' || input.design_type == 'Split Plot' || input.design_type == 'Augmented RCBD' || input.design_type == 'Strip Plot'",
        numericInput("rep", "Replications / blocks", value = 3, min = 2)
      ),
      conditionalPanel("input.design_type == 'Split Plot' || input.design_type == 'Strip Plot'",
        numericInput("main_trt", "Main / horizontal treatments", value = 3, min = 2),
        numericInput("sub_trt", "Sub / vertical treatments", value = 3, min = 2)
      ),
      conditionalPanel("input.design_type == 'Augmented RCBD'",
        numericInput("checks", "Number of checks", value = 3, min = 2),
        numericInput("test_trt", "Number of test treatments", value = 6, min = 2)
      ),
      numericInput("seed", "Randomization seed", value = 1, min = 1),
      build_help_box("What this module does", c("Creates a randomized fieldbook similar to the grapesAgri layout workflow.", "Supports CRD, RBD, two-factor factorial CRD/RBD, split-plot, strip-plot, and augmented RCBD layouts.", "Use the seed to reproduce a layout exactly.", "Download the allocation table for field teams or reporting.")),
      actionButton("generate_layout", "Generate layout", class = "btn-primary"),
      tags$hr(),
      downloadButton("download_layout_csv", "Download allocation CSV"),
      downloadButton("download_layout_report", "Download HTML report"),
      uiOutput("layout_error_msg")
    ),
    analysis_tabs(
      tabPanel("Experiment Summary", tableOutput("layout_summary_table")),
      tabPanel("Allocation Table", tableOutput("layout_fieldbook_table")),
      tabPanel("Layout Plot", plotOutput("layout_plot", height = "520px"))
    ),
    nav_catalog = nav_catalog
  )
}

design_analyzer_server <- function(input, output, session) {
  err <- reactiveVal(NULL)
  layout_plan <- eventReactive(input$generate_layout, {
    err(NULL)
    tryCatch(
      run_design_layout(
        design = input$design_type,
        seed = input$seed,
        trt = input$trt,
        rep = input$rep,
        main_trt = input$main_trt,
        sub_trt = input$sub_trt,
        factor_a_trt = input$factor_a_trt,
        factor_b_trt = input$factor_b_trt,
        checks = input$checks,
        test_trt = input$test_trt
      ),
      error = function(e) {
        err(conditionMessage(e))
        NULL
      }
    )
  })

  output$layout_error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
  output$layout_summary_table <- renderTable({ req(layout_plan()); layout_plan()$summary }, rownames = FALSE)
  output$layout_fieldbook_table <- renderTable({ req(layout_plan()); layout_plan()$fieldbook }, rownames = FALSE)
  output$layout_plot <- renderPlot({
    req(layout_plan())
    plan <- layout_plan()

    if (identical(plan$design, "CRD") || identical(plan$design, "Factorial CRD")) {
      desplot::desplot(
        form = row ~ col,
        data = plan$plot_data,
        text = label,
        out1 = row,
        out2 = col,
        main = sprintf("%s Layout", plan$design),
        cex = 1.1
      )
    } else if (identical(plan$design, "RBD") || identical(plan$design, "Factorial RBD")) {
      desplot::desplot(
        form = block_num ~ plot_num,
        data = plan$plot_data,
        text = label,
        out1 = block_num,
        out2 = plot_num,
        out2.gpar = list(col = "#547d43"),
        main = sprintf("%s Layout", plan$design),
        cex = 1.1
      )
    } else if (identical(plan$design, "Augmented RCBD")) {
      desplot::desplot(
        form = block_num ~ plot_num,
        data = plan$plot_data,
        text = label,
        out1 = block_num,
        out2 = plot_num,
        main = "Augmented RCBD Layout",
        cex = 1.1
      )
    } else if (identical(plan$design, "Split Plot")) {
      desplot::desplot(
        form = main_treatment ~ main_num + sub_num,
        data = plan$plot_data,
        text = sub_treatment,
        out1 = main_num,
        out2 = sub_num,
        main = "Split-Plot Layout",
        cex = 1
      )
    } else if (identical(plan$design, "Strip Plot")) {
      desplot::desplot(
        form = rep_num ~ row_num + col_num,
        data = plan$plot_data,
        text = label,
        out1 = rep_num,
        out2 = col_num,
        main = "Strip-Plot Layout",
        cex = 1
      )
    }
  })

  output$download_layout_csv <- downloadHandler(
    filename = function() sprintf("design-layout-%s.csv", gsub("[^a-z]+", "-", tolower(input$design_type))),
    content = function(file) {
      req(layout_plan())
      write.csv(layout_plan()$fieldbook, file, row.names = FALSE)
    }
  )

  output$download_layout_report <- downloadHandler(
    filename = function() "design-layout-report.html",
    content = function(file) {
      req(layout_plan())
      plan <- layout_plan()
      save_html_report("Design Layout Report", list(
        list(title = "Design summary", subtitle = sprintf("Design: %s, seed: %s", plan$design, input$seed), table = plan$summary),
        list(title = "Allocation table", table = plan$fieldbook)
      ), file)
    }
  )
}

crd_rbd_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "CRD / RBD",
    "Single-factor CRD and RBD analysis with ANOVA, configurable post-hoc tests, key statistics, treatment plots, and report export.",
    "crd-rbd",
    tagList(
      selectInput("design", "Experimental design", choices = c("CRD", "RBD")),
      selectInput("comparison_method", "Post-hoc comparison", choices = c("LSD", "DMRT", "Tukey"), selected = "LSD"),
      numericInput("alpha", "Significance level", value = 0.05, min = 0.01, max = 0.2, step = 0.01),
      fileInput("upload", "Upload CSV / TSV / XLSX", accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("data_input", "Or paste a table", value = default_data[["CRD"]], rows = 11),
      selectInput("plot_type", "Treatment plot", choices = c("Mean with 95% CI" = "means", "Boxplot" = "boxplot")),
      build_help_box("Expected format", c("First column should be the treatment label.", "Remaining columns should be replication columns.", "Use CRD for unblocked layouts and RBD when replications act as blocks.", "Post-hoc choices now mirror the upgraded grapesAgri workflow.")),
      actionButton("analyze", "Run analysis", class = "btn-primary"),
      tags$hr(),
      selectInput("csv_table", "CSV table to download", choices = c("Long data", "ANOVA", "Key statistics", "Means", "Treatment summary", "Groups")),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_pdf_report", "Download PDF report"),
      downloadButton("download_word_report", "Download Word report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(
      tabPanel("Means & CI", tableOutput("treatment_summary_table")),
      tabPanel("ANOVA Table", tableOutput("anova_table")),
      tabPanel("Key Statistics", tableOutput("stats_table")),
      tabPanel("Inference", verbatimTextOutput("inference_text")),
      tabPanel("Post-hoc", tableOutput("lsd_stats"), tags$br(), tableOutput("lsd_groups")),
      tabPanel("Treatment Plot", plotOutput("treatment_plot", height = "360px")),
      tabPanel("Long Data View", tableOutput("long_data_table"))
    ),
    nav_catalog = nav_catalog
  )
}

crd_rbd_server <- function(input, output, session) {
  observeEvent(input$design, updateTextAreaInput(session, "data_input", value = default_data[[input$design]]), ignoreNULL = FALSE)
  err <- reactiveVal(NULL)
  analysis <- eventReactive(input$analyze, {
    err(NULL)
    tryCatch(run_design_analysis(read_dataset_input(input$upload, input$data_input), input$design, 2, 2, input$alpha, input$comparison_method), error = function(e) {
      err(conditionMessage(e))
      NULL
    })
  })

  output$error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
  output$long_data_table <- renderTable({ req(analysis()); analysis()$dataset }, rownames = FALSE)
  output$anova_table <- renderTable({ req(analysis()); analysis()$anova }, rownames = FALSE)
  output$stats_table <- renderTable({ req(analysis()); analysis()$stats }, rownames = FALSE)
  output$means_ci_table <- renderTable({ req(analysis()); analysis()$means }, rownames = FALSE)
  output$lsd_stats <- renderTable({ req(analysis()); analysis()$lsd_stats }, rownames = FALSE)
  output$lsd_groups <- renderTable({ req(analysis()); analysis()$groups }, rownames = FALSE)
  output$treatment_summary_table <- renderTable({ req(analysis()); analysis()$treatment_summary }, rownames = FALSE)
  output$inference_text <- renderText({ req(analysis()); analysis()$inference })
  treatment_plot_object <- reactive({
    req(analysis())
    if (identical(input$plot_type, "boxplot")) {
      ggplot(analysis()$dataset, aes(x = Trt, y = Value, fill = Trt)) +
        geom_boxplot(alpha = 0.85) +
        theme_minimal() +
        theme(legend.position = "none") +
        labs(title = sprintf("%s response distribution", input$design), x = "Treatment", y = "Response")
    } else {
      ggplot(analysis()$treatment_summary, aes(x = Treatment, y = Mean, fill = Treatment)) +
        geom_col(alpha = 0.9) +
        geom_errorbar(aes(ymin = LowerCI, ymax = UpperCI), width = 0.2) +
        theme_minimal() +
        theme(legend.position = "none") +
        labs(title = sprintf("%s treatment means with 95%% CI", input$design), x = "Treatment", y = "Mean response")
    }
  })
  output$treatment_plot <- renderPlot({
    treatment_plot_object()
  })

  report_params <- reactive({
    req(analysis())
    list(
      report_title = sprintf("%s Analysis Report", input$design),
      design_name = input$design,
      alpha = input$alpha,
      comparison_method = analysis()$comparison_method,
      descriptive_stats = head(analysis()$dataset, 20),
      summary_stats = analysis()$treatment_summary,
      anova_table = analysis()$anova,
      key_statistics = analysis()$stats,
      mean_table = analysis()$means,
      posthoc_summary = analysis()$lsd_stats,
      posthoc_table = analysis()$groups,
      dataset_preview = head(analysis()$dataset, 20),
      inference_text = analysis()$inference,
      report_note = analysis()$report_note,
      plot_errorbar = treatment_plot_object(),
      generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
    )
  })

  output$download_csv <- downloadHandler(
    filename = function() sprintf("crd-rbd-%s.csv", gsub("[^a-z]+", "-", tolower(input$csv_table))),
    content = function(file) {
      req(analysis())
      table_map <- list("Long data" = analysis()$dataset, "ANOVA" = analysis()$anova, "Key statistics" = analysis()$stats, "Means" = analysis()$means, "Treatment summary" = analysis()$treatment_summary, "Groups" = analysis()$groups)
      write.csv(table_map[[input$csv_table]], file, row.names = FALSE)
    }
  )

  output$download_pdf_report <- downloadHandler(
    filename = function() "crd-rbd-report.pdf",
    content = function(file) {
      req(analysis())
      render_parameterized_report(
        output_file = file,
        output_format = "pdf_document",
        params = report_params()
      )
    }
  )

  output$download_word_report <- downloadHandler(
    filename = function() "crd-rbd-report.docx",
    content = function(file) {
      req(analysis())
      render_parameterized_report(
        output_file = file,
        output_format = "word_document",
        params = report_params()
      )
    }
  )

}

descriptive_statistics_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "Descriptive Statistics",
    "Summarize numeric variables, compare groups, inspect distributions, and check normality.",
    "descriptive-statistics",
    tagList(
      fileInput("upload", "Upload CSV / TSV / XLSX", accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("data_input", "Or paste a table", value = default_data[["Descriptive Statistics"]], rows = 11),
      selectInput("analysis_type", "Analysis type", choices = c("Summary" = "summary", "Summary by group" = "sumbygrp", "Boxplot" = "boxplot", "Histogram" = "histogram", "Q-Q plot" = "qqplot", "Normality test" = "nt"), selected = "summary"),
      uiOutput("desc_variable_ui"),
      uiOutput("desc_group_ui"),
      actionButton("desc_analyze", "Run descriptive analysis", class = "btn-primary"),
      tags$hr(),
      downloadButton("download_desc_csv", "Download CSV"),
      downloadButton("download_desc_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(
      tabPanel("Data preview", tableOutput("desc_data_table")),
      tabPanel("Summary", tableOutput("desc_summary_table")),
      tabPanel("Group summary", tableOutput("desc_group_table")),
      tabPanel("Plot", plotOutput("desc_plot", height = "520px")),
      tabPanel("Normality", verbatimTextOutput("desc_normality_text"))
    ),
    nav_catalog = nav_catalog
  )
}

descriptive_statistics_server <- function(input, output, session) {
  err <- reactiveVal(NULL)
  dataset <- reactive({
    tryCatch(read_dataset_input(input$upload, input$data_input), error = function(e) {
      err(conditionMessage(e)); NULL
    })
  })

  output$desc_variable_ui <- renderUI({
    df <- dataset()
    if (is.null(df)) return(NULL)
    numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
    if (length(numeric_cols) == 0) return(div(class = "alert alert-warning", "Upload data with numeric columns to continue."))
    if (input$analysis_type %in% c("summary", "sumbygrp", "boxplot", "histogram", "qqplot", "nt")) {
      selectInput("desc_vars", "Numeric variable(s)", choices = numeric_cols, selected = numeric_cols[1], multiple = input$analysis_type %in% c("summary", "sumbygrp"))
    }
  })

  output$desc_group_ui <- renderUI({
    df <- dataset()
    if (is.null(df)) return(NULL)
    factor_cols <- names(df)[vapply(df, function(x) is.factor(x) || is.character(x), logical(1))]
    if (input$analysis_type == "sumbygrp") {
      selectInput("desc_group", "Group variable", choices = factor_cols, selected = factor_cols[1])
    } else if (input$analysis_type == "boxplot") {
      selectInput("desc_group", "Color by group (optional)", choices = c(None = "", factor_cols), selected = "")
    } else {
      NULL
    }
  })

  desc_analysis <- eventReactive(input$desc_analyze, {
    err(NULL)
    tryCatch(
      run_descriptive_analysis(read_dataset_input(input$upload, input$data_input), input$analysis_type, input$desc_vars, input$desc_group),
      error = function(e) {
        err(conditionMessage(e)); NULL
      }
    )
  })

  output$error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
  output$desc_data_table <- renderTable({ req(desc_analysis()); head(desc_analysis()$dataset, 50) }, rownames = FALSE)
  output$desc_summary_table <- renderTable({ req(desc_analysis()); desc_analysis()$summary }, rownames = FALSE)
  output$desc_group_table <- renderTable({ req(desc_analysis()); desc_analysis()$by_group }, rownames = FALSE)
  output$desc_plot <- renderPlot({ req(desc_analysis()); desc_analysis()$plot_obj }, height = 520)
  output$desc_normality_text <- renderText({ req(desc_analysis()); paste(desc_analysis()$normality, collapse = "\n") })

  output$download_desc_csv <- downloadHandler(
    filename = function() "descriptive-statistics-data.csv",
    content = function(file) {
      req(desc_analysis())
      write.csv(desc_analysis()$summary, file, row.names = FALSE)
    }
  )

  output$download_desc_report <- downloadHandler(
    filename = function() "descriptive-statistics-report.html",
    content = function(file) {
      req(desc_analysis())
      result <- desc_analysis()
      save_html_report("Descriptive Statistics Report", list(
        list(title = "Data preview", table = head(result$dataset, 20)),
        list(title = "Summary statistics", table = result$summary),
        list(title = "Group summary", table = result$by_group),
        list(title = "Notes", text = paste(result$normality, collapse = "\n"))
      ), file)
    }
  )
}

compare_means_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "Compare Means",
    "One-sample, two-sample, Welch and paired t-test workflows with diagnostics and plots.",
    "compare-means",
    tagList(
      fileInput("upload", "Upload CSV / TSV / XLSX", accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("data_input", "Or paste a table", value = default_data[["Compare Means"]], rows = 11),
      selectInput("tt_type", "Test type", choices = c("One-sample t-test" = "one-sample", "Two-sample t-test" = "two-sample", "Welch t-test" = "welch", "Paired t-test" = "paired")),
      uiOutput("tt_value_var_ui"),
      uiOutput("tt_group_var_ui"),
      uiOutput("tt_pair_vars_ui"),
      numericInput("tt_mu", "Population mean for one-sample test", value = 0),
      checkboxInput("tt_var_equal", "Assume equal variance for two-sample t-test", value = TRUE),
      actionButton("tt_analyze", "Run t-test", class = "btn-primary"),
      tags$hr(),
      downloadButton("download_tt_csv", "Download CSV"),
      downloadButton("download_tt_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(
      tabPanel("Data preview", tableOutput("tt_data_table")),
      tabPanel("Descriptive summary", tableOutput("tt_desc_table")),
      tabPanel("Variance check", tableOutput("tt_variance_table")),
      tabPanel("Test result", tableOutput("tt_result_table")),
      tabPanel("Plot", plotOutput("tt_plot", height = "520px"))
    ),
    nav_catalog = nav_catalog
  )
}

compare_means_server <- function(input, output, session) {
  err <- reactiveVal(NULL)
  dataset <- reactive({
    tryCatch(read_dataset_input(input$upload, input$data_input), error = function(e) {
      err(conditionMessage(e)); NULL
    })
  })

  output$tt_value_var_ui <- renderUI({
    df <- dataset()
    if (is.null(df)) return(NULL)
    numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
    if (length(numeric_cols) == 0) return(div(class = "alert alert-warning", "Upload data with numeric columns to continue."))
    selectInput("tt_value", "Outcome variable", choices = numeric_cols, selected = numeric_cols[1])
  })

  output$tt_group_var_ui <- renderUI({
    req(input$tt_type)
    df <- dataset()
    if (is.null(df) || !input$tt_type %in% c("two-sample", "welch")) return(NULL)
    factor_cols <- names(df)[vapply(df, function(x) is.factor(x) || is.character(x), logical(1))]
    selectInput("tt_group", "Grouping variable", choices = factor_cols, selected = factor_cols[1])
  })

  output$tt_pair_vars_ui <- renderUI({
    req(input$tt_type)
    df <- dataset()
    if (is.null(df) || input$tt_type != "paired") return(NULL)
    numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
    tagList(
      selectInput("tt_pair_left", "Paired column 1", choices = numeric_cols, selected = numeric_cols[1]),
      selectInput("tt_pair_right", "Paired column 2", choices = numeric_cols, selected = numeric_cols[min(2, length(numeric_cols))])
    )
  })

  tt_analysis <- eventReactive(input$tt_analyze, {
    err(NULL)
    tryCatch(
      run_ttest_analysis(read_dataset_input(input$upload, input$data_input), input$tt_type, input$tt_value, input$tt_group, input$tt_pair_left, input$tt_pair_right, input$tt_mu, input$tt_var_equal),
      error = function(e) {
        err(conditionMessage(e)); NULL
      }
    )
  })

  output$error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
  output$tt_data_table <- renderTable({ req(tt_analysis()); head(tt_analysis()$dataset, 50) }, rownames = FALSE)
  output$tt_desc_table <- renderTable({ req(tt_analysis()); tt_analysis()$summary }, rownames = FALSE)
  output$tt_variance_table <- renderTable({ req(tt_analysis()); tt_analysis()$variance }, rownames = FALSE)
  output$tt_result_table <- renderTable({ req(tt_analysis()); tt_analysis()$test_result }, rownames = FALSE)
  output$tt_plot <- renderPlot({ req(tt_analysis()); tt_analysis()$plot_obj }, height = 520)

  output$download_tt_csv <- downloadHandler(
    filename = function() "compare-means-summary.csv",
    content = function(file) {
      req(tt_analysis())
      write.csv(tt_analysis()$summary, file, row.names = FALSE)
    }
  )

  output$download_tt_report <- downloadHandler(
    filename = function() "compare-means-report.html",
    content = function(file) {
      req(tt_analysis())
      result <- tt_analysis()
      save_html_report("Compare Means Report", list(
        list(title = "Data preview", table = head(result$dataset, 20)),
        list(title = "Descriptive summary", table = result$summary),
        list(title = "Variance comparison", table = result$variance),
        list(title = "t-test result", table = result$test_result)
      ), file)
    }
  )
}

factorial_design_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "Factorial Design",
    "Two-factor factorial CRD and RBD workflow with EDA, diagnostics, emmeans, Tukey comparisons, and letter groupings.",
    "factorial-design",
    tagList(
      selectInput("design", "Experimental design", choices = c("Factorial CRD", "Factorial RBD")),
      numericInput("levels_a", "Levels of Factor A", value = 2, min = 2),
      numericInput("levels_b", "Levels of Factor B", value = 2, min = 2),
      numericInput("alpha", "Significance level", value = 0.05, min = 0.01, max = 0.2, step = 0.01),
      fileInput("upload", "Upload CSV / TSV / XLSX", accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("data_input", "Or paste a table", value = default_data[["Factorial CRD"]], rows = 11),
      build_help_box("Expected format", c("First column should be the treatment label.", "Remaining columns should be replication columns.", "Paste factorial rows in order A1B1, A1B2 ... A2B1 ...", "Use the factor-level inputs to match the number of A x B combinations.")),
      actionButton("analyze", "Run factorial analysis", class = "btn-primary"),
      tags$hr(),
      selectInput("csv_table", "CSV table to download", choices = c("Long data", "ANOVA", "Key statistics", "Means", "LSD groups", "Factorial full ANOVA", "Factorial additive ANOVA", "Factorial emmeans interaction", "Factorial emmeans A", "Factorial emmeans B", "Factorial Tukey interaction", "Factorial CLD interaction", "Factorial diagnostics")),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(
      tabPanel("Long Data View", tableOutput("long_data_table")),
      tabPanel("ANOVA Table", tableOutput("anova_table")),
      tabPanel("Key Statistics", tableOutput("stats_table")),
      tabPanel("Means & CI", tableOutput("means_ci_table")),
      tabPanel("LSD & Letter Groups", tableOutput("lsd_stats"), tags$br(), tableOutput("lsd_groups")),
      tabPanel("EDA", verbatimTextOutput("factorial_data_summary"), plotOutput("factorial_boxplot", height = "320px"), plotOutput("factorial_observed_interaction", height = "320px")),
      tabPanel("Models", tableOutput("factorial_full_anova"), tags$br(), tableOutput("factorial_additive_anova"), tags$br(), tableOutput("factorial_assumptions")),
      tabPanel("Diagnostics", verbatimTextOutput("factorial_final_summary"), plotOutput("factorial_residual_plot", height = "320px"), plotOutput("factorial_residual_qq_plot", height = "320px"), tableOutput("factorial_shapiro"), tags$br(), tableOutput("factorial_levene"), tags$br(), tableOutput("factorial_diagnostics")),
      tabPanel("Emmeans", tableOutput("factorial_emm_interaction"), tags$br(), tableOutput("factorial_emm_a"), tags$br(), tableOutput("factorial_emm_b"), plotOutput("factorial_emm_interaction_plot", height = "320px"), plotOutput("factorial_emm_a_plot", height = "320px"), plotOutput("factorial_emm_b_plot", height = "320px")),
      tabPanel("Post-hoc", tableOutput("factorial_tukey_interaction"), tags$br(), tableOutput("factorial_tukey_a"), tags$br(), tableOutput("factorial_tukey_b"), tags$br(), tableOutput("factorial_cld_interaction"), tags$br(), tableOutput("factorial_cld_a"), tags$br(), tableOutput("factorial_cld_b"))
    ),
    nav_catalog = nav_catalog
  )
}

factorial_design_server <- function(input, output, session) {
  observeEvent(input$design, updateTextAreaInput(session, "data_input", value = default_data[[input$design]]), ignoreNULL = FALSE)
  err <- reactiveVal(NULL)
  analysis <- eventReactive(input$analyze, {
    err(NULL)
    tryCatch(run_design_analysis(read_dataset_input(input$upload, input$data_input), input$design, input$levels_a, input$levels_b, input$alpha), error = function(e) {
      err(conditionMessage(e))
      NULL
    })
  })

  output$error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
  output$long_data_table <- renderTable({ req(analysis()); analysis()$dataset }, rownames = FALSE)
  output$anova_table <- renderTable({ req(analysis()); analysis()$anova }, rownames = FALSE)
  output$stats_table <- renderTable({ req(analysis()); analysis()$stats }, rownames = FALSE)
  output$means_ci_table <- renderTable({ req(analysis()); analysis()$means }, rownames = FALSE)
  output$lsd_stats <- renderTable({ req(analysis()); analysis()$lsd_stats }, rownames = FALSE)
  output$lsd_groups <- renderTable({ req(analysis()); analysis()$groups }, rownames = FALSE)
  output$factorial_data_summary <- renderText({ req(analysis()); paste(analysis()$factorial$data_summary, collapse = "\n") })
  output$factorial_full_anova <- renderTable({ req(analysis()); analysis()$factorial$full_anova }, rownames = FALSE)
  output$factorial_additive_anova <- renderTable({ req(analysis()); analysis()$factorial$additive_anova }, rownames = FALSE)
  output$factorial_assumptions <- renderTable({ req(analysis()); analysis()$factorial$assumptions }, rownames = FALSE)
  output$factorial_final_summary <- renderText({ req(analysis()); paste(analysis()$factorial$final_summary, collapse = "\n") })
  output$factorial_shapiro <- renderTable({ req(analysis()); analysis()$factorial$shapiro }, rownames = FALSE)
  output$factorial_levene <- renderTable({ req(analysis()); analysis()$factorial$levene }, rownames = FALSE)
  output$factorial_diagnostics <- renderTable({ req(analysis()); analysis()$factorial$diagnostics }, rownames = FALSE)
  output$factorial_emm_interaction <- renderTable({ req(analysis()); analysis()$factorial$emmeans_interaction }, rownames = FALSE)
  output$factorial_emm_a <- renderTable({ req(analysis()); analysis()$factorial$emmeans_a }, rownames = FALSE)
  output$factorial_emm_b <- renderTable({ req(analysis()); analysis()$factorial$emmeans_b }, rownames = FALSE)
  output$factorial_tukey_interaction <- renderTable({ req(analysis()); analysis()$factorial$tukey_interaction }, rownames = FALSE)
  output$factorial_tukey_a <- renderTable({ req(analysis()); analysis()$factorial$tukey_a }, rownames = FALSE)
  output$factorial_tukey_b <- renderTable({ req(analysis()); analysis()$factorial$tukey_b }, rownames = FALSE)
  output$factorial_cld_interaction <- renderTable({ req(analysis()); analysis()$factorial$cld_interaction }, rownames = FALSE)
  output$factorial_cld_a <- renderTable({ req(analysis()); analysis()$factorial$cld_a }, rownames = FALSE)
  output$factorial_cld_b <- renderTable({ req(analysis()); analysis()$factorial$cld_b }, rownames = FALSE)
  output$factorial_boxplot <- renderPlot({ req(analysis()); print(analysis()$factorial$boxplot_obj) })
  output$factorial_observed_interaction <- renderPlot({ req(analysis()); print(analysis()$factorial$observed_interaction_plot) })
  output$factorial_emm_interaction_plot <- renderPlot({ req(analysis()); print(analysis()$factorial$emm_interaction_plot) })
  output$factorial_emm_a_plot <- renderPlot({ req(analysis()); print(analysis()$factorial$emm_a_plot) })
  output$factorial_emm_b_plot <- renderPlot({ req(analysis()); print(analysis()$factorial$emm_b_plot) })
  output$factorial_residual_plot <- renderPlot({ req(analysis()); plot(analysis()$factorial$fitted, analysis()$factorial$residuals, xlab = "Fitted values", ylab = "Residuals", main = "Residuals vs Fitted"); abline(h = 0, lty = 2, col = "red") })
  output$factorial_residual_qq_plot <- renderPlot({ req(analysis()); qqnorm(analysis()$factorial$residuals, main = "Residual Q-Q Plot"); qqline(analysis()$factorial$residuals, col = "red") })

  output$download_csv <- downloadHandler(
    filename = function() sprintf("factorial-design-%s.csv", gsub("[^a-z]+", "-", tolower(input$csv_table))),
    content = function(file) {
      req(analysis())
      table_map <- list(
        "Long data" = analysis()$dataset,
        "ANOVA" = analysis()$anova,
        "Key statistics" = analysis()$stats,
        "Means" = analysis()$means,
        "LSD groups" = analysis()$groups,
        "Factorial full ANOVA" = analysis()$factorial$full_anova,
        "Factorial additive ANOVA" = analysis()$factorial$additive_anova,
        "Factorial emmeans interaction" = analysis()$factorial$emmeans_interaction,
        "Factorial emmeans A" = analysis()$factorial$emmeans_a,
        "Factorial emmeans B" = analysis()$factorial$emmeans_b,
        "Factorial Tukey interaction" = analysis()$factorial$tukey_interaction,
        "Factorial CLD interaction" = analysis()$factorial$cld_interaction,
        "Factorial diagnostics" = analysis()$factorial$diagnostics
      )
      write.csv(table_map[[input$csv_table]], file, row.names = FALSE)
    }
  )

  output$download_report <- downloadHandler(
    filename = function() "factorial-design-report.html",
    content = function(file) {
      req(analysis())
      save_html_report("Factorial Design Report", list(
        list(title = "Dataset summary", subtitle = analysis()$report_note, table = head(analysis()$dataset, 20)),
        list(title = "ANOVA table", table = analysis()$anova),
        list(title = "Key statistics", table = analysis()$stats),
        list(title = "Factorial full model ANOVA", table = analysis()$factorial$full_anova),
        list(title = "Factorial additive model ANOVA", table = analysis()$factorial$additive_anova),
        list(title = "Factorial assumptions", table = analysis()$factorial$assumptions),
        list(title = "Factorial emmeans: interaction", table = analysis()$factorial$emmeans_interaction),
        list(title = "Factorial post-hoc: interaction", table = analysis()$factorial$tukey_interaction)
      ), file)
    }
  )
}

pooled_anova_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "Pooled ANOVA",
    "Pool comparable trials across years or seasons after checking error homogeneity.",
    "pooled-anova",
    tagList(
      numericInput("alpha", "Significance level", value = 0.05, min = 0.01, max = 0.2, step = 0.01),
      fileInput("upload", "Upload CSV / TSV / XLSX", accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("data_input", "Or paste a table", value = pooled_example, rows = 11),
      build_help_box("Expected columns", c("Season, Treatment, and Value are required.", "Rep is recommended for blocked trials.", "Use one row per observed plot value.")),
      actionButton("analyze", "Run pooled ANOVA", class = "btn-primary"),
      tags$hr(),
      selectInput("csv_table", "CSV table to download", choices = c("ANOVA", "Homogeneity", "Treatment means", "Season x treatment means")),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(tabPanel("ANOVA Table", tableOutput("anova_table")), tabPanel("Homogeneity Checks", tableOutput("homogeneity_table"), tags$br(), tableOutput("error_ms_table")), tabPanel("Means", tableOutput("treatment_means_table"), tags$br(), tableOutput("season_treatment_means_table")), tabPanel("Long Data View", tableOutput("long_data_table")))
    ,
    nav_catalog = nav_catalog
  )
}

pooled_anova_server <- function(input, output, session) {
  err <- reactiveVal(NULL)
  analysis <- eventReactive(input$analyze, {
    err(NULL)
    tryCatch(run_pooled_anova(read_dataset_input(input$upload, input$data_input), input$alpha), error = function(e) {
      err(conditionMessage(e))
      NULL
    })
  })

  output$error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
  output$anova_table <- renderTable({ req(analysis()); analysis()$anova }, rownames = FALSE)
  output$homogeneity_table <- renderTable({ req(analysis()); analysis()$homogeneity }, rownames = FALSE)
  output$error_ms_table <- renderTable({ req(analysis()); analysis()$error_summary }, rownames = FALSE)
  output$treatment_means_table <- renderTable({ req(analysis()); analysis()$treatment_means }, rownames = FALSE)
  output$season_treatment_means_table <- renderTable({ req(analysis()); analysis()$season_treatment_means }, rownames = FALSE)
  output$long_data_table <- renderTable({ req(analysis()); analysis()$dataset }, rownames = FALSE)

  output$download_csv <- downloadHandler(
    filename = function() sprintf("pooled-anova-%s.csv", gsub("[^a-z]+", "-", tolower(input$csv_table))),
    content = function(file) {
      req(analysis())
      table_map <- list("ANOVA" = analysis()$anova, "Homogeneity" = analysis()$homogeneity, "Treatment means" = analysis()$treatment_means, "Season x treatment means" = analysis()$season_treatment_means)
      write.csv(table_map[[input$csv_table]], file, row.names = FALSE)
    }
  )

  output$download_report <- downloadHandler(
    filename = function() "pooled-anova-report.html",
    content = function(file) {
      req(analysis())
      save_html_report("Pooled ANOVA Report", list(
        list(title = "Dataset summary", subtitle = analysis()$report_note, table = head(analysis()$dataset, 20)),
        list(title = "Homogeneity check", table = analysis()$homogeneity),
        list(title = "Season-wise error mean square", table = analysis()$error_summary),
        list(title = "Pooled ANOVA table", table = analysis()$anova),
        list(title = "Treatment means", table = analysis()$treatment_means)
      ), file)
    }
  )
}

split_plot_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "Split Plot",
    "Mixed-model split-plot workflow with EDA, interaction testing, diagnostics, emmeans, Tukey comparisons, and letter groupings.",
    "split-plot",
    tagList(
      numericInput("alpha", "Significance level", value = 0.05, min = 0.01, max = 0.2, step = 0.01),
      fileInput("upload", "Upload CSV / TSV / XLSX", accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("data_input", "Or paste a table", value = split_plot_example, rows = 11),
      uiOutput("split_rep_var_ui"),
      uiOutput("split_mainplot_var_ui"),
      uiOutput("split_subplot_var_ui"),
      uiOutput("split_response_var_ui"),
      build_help_box("Expected columns", c("Choose the correct column for Rep, MainPlot, SubPlot, and Value after pasting or uploading data.", "Common shorthand: W/A/B/Y or any custom names.", "Replication is the whole-plot factor, MainPlot and SubPlot are treatment factors.")),
      actionButton("analyze", "Run split-plot analysis", class = "btn-primary"),
      tags$hr(),
      selectInput("csv_table", "CSV table to download", choices = c("Full ANOVA", "Additive ANOVA", "Split ANOVA", "Main plot means", "Subplot means", "Interaction means", "Split LSD/CV summary", "EMMeans main plot", "EMMeans subplot", "Tukey main plot", "Tukey subplot", "CLD main plot", "CLD subplot", "Diagnostics")),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_split_pdf_report", "Download PDF report"),
      downloadButton("download_split_word_report", "Download Word report"),
      downloadButton("download_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(
      tabPanel("EDA", verbatimTextOutput("data_summary_text"), plotOutput("boxplot_plot", height = "320px"), plotOutput("interaction_plot_chart", height = "320px")),
      tabPanel("Model ANOVA", tableOutput("full_anova_table"), tags$br(), tableOutput("additive_anova_table"), tags$br(), tableOutput("assumptions_table")),
      tabPanel("Split Plot Results",
        tags$h4("Clean split-plot ANOVA"),
        tableOutput("split_anova_table"),
        tags$br(),
        tags$h4("Main plot means"),
        tableOutput("split_main_means_table"),
        tags$br(),
        tags$h4("Subplot means"),
        tableOutput("split_sub_means_table"),
        tags$br(),
        tags$h4("Interaction means"),
        tableOutput("split_interaction_means_table"),
        tags$br(),
        tags$h4("LSD and CV summary"),
        tableOutput("split_lsd_cv_table"),
        tags$br(),
        plotOutput("lsd_main_plot", height = "280px"),
        plotOutput("lsd_sub_plot", height = "280px"),
        plotOutput("split_interaction_mean_plot", height = "320px")
      ),
      tabPanel("Diagnostics", verbatimTextOutput("final_summary_text"), plotOutput("diagnostic_scatter_plot", height = "320px"), plotOutput("residual_qq_plot", height = "320px"), plotOutput("random_effects_qq_plot", height = "320px"), tableOutput("diagnostics_table")),
      tabPanel("Estimated Means", tableOutput("emmeans_main_table"), tags$br(), tableOutput("emmeans_sub_table"), tags$br(), tableOutput("emmeans_interaction_table"), plotOutput("lsmean_main_plot_chart", height = "320px"), plotOutput("lsmean_sub_plot_chart", height = "320px")),
      tabPanel("Post-hoc", tableOutput("tukey_main_table"), tags$br(), tableOutput("tukey_sub_table"), tags$br(), tableOutput("cld_main_table"), tags$br(), tableOutput("cld_sub_table")),
      tabPanel("Long Data View", DT::dataTableOutput("long_data_table"))
    )
    ,
    nav_catalog = nav_catalog
  )
}

split_plot_server <- function(input, output, session) {

  ##########################################################
  # ERROR HOLDER
  ##########################################################

  err <- reactiveVal(NULL)

  ##########################################################
  # DATASET
  ##########################################################

  dataset <- reactive({

    tryCatch(

      read_dataset_input(
        input$upload,
        input$data_input
      ),

      error = function(e){

        err(conditionMessage(e))

        NULL
      }
    )
  })

  ##########################################################
  # VARIABLE SELECTION UI
  ##########################################################

  output$split_rep_var_ui <- renderUI({

    df <- dataset()

    validate(
      need(!is.null(df),
           "Upload or paste data first.")
    )

    choices <- names(df)

    selectInput(
      "rep_var",
      "Replication variable",
      choices = choices,
      selected =
        if("Rep" %in% choices) "Rep"
        else choices[1]
    )
  })


  output$split_mainplot_var_ui <- renderUI({

    df <- dataset()

    validate(
      need(!is.null(df),
           "Upload or paste data first.")
    )

    choices <- names(df)

    selectInput(
      "mainplot_var",
      "Main plot variable",
      choices = choices,
      selected =
        if("MainPlot" %in% choices) "MainPlot"
        else if("A" %in% choices) "A"
        else choices[min(2,length(choices))]
    )
  })


  output$split_subplot_var_ui <- renderUI({

    df <- dataset()

    validate(
      need(!is.null(df),
           "Upload or paste data first.")
    )

    choices <- names(df)

    selectInput(
      "subplot_var",
      "Sub plot variable",
      choices = choices,
      selected =
        if("SubPlot" %in% choices) "SubPlot"
        else if("B" %in% choices) "B"
        else choices[min(3,length(choices))]
    )
  })


  output$split_response_var_ui <- renderUI({

    df <- dataset()

    validate(
      need(!is.null(df),
           "Upload or paste data first.")
    )

    numeric_cols <- names(df)[
      sapply(df,is.numeric)
    ]

    validate(
      need(length(numeric_cols)>0,
           "No numeric columns found.")
    )

    selectInput(
      "response_var",
      "Response variable",
      choices = numeric_cols,
      selected = numeric_cols[1]
    )
  })

  ##########################################################
  # ANALYSIS
  ##########################################################

  analysis <- eventReactive(
    input$analyze,
    {

      err(NULL)

      req(dataset())

      validate(
        need(
          length(unique(c(
            input$rep_var,
            input$mainplot_var,
            input$subplot_var,
            input$response_var
          ))) == 4,

          "All variables must be different."
        )
      )

      tryCatch(

        run_split_plot(
          dataset(),
          input$rep_var,
          input$mainplot_var,
          input$subplot_var,
          input$response_var,
          input$alpha
        ),

        error = function(e){

          err(conditionMessage(e))

          NULL
        }
      )
    }
  )

  ##########################################################
  # ERROR DISPLAY
  ##########################################################

  output$error_msg <- renderUI({

    if(!is.null(err())){

      div(
        class = "alert alert-danger",

        tags$b("Error: "),

        err()
      )
    }
  })

  ##########################################################
  # TEXT OUTPUTS
  ##########################################################

  output$data_summary_text <- renderText({

    req(analysis())

    paste(
      analysis()$data_summary,
      collapse = "\n"
    )
  })


  output$final_summary_text <- renderText({

    req(analysis())

    paste(
      analysis()$final_summary,
      collapse = "\n"
    )
  })

  ##########################################################
  # SAFE TABLE RENDERER
  ##########################################################

  safe_table <- function(obj){

    if(is.null(obj)){

      return(NULL)
    }

    if(is.list(obj) &&
       !is.data.frame(obj)){

      obj <- as.data.frame(
        do.call(
          rbind,
          lapply(obj,unlist)
        )
      )
    }

    obj
  }

  ##########################################################
  # TABLE OUTPUTS
  ##########################################################

  output$full_anova_table <- renderTable({
    req(analysis())
    safe_table(analysis()$full_anova)
  }, rownames = FALSE)

  output$additive_anova_table <- renderTable({
    req(analysis())
    safe_table(analysis()$additive_anova)
  }, rownames = FALSE)

  output$assumptions_table <- renderTable({
    req(analysis())
    safe_table(analysis()$assumptions)
  }, rownames = FALSE)

  output$split_anova_table <- renderTable({
    req(analysis())
    safe_table(analysis()$split_anova)
  }, rownames = FALSE)

  output$split_main_means_table <- renderTable({
    req(analysis())
    safe_table(analysis()$split_main_means)
  }, rownames = FALSE)

  output$split_sub_means_table <- renderTable({
    req(analysis())
    safe_table(analysis()$split_sub_means)
  }, rownames = FALSE)

  output$split_interaction_means_table <- renderTable({
    req(analysis())
    safe_table(analysis()$split_interaction_means)
  }, rownames = FALSE)

  output$split_lsd_cv_table <- renderTable({
    req(analysis())
    safe_table(analysis()$split_lsd_cv)
  }, rownames = FALSE)

  output$emmeans_main_table <- renderTable({
    req(analysis())
    safe_table(analysis()$emmeans_main)
  }, rownames = FALSE)

  output$emmeans_sub_table <- renderTable({
    req(analysis())
    safe_table(analysis()$emmeans_sub)
  }, rownames = FALSE)

  output$emmeans_interaction_table <- renderTable({
    req(analysis())
    safe_table(analysis()$emmeans_interaction)
  }, rownames = FALSE)

  output$tukey_main_table <- renderTable({
    req(analysis())
    safe_table(analysis()$tukey_main)
  }, rownames = FALSE)

  output$tukey_sub_table <- renderTable({
    req(analysis())
    safe_table(analysis()$tukey_sub)
  }, rownames = FALSE)

  output$cld_main_table <- renderTable({
    req(analysis())
    safe_table(analysis()$cld_main)
  }, rownames = FALSE)

  output$cld_sub_table <- renderTable({
    req(analysis())
    safe_table(analysis()$cld_sub)
  }, rownames = FALSE)

  output$diagnostics_table <- renderTable({
    req(analysis())
    safe_table(analysis()$diagnostics)
  }, rownames = FALSE)

  ##########################################################
  # LARGE DATA TABLE
  ##########################################################

  output$long_data_table <- DT::renderDataTable({

    req(analysis())

    analysis()$dataset

  },
  options = list(
    pageLength = 10,
    scrollX = TRUE
  ))

  ##########################################################
  # SAFE PLOT FUNCTION
  ##########################################################

  safe_plot <- function(plot_obj){

    validate(
      need(
        !is.null(plot_obj),
        "Plot unavailable"
      )
    )

    print(plot_obj)
  }

  ##########################################################
  # PLOTS
  ##########################################################

  output$boxplot_plot <- renderPlot({
    req(analysis())
    safe_plot(analysis()$boxplot_obj)
  })

  output$interaction_plot_chart <- renderPlot({
    req(analysis())
    safe_plot(analysis()$interaction_plot)
  })

  output$lsmean_main_plot_chart <- renderPlot({
    req(analysis())
    safe_plot(analysis()$lsmean_main_plot)
  })

  output$lsmean_sub_plot_chart <- renderPlot({
    req(analysis())
    safe_plot(analysis()$lsmean_sub_plot)
  })

  output$lsd_main_plot <- renderPlot({
    req(analysis())
    safe_plot(analysis()$lsd_main_plot)
  })

  output$lsd_sub_plot <- renderPlot({
    req(analysis())
    safe_plot(analysis()$lsd_sub_plot)
  })

  output$split_interaction_mean_plot <- renderPlot({
    req(analysis())
    safe_plot(analysis()$split_interaction_mean_plot)
  })

  ##########################################################
  # DIAGNOSTIC PLOTS
  ##########################################################

  output$diagnostic_scatter_plot <- renderPlot({

    req(analysis())

    validate(
      need(
        !is.null(analysis()$fitted_final),
        "Diagnostics unavailable"
      )
    )

    plot(
      analysis()$fitted_final,
      analysis()$residuals_final,

      xlab = "Fitted values",
      ylab = "Residuals",

      main = "Residuals vs Fitted"
    )

    abline(h = 0,
           lty = 2,
           col = "red")
  })


  output$residual_qq_plot <- renderPlot({

    req(analysis())

    qqnorm(
      analysis()$residuals_final,

      main = "Residual Q-Q Plot"
    )

    qqline(
      analysis()$residuals_final,
      col = "red"
    )
  })


  output$random_effects_qq_plot <- renderPlot({

    req(analysis())

    reffects <- analysis()$random_effects
    rcol <- analysis()$random_effect_column

    validate(
      need(!is.null(reffects), "Random effects unavailable"),
      need(!is.null(rcol), "Random effect column missing"),
      need(rcol %in% names(reffects), "Random effect column not found")
    )

    random_vals <- reffects[[rcol]]

    validate(
      need(length(random_vals) > 0, "No random effects available")
    )

    qqnorm(
      random_vals,
      main = "Random Effects Q-Q Plot"
    )

    qqline(
      random_vals,
      col = "red"
    )
  })

  report_params <- reactive({
    req(analysis())

    residual_plot <- ggplot2::ggplot(
      data.frame(Fitted = analysis()$fitted_final, Residual = analysis()$residuals_final),
      ggplot2::aes(x = Fitted, y = Residual)
    ) +
      ggplot2::geom_point(color = "#244130") +
      ggplot2::geom_hline(yintercept = 0, linetype = 2, color = "red") +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Residuals vs Fitted", x = "Fitted values", y = "Residuals")

    residual_qq_plot <- ggplot2::ggplot(
      data.frame(Residual = analysis()$residuals_final),
      ggplot2::aes(sample = Residual)
    ) +
      ggplot2::stat_qq(color = "#244130") +
      ggplot2::stat_qq_line(color = "red") +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Residual Q-Q Plot")

    random_effects <- analysis()$random_effects
    random_effect_column <- analysis()$random_effect_column
    random_effect_qq_plot <- NULL
    if (!is.null(random_effects) &&
        !is.null(random_effect_column) &&
        random_effect_column %in% names(random_effects)) {
      random_effect_qq_plot <- ggplot2::ggplot(
        data.frame(RandomEffect = random_effects[[random_effect_column]]),
        ggplot2::aes(sample = RandomEffect)
      ) +
        ggplot2::stat_qq(color = "#244130") +
        ggplot2::stat_qq_line(color = "red") +
        ggplot2::theme_minimal() +
        ggplot2::labs(title = "Random Effects Q-Q Plot")
    }

    list(
      report_title = "Split Plot Analysis Report",
      design_name = "Split Plot",
      alpha = input$alpha,
      comparison_method = "Tukey",
      descriptive_stats = safe_table(analysis()$diagnostics),
      summary_stats = safe_table(analysis()$split_lsd_cv),
      anova_table = safe_table(analysis()$split_anova),
      key_statistics = safe_table(analysis()$assumptions),
      mean_table = safe_table(analysis()$split_interaction_means),
      posthoc_summary = safe_table(analysis()$tukey_main),
      posthoc_table = safe_table(analysis()$cld_main),
      dataset_preview = head(analysis()$dataset, 20),
      inference_text = "The split-plot module fits the selected mixed model, reports split-plot ANOVA strata, computes observed means, estimated marginal means, Tukey comparisons, compact letter displays, LSD/CV summaries, and model diagnostics.",
      report_note = analysis()$report_note,
      plot_errorbar = analysis()$interaction_plot,
      extra_tables = list(
        "Full Mixed-Model ANOVA" = safe_table(analysis()$full_anova),
        "Additive Mixed-Model ANOVA" = safe_table(analysis()$additive_anova),
        "Assumptions and Model Choice" = safe_table(analysis()$assumptions),
        "Clean Split-Plot ANOVA" = safe_table(analysis()$split_anova),
        "Main Plot Means" = safe_table(analysis()$split_main_means),
        "Subplot Means" = safe_table(analysis()$split_sub_means),
        "Interaction Means" = safe_table(analysis()$split_interaction_means),
        "LSD and CV Summary" = safe_table(analysis()$split_lsd_cv),
        "Estimated Means - Main Plot" = safe_table(analysis()$emmeans_main),
        "Estimated Means - Subplot" = safe_table(analysis()$emmeans_sub),
        "Estimated Means - Interaction" = safe_table(analysis()$emmeans_interaction),
        "Tukey Comparisons - Main Plot" = safe_table(analysis()$tukey_main),
        "Tukey Comparisons - Subplot" = safe_table(analysis()$tukey_sub),
        "Compact Letter Display - Main Plot" = safe_table(analysis()$cld_main),
        "Compact Letter Display - Subplot" = safe_table(analysis()$cld_sub),
        "Diagnostics" = safe_table(analysis()$diagnostics)
      ),
      extra_text_sections = list(
        "Data Summary" = analysis()$data_summary,
        "Final Model Summary" = analysis()$final_summary
      ),
      extra_plots = list(
        "Boxplot" = analysis()$boxplot_obj,
        "Estimated Means Interaction Plot" = analysis()$interaction_plot,
        "Estimated Means - Main Plot" = analysis()$lsmean_main_plot,
        "Estimated Means - Subplot" = analysis()$lsmean_sub_plot,
        "Main Plot Means with LSD" = analysis()$lsd_main_plot,
        "Subplot Means with LSD" = analysis()$lsd_sub_plot,
        "Observed Interaction Means" = analysis()$split_interaction_mean_plot,
        "Residuals vs Fitted" = residual_plot,
        "Residual Q-Q Plot" = residual_qq_plot,
        "Random Effects Q-Q Plot" = random_effect_qq_plot
      ),
      generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
    )
  })

  ##########################################################
  # DOWNLOAD CSV
  ##########################################################

  output$download_csv <- downloadHandler(

    filename = function(){

      paste0(
        "split-plot-",
        Sys.Date(),
        ".csv"
      )
    },

    content = function(file){

      req(analysis())

      table_map <- list(

        "Full ANOVA" =
          analysis()$full_anova,

        "Additive ANOVA" =
          analysis()$additive_anova,

        "Split ANOVA" =
          analysis()$split_anova,

        "Main plot means" =
          analysis()$split_main_means,

        "Subplot means" =
          analysis()$split_sub_means,

        "Interaction means" =
          analysis()$split_interaction_means,

        "Split LSD/CV summary" =
          analysis()$split_lsd_cv,

        "EMMeans main plot" =
          analysis()$emmeans_main,

        "EMMeans subplot" =
          analysis()$emmeans_sub,

        "Tukey main plot" =
          analysis()$tukey_main,

        "Tukey subplot" =
          analysis()$tukey_sub,

        "CLD main plot" =
          analysis()$cld_main,

        "CLD subplot" =
          analysis()$cld_sub,

        "Diagnostics" =
          analysis()$diagnostics
      )

      tbl <- table_map[[input$csv_table]]

      validate(
        need(
          !is.null(tbl),
          "Selected table unavailable"
        )
      )

      write.csv(
        safe_table(tbl),
        file,
        row.names = FALSE
      )
    }
  )

  output$download_split_pdf_report <- downloadHandler(
    filename = function() "split-plot-report.pdf",
    content = function(file) {
      req(analysis())

      render_parameterized_report(
        output_file = file,
        output_format = "pdf_document",
        params = report_params()
      )
    }
  )

  output$download_split_word_report <- downloadHandler(
    filename = function() "split-plot-report.docx",
    content = function(file) {
      req(analysis())

      render_parameterized_report(
        output_file = file,
        output_format = "word_document",
        params = report_params()
      )
    }
  )

  output$download_report <- downloadHandler(
    filename = function() "split-plot-report.html",
    content = function(file) {
      req(analysis())

      save_html_report("Split Plot Report", list(
        list(title = "Dataset summary", subtitle = analysis()$report_note, table = head(analysis()$dataset, 20)),
        list(title = "Assumptions and model choice", table = safe_table(analysis()$assumptions)),
        list(title = "Full mixed-model ANOVA", table = safe_table(analysis()$full_anova)),
        list(title = "Additive mixed-model ANOVA", table = safe_table(analysis()$additive_anova)),
        list(title = "Clean split-plot ANOVA", table = safe_table(analysis()$split_anova)),
        list(title = "Main plot means", table = safe_table(analysis()$split_main_means)),
        list(title = "Subplot means", table = safe_table(analysis()$split_sub_means)),
        list(title = "Interaction means", table = safe_table(analysis()$split_interaction_means)),
        list(title = "LSD and CV summary", table = safe_table(analysis()$split_lsd_cv)),
        list(title = "Estimated means for main plot", table = safe_table(analysis()$emmeans_main)),
        list(title = "Estimated means for subplot", table = safe_table(analysis()$emmeans_sub)),
        list(title = "Estimated means for interaction", table = safe_table(analysis()$emmeans_interaction)),
        list(title = "Tukey comparisons for main plot", table = safe_table(analysis()$tukey_main)),
        list(title = "Tukey comparisons for subplot", table = safe_table(analysis()$tukey_sub)),
        list(title = "Compact letter display for main plot", table = safe_table(analysis()$cld_main)),
        list(title = "Compact letter display for subplot", table = safe_table(analysis()$cld_sub)),
        list(title = "Diagnostics", table = safe_table(analysis()$diagnostics)),
        list(title = "Final model summary", text = paste(analysis()$final_summary, collapse = "\n"))
      ), file)
    }
  )
}

correlation_regression_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "Correlation & Regression",
    "Explore numeric relationships using correlation, simple regression, and multiple regression.",
    "correlation-regression",
    tagList(
      fileInput("upload", "Upload CSV / TSV / XLSX", accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("data_input", "Or paste a table", value = correlation_example, rows = 11),
      uiOutput("response_ui"),
      uiOutput("predictor_ui"),
      selectInput("corr_method", "Correlation plot style", choices = c("Color tiles" = "color", "Circles" = "circle", "Numbers" = "number")),
      selectInput("corr_type", "Matrix area", choices = c("Lower triangle" = "lower", "Full matrix" = "full", "Upper triangle" = "upper"), selected = "lower"),
      selectInput("corr_order", "Variable order", choices = c("Input order" = "original", "Clustered" = "hclust")),
      selectInput("corr_palette", "Color palette", choices = c("Red-Blue" = "RdBu", "Purple-Orange" = "PuOr", "Green-Pink" = "PiYG"), selected = "RdBu"),
      checkboxInput("corr_sig_filter", "Hide insignificant correlations", value = TRUE),
      numericInput("corr_sig_level", "Significance level for plot", value = 0.05, min = 0.001, max = 0.2, step = 0.01),
      build_help_box("Expected data", c("Use numeric columns for correlation and regression.", "Choose one numeric response variable.", "Choose one or more numeric predictors.")),
      actionButton("analyze", "Run correlation and regression", class = "btn-primary"),
      tags$hr(),
      selectInput("csv_table", "CSV table to download", choices = c("Correlation matrix", "Coefficients", "Fit statistics", "Diagnostics")),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_corrplot", "Download correlation plot"),
      downloadButton("download_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(
      tabPanel("Correlation Plot", plotOutput("correlation_plot", height = "520px")),
      tabPanel("Correlation Matrix", tableOutput("correlation_table")),
      tabPanel("Regression Coefficients", tableOutput("coefficients_table")),
      tabPanel("Fit Statistics", tableOutput("fit_table")),
      tabPanel("Diagnostics", tableOutput("diagnostics_table")),
      tabPanel("Long Data View", tableOutput("long_data_table"))
    )
    ,
    nav_catalog = nav_catalog
  )
}

correlation_regression_server <- function(input, output, session) {
  err <- reactiveVal(NULL)
  dataset <- reactive(tryCatch(read_dataset_input(input$upload, input$data_input), error = function(e) NULL))

  output$response_ui <- renderUI({
    df <- dataset()
    numeric_cols <- if (is.null(df)) character(0) else names(df)[vapply(df, is.numeric, logical(1))]
    selectInput("response", "Response variable", choices = numeric_cols, selected = numeric_cols[1])
  })

  output$predictor_ui <- renderUI({
    df <- dataset()
    numeric_cols <- if (is.null(df)) character(0) else names(df)[vapply(df, is.numeric, logical(1))]
    default_predictors <- setdiff(numeric_cols, numeric_cols[1])[seq_len(max(0, min(length(numeric_cols) - 1, 2)))]
    checkboxGroupInput("predictors", "Predictor variables", choices = numeric_cols, selected = default_predictors)
  })

  analysis <- eventReactive(input$analyze, {
    err(NULL)
    tryCatch(run_correlation_regression(read_dataset_input(input$upload, input$data_input), input$response, input$predictors), error = function(e) {
      err(conditionMessage(e))
      NULL
    })
  })

  output$error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
  output$correlation_plot <- renderPlot({
    req(analysis())
    validate(need(requireNamespace("corrplot", quietly = TRUE), "Install the 'corrplot' package to view the correlation plot."))
    validate(need(requireNamespace("RColorBrewer", quietly = TRUE), "Install the 'RColorBrewer' package to view the correlation plot."))

    corr_matrix <- as.matrix(analysis()$correlation)
    p_matrix <- as.matrix(analysis()$correlation_p)
    palette_values <- colorRampPalette(RColorBrewer::brewer.pal(8, input$corr_palette))(200)
    label_position <- switch(input$corr_type, lower = "ld", upper = "td", full = "lt", "ld")

    corrplot::corrplot(
      corr_matrix,
      method = input$corr_method,
      type = input$corr_type,
      order = input$corr_order,
      col = palette_values,
      tl.pos = label_position,
      tl.col = "black",
      tl.cex = 0.9,
      tl.srt = 45,
      diag = TRUE,
      addgrid.col = "grey85",
      mar = c(0, 0, 2, 0),
      cl.pos = "r",
      cl.cex = 0.8,
      p.mat = if (isTRUE(input$corr_sig_filter)) p_matrix else NULL,
      sig.level = input$corr_sig_level,
      insig = if (isTRUE(input$corr_sig_filter)) "blank" else "pch",
      title = sprintf("Correlation Plot: %s", analysis()$formula)
    )
  })
  output$correlation_table <- renderTable({ req(analysis()); analysis()$correlation }, rownames = TRUE)
  output$coefficients_table <- renderTable({ req(analysis()); analysis()$coefficients }, rownames = FALSE)
  output$fit_table <- renderTable({ req(analysis()); analysis()$fit }, rownames = FALSE)
  output$diagnostics_table <- renderTable({ req(analysis()); analysis()$diagnostics }, rownames = FALSE)
  output$long_data_table <- renderTable({ req(analysis()); analysis()$dataset }, rownames = FALSE)

  output$download_csv <- downloadHandler(
    filename = function() sprintf("correlation-regression-%s.csv", gsub("[^a-z]+", "-", tolower(input$csv_table))),
    content = function(file) {
      req(analysis())
      table_map <- list("Correlation matrix" = analysis()$correlation, "Coefficients" = analysis()$coefficients, "Fit statistics" = analysis()$fit, "Diagnostics" = analysis()$diagnostics)
      write.csv(table_map[[input$csv_table]], file, row.names = FALSE)
    }
  )

  output$download_corrplot <- downloadHandler(
    filename = function() "correlation-plot.png",
    content = function(file) {
      req(analysis())
      validate(need(requireNamespace("corrplot", quietly = TRUE), "Install the 'corrplot' package to download the correlation plot."))
      validate(need(requireNamespace("RColorBrewer", quietly = TRUE), "Install the 'RColorBrewer' package to download the correlation plot."))

      corr_matrix <- as.matrix(analysis()$correlation)
      p_matrix <- as.matrix(analysis()$correlation_p)
      palette_values <- colorRampPalette(RColorBrewer::brewer.pal(8, input$corr_palette))(200)
      label_position <- switch(input$corr_type, lower = "ld", upper = "td", full = "lt", "ld")

      png(file, width = 2000, height = 2000, res = 300)
      on.exit(dev.off(), add = TRUE)
      corrplot::corrplot(
        corr_matrix,
        method = input$corr_method,
        type = input$corr_type,
        order = input$corr_order,
        col = palette_values,
        tl.pos = label_position,
        tl.col = "black",
        tl.cex = 1,
        tl.srt = 45,
        diag = TRUE,
        addgrid.col = "grey85",
        mar = c(0, 0, 2, 0),
        cl.pos = "r",
        cl.cex = 0.8,
        p.mat = if (isTRUE(input$corr_sig_filter)) p_matrix else NULL,
        sig.level = input$corr_sig_level,
        insig = if (isTRUE(input$corr_sig_filter)) "blank" else "pch",
        title = sprintf("Correlation Plot: %s", analysis()$formula)
      )
    }
  )

  output$download_report <- downloadHandler(
    filename = function() "correlation-regression-report.html",
    content = function(file) {
      req(analysis())
      save_html_report("Correlation and Regression Report", list(
        list(title = "Dataset summary", subtitle = paste(analysis()$report_note, sprintf("Corrplot style: %s, area: %s, order: %s.", input$corr_method, input$corr_type, input$corr_order)), table = head(analysis()$dataset, 20)),
        list(title = "Correlation matrix", table = analysis()$correlation),
        list(title = "Regression coefficients", table = analysis()$coefficients),
        list(title = "Fit statistics", table = analysis()$fit),
        list(title = "Diagnostics", table = analysis()$diagnostics)
      ), file)
    }
  )
}


# ============================================================
# MET STABILITY UI
# ============================================================
met_stability_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "MET Stability Analysis",
    "Multi-environment trial analysis: individual & combined ANOVA, AMMI, GGE, WAASB, BLUP-based stability indices, and simultaneous selection indices.",
    "met-stability",
    tagList(
      fileInput("met_upload", "Upload CSV / TSV / XLSX",
                accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("met_data_input", "Or paste a table", value = met_example, rows = 8),

      radioButtons(
        "met_mode", "Analysis mode",
        choices = c("Single trait" = "single", "Multi-trait batch" = "batch"),
        selected = "single",
        inline = TRUE
      ),
      uiOutput("met_gen_var_ui"),
      uiOutput("met_rep_var_ui"),
      uiOutput("met_trait_var_ui"),
      uiOutput("met_lower_traits_ui"),

      checkboxInput("met_use_sep_env",
                    "Build ENV from separate Season x Location columns", value = FALSE),
      conditionalPanel("input.met_use_sep_env",
        uiOutput("met_season_var_ui"),
        uiOutput("met_loc_var_ui")
      ),
      conditionalPanel("!input.met_use_sep_env",
        uiOutput("met_env_var_ui")
      ),

      numericInput("met_alpha", "Significance level",
                   value = 0.05, min = 0.001, max = 0.2, step = 0.01),

      build_help_box("Required data format", c(
        "Long format - one row per plot observation.",
        "Genotype: variety / line label.",
        "Environment: combined label (e.g. 2023_Delhi) OR use Season x Location mode.",
        "Rep: replication / block identifier.",
        "Trait: one numeric response column for single mode, or multiple numeric traits for batch mode."
      )),

      actionButton("met_run", "Run MET Analysis", class = "btn-primary"),
      tags$hr(),
      selectInput("met_csv_table", "CSV table to download",
                  choices = c("Genotype Means", "Combined ANOVA", "Over-Year ANOVA",
                              "AMMI IPCA", "AMMI PC Scores", "AMMI Stability",
                              "WAASB Scores", "BLUP Indices", "Parametric SSI",
                              "Culled SSI", "Top 10 All Traits", "Multi-Trait Index",
                              "Batch Errors")),
      downloadButton("met_download_csv",    "Download CSV"),
      downloadButton("met_download_xlsx",   "Download XLSX"),
      downloadButton("met_download_report", "Download HTML Report"),
      uiOutput("met_error_msg")
    ),
    tagList(
      div(class = "station-panel", uiOutput("met_cached_result_header")),
      analysis_tabs(
        tabPanel("Data Preview",
          DT::dataTableOutput("met_data_table")
        ),
        tabPanel("Individual ANOVA",
          uiOutput("met_env_selector_ui"),
          tags$hr(),
          tableOutput("met_ind_anova_table"),
          uiOutput("met_ind_anova_summary")
        ),
        tabPanel("Combined ANOVA",
          tableOutput("met_comb_anova_table"),
          uiOutput("met_comb_anova_summary")
        ),
        tabPanel("Over-Year ANOVA",
          uiOutput("met_year_anova_msg"),
          tableOutput("met_year_anova_table")
        ),
        tabPanel("Genotype Means",
          tableOutput("met_gen_means_table"),
          tags$br(),
          plotOutput("met_gen_means_plot", height = "400px")
        ),
        tabPanel("AMMI",
          tabsetPanel(
            tabPanel("AMMI ANOVA", tableOutput("met_ammi_anova_table")),
            tabPanel("IPCA Summary", tableOutput("met_ammi_ipca_table")),
            tabPanel("PC Scores", tableOutput("met_ammi_scores_table")),
            tabPanel("Stability Indices",
              p(class = "station-muted",
                "ASV: AMMI Stability Value | SIPC: Sum of absolute IPCAs | EV: Eigenvalue stability | ZA: Z-score average | WAAS: Weighted average absolute scores"),
              tableOutput("met_ammi_stab_table")
            )
          )
        ),
        tabPanel("AMMI Biplots",
          tabsetPanel(
            tabPanel("AMMI1 - Mean vs PC1", plotOutput("met_ammi1_plot", height = "520px")),
            tabPanel("AMMI2 - PC1 vs PC2",  plotOutput("met_ammi2_plot", height = "520px"))
          ),
        ),
        tabPanel("GGE Biplots",
          tabsetPanel(
            tabPanel("Mean vs Stability",  plotOutput("met_gge_mean_stab_plot", height = "520px")),
            tabPanel("Which-Won-Where",    plotOutput("met_gge_www_plot",       height = "520px")),
            tabPanel("Discriminativeness", plotOutput("met_gge_disc_plot",      height = "520px")),
            tabPanel("Env. Relationship",  plotOutput("met_gge_env_plot",       height = "520px"))
          )
        ),
        tabPanel("WAASB / WAASBY",
          tableOutput("met_waasb_table"),
          tags$br(),
          plotOutput("met_waasby_plot", height = "420px")
        ),
        tabPanel("BLUPs",
          p(class = "station-muted",
            "HMGV: Harmonic Mean of Genotypic Values | RPGV: Relative Performance of Genotypic Values | HMRPGV: Harmonic Mean of RPGV (combined stability + yield index)"),
          tableOutput("met_blup_table"),
          tags$br(),
          plotOutput("met_blup_plot", height = "400px")
        ),
        tabPanel("SSI",
          tabsetPanel(
            tabPanel("Parametric SSI (P-SSI)",
              p(class = "station-muted",
                "Weighted index: 70% yield + 30% stability. Higher P-SSI = better."),
              tableOutput("met_pssi_table")
            ),
            tabPanel("Non-Parametric SSI (NP-SSI)",
              p(class = "station-muted",
                "Rank-sum of yield rank + stability rank. Lower NP-SSI = better."),
              tableOutput("met_npssi_table")
            ),
            tabPanel("Culled SSI (C-SSI)",
              p(class = "station-muted",
                "Stable genotypes (WAASB < mean) ranked by yield after culling unstable entries."),
              tableOutput("met_cssi_table")
            )
          )
        ),
        tabPanel("Batch Summary",
          tabsetPanel(
            tabPanel("Top 10 by Trait", tableOutput("met_batch_top_table")),
            tabPanel("Multi-Trait Index", tableOutput("met_batch_index_table")),
            tabPanel("Trait Errors", tableOutput("met_batch_errors_table"))
          ),
        )
      )
    ),
    nav_catalog = nav_catalog
  )
}

# ============================================================
# MET STABILITY SERVER
# ============================================================
met_stability_server <- function(input, output, session) {

  err <- reactiveVal(NULL)

  dataset <- reactive({
    tryCatch(
      read_dataset_input(input$met_upload, input$met_data_input),
      error = function(e) { err(conditionMessage(e)); NULL }
    )
  })

  all_cols     <- reactive({ df <- dataset(); if (is.null(df)) character(0) else names(df) })
  numeric_cols <- reactive({
    df <- dataset()
    if (is.null(df)) character(0) else names(df)[vapply(df, is.numeric, logical(1))]
  })

  met_default_lower_traits <- function(cols) {
    intersect(c("DFF50", "DPM"), cols)
  }

  met_data_source_signature <- reactive({
    upload <- input$met_upload
    if (!is.null(upload) && nzchar(upload$datapath %||% "")) {
      return(list(
        type = "upload",
        name = upload$name,
        size = upload$size,
        type_hint = upload$type
      ))
    }
    pasted <- input$met_data_input %||% ""
    list(
      type = "pasted",
      length = nchar(pasted),
      head = substr(pasted, 1, 120),
      tail = substr(pasted, max(1, nchar(pasted) - 119), nchar(pasted))
    )
  })

  current_met_signature <- reactive({
    lower_traits <- input$met_lower_traits %||% character(0)
    use_sep_env <- isTRUE(input$met_use_sep_env)
    env_col_use <- if (use_sep_env) "ENV_COMBINED" else input$met_env_col
    traits <- if (identical(input$met_mode, "batch")) input$met_trait_cols else input$met_trait_col

    met_run_signature(
      mode = input$met_mode %||% "single",
      data_source = met_data_source_signature(),
      gen_col = input$met_gen_col,
      env_col = env_col_use,
      rep_col = input$met_rep_col,
      trait_col = input$met_trait_col,
      trait_cols = traits,
      lower_traits = lower_traits,
      alpha = input$met_alpha,
      use_sep_env = use_sep_env,
      season_col = if (use_sep_env) input$met_season_col else NULL,
      loc_col = if (use_sep_env) input$met_loc_col else NULL
    )
  })

  output$met_gen_var_ui <- renderUI({
    cols <- all_cols(); if (length(cols) == 0) return(NULL)
    sel  <- if ("GEN" %in% cols) "GEN" else if ("Genotype" %in% cols) "Genotype" else cols[1]
    selectInput("met_gen_col", "Genotype column", choices = cols, selected = sel)
  })
  output$met_rep_var_ui <- renderUI({
    cols <- all_cols(); if (length(cols) == 0) return(NULL)
    sel  <- if ("REP" %in% cols) "REP" else if ("Rep" %in% cols) "Rep" else
            if ("Replication" %in% cols) "Replication" else cols[min(3, length(cols))]
    selectInput("met_rep_col", "Replication column", choices = cols, selected = sel)
  })
  output$met_trait_var_ui <- renderUI({
    cols <- numeric_cols()
    if (length(cols) == 0) return(div(class = "alert alert-warning", "No numeric columns detected."))
    tagList(
      conditionalPanel(
        "input.met_mode == 'single'",
        selectInput("met_trait_col", "Trait (response) column", choices = cols, selected = cols[1])
      ),
      conditionalPanel(
        "input.met_mode == 'batch'",
        selectizeInput("met_trait_cols", "Traits for batch analysis",
                       choices = cols, selected = cols,
                       multiple = TRUE,
                       options = list(plugins = list("remove_button")))
      )
    )
  })
  output$met_lower_traits_ui <- renderUI({
    cols <- numeric_cols()
    if (length(cols) == 0) return(NULL)
    selectizeInput(
      "met_lower_traits", "Lower-is-better traits",
      choices = cols,
      selected = met_default_lower_traits(cols),
      multiple = TRUE,
      options = list(plugins = list("remove_button"))
    )
  })
  output$met_env_var_ui <- renderUI({
    cols <- all_cols(); if (length(cols) == 0) return(NULL)
    sel  <- if ("ENV" %in% cols) "ENV" else if ("Environment" %in% cols) "Environment" else cols[min(2, length(cols))]
    selectInput("met_env_col", "Environment column", choices = cols, selected = sel)
  })
  output$met_season_var_ui <- renderUI({
    cols <- all_cols(); if (length(cols) == 0) return(NULL)
    sel  <- if ("SEASON" %in% cols) "SEASON" else if ("Season" %in% cols) "Season" else
            if ("Year" %in% cols) "Year" else cols[1]
    selectInput("met_season_col", "Season / Year column", choices = cols, selected = sel)
  })
  output$met_loc_var_ui <- renderUI({
    cols <- all_cols(); if (length(cols) == 0) return(NULL)
    sel  <- if ("LOC" %in% cols) "LOC" else if ("Location" %in% cols) "Location" else cols[min(3, length(cols))]
    selectInput("met_loc_col", "Location column", choices = cols, selected = sel)
  })

  analysis <- eventReactive(input$met_run, {
    err(NULL)
    tryCatch({
      df             <- read_dataset_input(input$met_upload, input$met_data_input)
      season_col_use <- NULL
      loc_col_use    <- NULL
      env_col_use    <- input$met_env_col
      lower_traits   <- input$met_lower_traits %||% character(0)

      if (isTRUE(input$met_use_sep_env)) {
        req(input$met_season_col, input$met_loc_col)
        df$ENV_COMBINED <- interaction(df[[input$met_season_col]], df[[input$met_loc_col]], sep = "_", drop = TRUE)
        env_col_use     <- "ENV_COMBINED"
        season_col_use  <- input$met_season_col
        loc_col_use     <- input$met_loc_col
      }

      if (identical(input$met_mode, "batch")) {
        req(input$met_trait_cols)
        traits <- input$met_trait_cols
        direction_map <- stats::setNames(ifelse(traits %in% lower_traits, "l", "h"), traits)
        batch <- run_met_batch_analysis(
          data          = df,
          gen_col       = input$met_gen_col,
          env_col       = env_col_use,
          rep_col       = input$met_rep_col,
          trait_cols    = traits,
          direction_map = direction_map,
          season_col    = season_col_use,
          loc_col       = loc_col_use,
          alpha         = input$met_alpha
        )
        if (length(batch$results) == 0) {
          stop("Batch analysis failed for all selected traits.")
        }
        list(
          mode = "batch",
          batch = batch,
          signature = current_met_signature(),
          run_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
          trait_cols = traits,
          direction_map = direction_map,
          columns = list(
            gen_col = input$met_gen_col,
            env_col = env_col_use,
            rep_col = input$met_rep_col,
            season_col = season_col_use,
            loc_col = loc_col_use
          ),
          alpha = input$met_alpha
        )
      } else {
        req(input$met_trait_col)
        direction <- if (input$met_trait_col %in% lower_traits) "l" else "h"
        result <- run_met_analysis(
          data       = df,
          gen_col    = input$met_gen_col,
          env_col    = env_col_use,
          rep_col    = input$met_rep_col,
          trait_col  = input$met_trait_col,
          season_col = season_col_use,
          loc_col    = loc_col_use,
          alpha      = input$met_alpha,
          direction  = direction
        )
        list(
          mode = "single",
          result = result,
          signature = current_met_signature(),
          run_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
          trait_col = input$met_trait_col,
          direction_map = stats::setNames(direction, input$met_trait_col),
          columns = list(
            gen_col = input$met_gen_col,
            env_col = env_col_use,
            rep_col = input$met_rep_col,
            season_col = season_col_use,
            loc_col = loc_col_use
          ),
          alpha = input$met_alpha
        )
      }
    }, error = function(e) { err(conditionMessage(e)); NULL })
  })

  current_result <- reactive({
    payload <- analysis()
    req(payload)
    met_select_cached_result(payload, input$met_batch_view_trait)
  })

  batch_result <- reactive({
    payload <- analysis()
    if (is.null(payload) || !identical(payload$mode, "batch")) return(NULL)
    payload$batch
  })

  output$met_error_msg <- renderUI({
    payload <- analysis()
    messages <- list()
    if (!is.null(err())) {
      messages <- c(messages, list(div(class = "alert alert-danger", tags$b("Error: "), err())))
    }
    if (!is.null(payload) && identical(payload$mode, "batch") && nrow(payload$batch$errors) > 0) {
      messages <- c(messages, list(div(class = "alert alert-warning",
        tags$b("Some traits failed: "),
        paste(payload$batch$errors$Trait, collapse = ", ")
      )))
    }
    if (!is.null(payload) && met_signature_changed(payload$signature, current_met_signature())) {
      messages <- c(messages, list(div(class = "alert alert-warning",
        tags$b("Displayed results are from the last completed run. "),
        "Inputs have changed; click Run MET Analysis to refresh cached results."
      )))
    }
    res <- tryCatch(current_result(), error = function(e) NULL)
    if (!is.null(res) && length(res$warnings) > 0) {
      messages <- c(messages, list(div(class = "alert alert-info",
        tags$b("Model notes: "),
        paste(unique(res$warnings), collapse = " | ")
      )))
    }
    if (length(messages) == 0) return(NULL)
    do.call(tagList, messages)
  })

  output$met_cached_result_header <- renderUI({
    payload <- analysis()
    if (is.null(payload)) {
      return(div(class = "station-muted", "Run MET Analysis to generate results."))
    }
    selected <- isolate(input$met_batch_view_trait)
    traits <- met_payload_traits(payload)
    if (!is.null(selected) && selected %in% traits) {
      selected_trait <- selected
    } else {
      selected_trait <- traits[1]
    }

    status <- met_payload_status_text(payload, selected_trait)
    stale <- met_signature_changed(payload$signature, current_met_signature())

    if (identical(payload$mode, "batch")) {
      tagList(
        fluidRow(
          column(
            5,
            selectInput(
              "met_batch_view_trait",
              "Computed trait to view",
              choices = traits,
              selected = selected_trait
            )
          ),
          column(
            7,
            div(class = "station-muted", status),
            if (isTRUE(stale)) div(class = "alert alert-warning",
              "Inputs changed after this batch run. The displayed trait output is cached from the last completed run."
            )
          )
        )
      )
    } else {
      tagList(
        div(class = "station-muted", status),
        if (isTRUE(stale)) div(class = "alert alert-warning",
          "Inputs changed after this run. The displayed output is cached from the last completed run."
        )
      )
    }
  })

  output$met_data_table <- DT::renderDataTable({
    req(current_result()); current_result()$dataset
  }, options = list(pageLength = 10, scrollX = TRUE))

  output$met_env_selector_ui <- renderUI({
    req(current_result())
    envs <- names(current_result()$ind_anova)
    selectInput("met_sel_env", "Select environment to view", choices = envs, selected = envs[1])
  })
  output$met_ind_anova_table <- renderTable({
    req(current_result(), input$met_sel_env); current_result()$ind_anova[[input$met_sel_env]]
  }, rownames = FALSE)
  output$met_ind_anova_summary <- renderUI({
    req(current_result(), input$met_sel_env)
    tbl <- current_result()$ind_anova[[input$met_sel_env]]
    cv  <- attr(tbl, "cv_pct"); gm <- attr(tbl, "grand_mean")
    if (!is.null(cv) && !is.null(gm))
      div(class = "station-muted", sprintf("Grand Mean: %.4f  |  CV: %.2f%%", gm, cv))
  })

  output$met_comb_anova_table <- renderTable({ req(current_result()); current_result()$comb_anova }, rownames = FALSE)
  output$met_comb_anova_summary <- renderUI({
    req(current_result())
    tbl <- current_result()$comb_anova; cv <- attr(tbl, "cv_pct"); gm <- attr(tbl, "grand_mean")
    if (!is.null(cv) && !is.null(gm))
      div(class = "station-muted", sprintf("Grand Mean: %.4f  |  CV: %.2f%%", gm, cv))
  })

  output$met_year_anova_msg <- renderUI({
    req(current_result())
    if (is.null(current_result()$year_anova))
      div(class = "alert alert-info",
          "Over-Year ANOVA is available only when Season and Location columns are specified.",
          "Enable 'Build ENV from separate Season x Location columns' in the sidebar.")
  })
  output$met_year_anova_table <- renderTable({ req(current_result()); current_result()$year_anova }, rownames = FALSE)

  output$met_gen_means_table <- renderTable({ req(current_result()); current_result()$gen_means }, rownames = FALSE)
  output$met_gen_means_plot  <- renderPlot({
    req(current_result())
    gm <- current_result()$gen_means
    gm$Genotype <- factor(gm$Genotype, levels = rev(gm$Genotype))
    ggplot2::ggplot(gm, ggplot2::aes(x = Genotype, y = Mean, fill = Mean)) +
      ggplot2::geom_col(alpha = 0.9) +
      ggplot2::geom_errorbar(ggplot2::aes(ymin = Mean - SD, ymax = Mean + SD), width = 0.3, color = "grey30") +
      ggplot2::coord_flip() +
      ggplot2::scale_fill_gradient(low = "#a8d5a2", high = "#1f4d3b") +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(legend.position = "none") +
      ggplot2::labs(title = paste("Genotype means +/-SD for", current_result()$trait), x = "Genotype", y = "Mean")
  })

  output$met_ammi_anova_table  <- renderTable({ req(current_result()); current_result()$ammi$anova }, rownames = FALSE)
  output$met_ammi_ipca_table   <- renderTable({ req(current_result()); current_result()$ammi$ipca_summary }, rownames = FALSE)
  output$met_ammi_scores_table <- renderTable({ req(current_result()); current_result()$ammi$pc_scores }, rownames = FALSE)
  output$met_ammi_stab_table   <- renderTable({ req(current_result()); current_result()$ammi$stability }, rownames = FALSE)

  output$met_ammi1_plot <- renderPlot({
    req(current_result()); mod <- current_result()$ammi$mod
    validate(need(!is.null(mod), "AMMI model not available. Check data and re-run."))
    metan::plot_scores(mod, type = 1)
  })
  output$met_ammi2_plot <- renderPlot({
    req(current_result()); mod <- current_result()$ammi$mod
    validate(need(!is.null(mod), "AMMI model not available. Check data and re-run."))
    metan::plot_scores(mod, type = 2)
  })

  make_gge_plot <- function(type_num) {
    renderPlot({
      req(current_result()); mod <- current_result()$gge$mod
      validate(need(!is.null(mod), "GGE model not available. Check data and re-run."))
      plot(mod, type = type_num)
    })
  }
  output$met_gge_mean_stab_plot <- make_gge_plot(2)
  output$met_gge_www_plot       <- make_gge_plot(3)
  output$met_gge_disc_plot      <- make_gge_plot(4)
  output$met_gge_env_plot       <- make_gge_plot(6)

  output$met_waasb_table <- renderTable({ req(current_result()); current_result()$waasb$scores }, rownames = FALSE)
  output$met_waasby_plot <- renderPlot({
    req(current_result()); mod <- current_result()$waasb$mod
    validate(need(!is.null(mod), "WAASB model not available. Check data and re-run."))
    plot_fun <- tryCatch(getExportedValue("metan", "plot_waasby"), error = function(e) NULL)
    if (is.function(plot_fun)) plot_fun(mod) else metan::plot_scores(mod, type = 3)
  })

  output$met_blup_table <- renderTable({ req(current_result()); current_result()$blup }, rownames = FALSE)
  output$met_blup_plot  <- renderPlot({
    req(current_result()); blup <- current_result()$blup
    validate(need(!is.null(blup) && "HMRPGV" %in% names(blup), "BLUP indices not available."))
    blup     <- blup[!is.na(blup$HMRPGV), ]
    blup$GEN <- factor(blup$GEN, levels = rev(blup$GEN[order(blup$Rank_HMRPGV)]))
    ggplot2::ggplot(blup, ggplot2::aes(x = GEN, y = HMRPGV, fill = HMRPGV)) +
      ggplot2::geom_col(alpha = 0.9) +
      ggplot2::coord_flip() +
      ggplot2::scale_fill_gradient(low = "#a8d5a2", high = "#1f4d3b") +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(legend.position = "none") +
      ggplot2::labs(title = "HMRPGV - Stability-adjusted BLUP ranking", x = "Genotype", y = "HMRPGV")
  })

  output$met_pssi_table <- renderTable({
    req(current_result()); ssi <- current_result()$ssi$full; if (is.null(ssi)) return(NULL)
    cols <- intersect(c("GEN","Mean","WAASB","WAASBY","P_SSI","Rank_P_SSI"), names(ssi))
    ssi[, cols, drop = FALSE]
  }, rownames = FALSE)
  output$met_npssi_table <- renderTable({
    req(current_result()); ssi <- current_result()$ssi$full; if (is.null(ssi)) return(NULL)
    ssi  <- ssi[order(ssi$Rank_NP_SSI), ]
    cols <- intersect(c("GEN","Mean","WAASB","Rank_Yield","Rank_Stability","NP_SSI","Rank_NP_SSI"), names(ssi))
    ssi[, cols, drop = FALSE]
  }, rownames = FALSE)
  output$met_cssi_table <- renderTable({ req(current_result()); current_result()$ssi$culled }, rownames = FALSE)

  output$met_batch_top_table <- renderTable({
    batch <- batch_result()
    if (is.null(batch)) return(data.frame(Message = "Run multi-trait batch mode to see this summary."))
    batch$top_summary
  }, rownames = FALSE)
  output$met_batch_index_table <- renderTable({
    batch <- batch_result()
    if (is.null(batch)) return(data.frame(Message = "Run multi-trait batch mode to see this summary."))
    batch$multi_trait_index
  }, rownames = FALSE)
  output$met_batch_errors_table <- renderTable({
    batch <- batch_result()
    if (is.null(batch)) return(data.frame(Message = "Run multi-trait batch mode to see trait errors."))
    if (nrow(batch$errors) == 0) return(data.frame(Message = "No trait-level errors."))
    batch$errors
  }, rownames = FALSE)

  table_for_download <- function() {
    req(current_result())
    res <- current_result()
    batch <- batch_result()
    tbl_map <- list(
      "Genotype Means" = res$gen_means,
      "Combined ANOVA" = res$comb_anova,
      "Over-Year ANOVA" = res$year_anova,
      "AMMI IPCA" = res$ammi$ipca_summary,
      "AMMI PC Scores" = res$ammi$pc_scores,
      "AMMI Stability" = res$ammi$stability,
      "WAASB Scores" = res$waasb$scores,
      "BLUP Indices" = res$blup,
      "Parametric SSI" = res$ssi$full,
      "Culled SSI" = res$ssi$culled,
      "Top 10 All Traits" = if (!is.null(batch)) batch$top_summary else NULL,
      "Multi-Trait Index" = if (!is.null(batch)) batch$multi_trait_index else NULL,
      "Batch Errors" = if (!is.null(batch)) batch$errors else NULL
    )
    tbl_map[[input$met_csv_table]]
  }

  output$met_download_csv <- downloadHandler(
    filename = function() paste0("met-", gsub("[^a-z]+", "-", tolower(input$met_csv_table)), ".csv"),
    content  = function(file) {
      tbl <- table_for_download()
      validate(need(!is.null(tbl), "Selected table is not available for this dataset."))
      write.csv(tbl, file, row.names = FALSE)
    }
  )

  output$met_download_xlsx <- downloadHandler(
    filename = function() {
      res <- current_result()
      paste0("met-stability-", gsub("[^A-Za-z0-9]+", "-", res$trait), ".xlsx")
    },
    content = function(file) {
      validate(need(requireNamespace("writexl", quietly = TRUE), "Install the writexl package to export XLSX files."))
      res <- current_result()
      batch <- batch_result()
      tables <- if (!is.null(batch)) met_all_batch_result_tables(batch, res, include_all_traits = TRUE) else met_result_tables(res)
      names(tables) <- met_safe_sheet_names(names(tables))
      writexl::write_xlsx(tables, file)
    }
  )

  output$met_download_report <- downloadHandler(
    filename = function() "met-stability-report.html",
    content  = function(file) {
      req(current_result()); res <- current_result(); batch <- batch_result()
      sections <- list(
        list(title = "Analysis summary",                  text  = res$report_note),
        list(title = "Genotype means",                    table = res$gen_means),
        list(title = "Combined ANOVA",                    table = res$comb_anova),
        list(title = "AMMI IPCA summary",                 table = res$ammi$ipca_summary),
        list(title = "AMMI stability indices",            table = res$ammi$stability),
        list(title = "WAASB / WAASBY scores",             table = res$waasb$scores),
        list(title = "BLUP indices (HMGV, RPGV, HMRPGV)", table = res$blup),
        list(title = "Parametric SSI",                    table = res$ssi$full),
        list(title = "Culled SSI",                        table = res$ssi$culled)
      )
      if (!is.null(res$year_anova))
        sections <- c(sections, list(list(title = "Over-Year ANOVA", table = res$year_anova)))
      if (!is.null(batch)) {
        sections <- c(sections, list(
          list(title = "Top 10 genotypes across traits", table = batch$top_summary),
          list(title = "Multi-trait top genotype summary", table = batch$multi_trait_index),
          list(title = "Batch trait errors", table = batch$errors)
        ))
      }
      save_html_report(paste("MET Stability Report -", res$trait), sections, file)
    }
  )
}
