portal_ui <- function(catalog = app_catalog) {
  fluidPage(
    tags$head(tags$style(research_station_styles)),
    div(class = "station-hero", h1("Research Analytics Station"), p("Cloud-ready Shiny suite for agricultural and experimental data analysis."), nav_links("portal", catalog)),
    fluidRow(
      column(6, div(class = "station-card", h3("How researchers will use this suite"), p("Choose a module, upload CSV/XLSX data or paste a table, review assumptions, then export CSV tables, HTML reports, and randomized design plans where applicable."), tags$ul(tags$li("Public link access for v1."), tags$li("Shared validation and reporting patterns across modules."), tags$li("Deployment assets included for Docker, nginx, and Shiny Server.")))),
      column(6, div(class = "station-card", h3("Support"), p("Version 1.0 deployment scaffold"), p("Recommended host: single cloud VM with Docker Compose."), p("Update this section with station support contacts before production."), p("Modules are linked below.")))
    ),
    fluidRow(lapply(catalog[-1], function(app) {
      column(6, div(class = "station-card", h3(app$label), p(switch(app$key, "design-analyzer" = "Generate randomized field layouts and allocation tables for CRD, RBD, split-plot, strip-plot, and augmented RCBD experiments.", "crd-rbd" = "Single-factor CRD and RBD analysis with ANOVA, configurable post-hoc tests, and treatment plots.", "factorial-design" = "Two-factor factorial CRD and RBD analysis with EDA, diagnostics, emmeans, and post-hoc comparisons.", "pooled-anova" = "Pool trials across years or seasons after homogeneity checks.", "split-plot" = "Analyze split-plot experiments with correct strata.", "correlation-regression" = "Explore correlation, simple regression, and multiple regression.", "descriptive-statistics" = "Summarize variables, inspect distributions, and run normality diagnostics.", "compare-means" = "Run one-sample, two-sample, Welch and paired t-tests with visual comparison charts.")), tags$a(class = "btn btn-success", href = app$path, "Open Module")))
    }))
  )
}

portal_server <- function(input, output, session) {}

design_analyzer_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "Design Analyzer",
    "Generate randomized layout plans for common agricultural experiments and export the allocation table.",
    "design-analyzer",
    tagList(
      selectInput("design_type", "Design type", choices = c("CRD", "RBD", "Split Plot", "Augmented RCBD", "Strip Plot")),
      conditionalPanel("input.design_type == 'CRD' || input.design_type == 'RBD'",
        numericInput("trt", "Number of treatments", value = 4, min = 2)
      ),
      conditionalPanel("input.design_type == 'CRD' || input.design_type == 'RBD' || input.design_type == 'Split Plot' || input.design_type == 'Augmented RCBD' || input.design_type == 'Strip Plot'",
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
      build_help_box("What this module does", c("Creates a randomized fieldbook similar to the grapesAgri layout workflow.", "Use the seed to reproduce a layout exactly.", "Download the allocation table for field teams or reporting.")),
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

    if (identical(plan$design, "CRD")) {
      desplot::desplot(
        form = row ~ col,
        data = plan$plot_data,
        text = label,
        out1 = row,
        out2 = col,
        main = "CRD Layout",
        cex = 1.1
      )
    } else if (identical(plan$design, "RBD")) {
      desplot::desplot(
        form = block_num ~ plot_num,
        data = plan$plot_data,
        text = label,
        out1 = block_num,
        out2 = plot_num,
        out2.gpar = list(col = "#547d43"),
        main = "RBD Layout",
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
        form = rep_num ~ main_num + sub_num,
        data = plan$plot_data,
        text = label,
        out1 = rep_num,
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
      downloadButton("download_report", "Download HTML report"),
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
  output$treatment_plot <- renderPlot({
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

  output$download_csv <- downloadHandler(
    filename = function() sprintf("crd-rbd-%s.csv", gsub("[^a-z]+", "-", tolower(input$csv_table))),
    content = function(file) {
      req(analysis())
      table_map <- list("Long data" = analysis()$dataset, "ANOVA" = analysis()$anova, "Key statistics" = analysis()$stats, "Means" = analysis()$means, "Treatment summary" = analysis()$treatment_summary, "Groups" = analysis()$groups)
      write.csv(table_map[[input$csv_table]], file, row.names = FALSE)
    }
  )

  output$download_report <- downloadHandler(
    filename = function() "crd-rbd-report.html",
    content = function(file) {
      req(analysis())
      save_html_report("CRD / RBD Report", list(
        list(title = "Treatment summary with confidence intervals", table = analysis()$treatment_summary),
        list(title = "ANOVA table", table = analysis()$anova),
        list(title = "Key statistics", table = analysis()$stats),
        list(title = "Inference", text = analysis()$inference),
        list(title = sprintf("%s summary", analysis()$comparison_method), table = analysis()$lsd_stats),
        list(title = "Letter grouping", table = analysis()$groups),
        list(title = "Dataset summary", subtitle = analysis()$report_note, table = head(analysis()$dataset, 20))
      ), file)
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
      build_help_box("Expected columns", c("Use Rep/MainPlot/SubPlot/Value or W/A/B/Y.", "Rep or W is the block/random whole-plot factor.", "MainPlot/A and SubPlot/B are the treatment factors.")),
      actionButton("analyze", "Run split-plot analysis", class = "btn-primary"),
      tags$hr(),
      selectInput("csv_table", "CSV table to download", choices = c("Full ANOVA", "Additive ANOVA", "EMMeans main plot", "EMMeans subplot", "Tukey main plot", "Tukey subplot", "CLD main plot", "CLD subplot", "Diagnostics")),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(
      tabPanel("EDA", verbatimTextOutput("data_summary_text"), plotOutput("boxplot_plot", height = "320px"), plotOutput("interaction_plot_chart", height = "320px")),
      tabPanel("Model ANOVA", tableOutput("full_anova_table"), tags$br(), tableOutput("additive_anova_table"), tags$br(), tableOutput("assumptions_table")),
      tabPanel("Diagnostics", verbatimTextOutput("final_summary_text"), plotOutput("diagnostic_scatter_plot", height = "320px"), plotOutput("residual_qq_plot", height = "320px"), plotOutput("random_effects_qq_plot", height = "320px"), tableOutput("diagnostics_table")),
      tabPanel("Estimated Means", tableOutput("emmeans_main_table"), tags$br(), tableOutput("emmeans_sub_table"), tags$br(), tableOutput("emmeans_interaction_table"), plotOutput("lsmean_main_plot_chart", height = "320px"), plotOutput("lsmean_sub_plot_chart", height = "320px")),
      tabPanel("Post-hoc", tableOutput("tukey_main_table"), tags$br(), tableOutput("tukey_sub_table"), tags$br(), tableOutput("cld_main_table"), tags$br(), tableOutput("cld_sub_table")),
      tabPanel("Long Data View", tableOutput("long_data_table"))
    )
    ,
    nav_catalog = nav_catalog
  )
}

split_plot_server <- function(input, output, session) {
  err <- reactiveVal(NULL)
  analysis <- eventReactive(input$analyze, {
    err(NULL)
    tryCatch(run_split_plot(read_dataset_input(input$upload, input$data_input), input$alpha), error = function(e) {
      err(conditionMessage(e))
      NULL
    })
  })

  output$error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
  output$data_summary_text <- renderText({ req(analysis()); paste(analysis()$data_summary, collapse = "\n") })
  output$full_anova_table <- renderTable({ req(analysis()); analysis()$full_anova }, rownames = FALSE)
  output$additive_anova_table <- renderTable({ req(analysis()); analysis()$additive_anova }, rownames = FALSE)
  output$assumptions_table <- renderTable({ req(analysis()); analysis()$assumptions }, rownames = FALSE)
  output$final_summary_text <- renderText({ req(analysis()); paste(analysis()$final_summary, collapse = "\n") })
  output$emmeans_main_table <- renderTable({ req(analysis()); analysis()$emmeans_main }, rownames = FALSE)
  output$emmeans_sub_table <- renderTable({ req(analysis()); analysis()$emmeans_sub }, rownames = FALSE)
  output$emmeans_interaction_table <- renderTable({ req(analysis()); analysis()$emmeans_interaction }, rownames = FALSE)
  output$tukey_main_table <- renderTable({ req(analysis()); analysis()$tukey_main }, rownames = FALSE)
  output$tukey_sub_table <- renderTable({ req(analysis()); analysis()$tukey_sub }, rownames = FALSE)
  output$cld_main_table <- renderTable({ req(analysis()); analysis()$cld_main }, rownames = FALSE)
  output$cld_sub_table <- renderTable({ req(analysis()); analysis()$cld_sub }, rownames = FALSE)
  output$diagnostics_table <- renderTable({ req(analysis()); analysis()$diagnostics }, rownames = FALSE)
  output$long_data_table <- renderTable({ req(analysis()); analysis()$dataset }, rownames = FALSE)
  output$boxplot_plot <- renderPlot({ req(analysis()); print(analysis()$boxplot_obj) })
  output$interaction_plot_chart <- renderPlot({ req(analysis()); print(analysis()$interaction_plot) })
  output$lsmean_main_plot_chart <- renderPlot({ req(analysis()); print(analysis()$lsmean_main_plot) })
  output$lsmean_sub_plot_chart <- renderPlot({ req(analysis()); print(analysis()$lsmean_sub_plot) })
  output$diagnostic_scatter_plot <- renderPlot({
    req(analysis())
    plot(analysis()$fitted_final, analysis()$residuals_final, xlab = "Fitted values", ylab = "Residuals", main = "Residuals vs Fitted")
    abline(h = 0, lty = 2, col = "red")
  })
  output$residual_qq_plot <- renderPlot({
    req(analysis())
    qqnorm(analysis()$residuals_final, main = "Residual Q-Q Plot")
    qqline(analysis()$residuals_final, col = "red")
  })
  output$random_effects_qq_plot <- renderPlot({
    req(analysis())
    random_vals <- analysis()$random_effects[[analysis()$random_effect_column]]
    qqnorm(random_vals, main = "Random Effects Q-Q Plot")
    qqline(random_vals, col = "red")
  })

  output$download_csv <- downloadHandler(
    filename = function() sprintf("split-plot-%s.csv", gsub("[^a-z]+", "-", tolower(input$csv_table))),
    content = function(file) {
      req(analysis())
      table_map <- list(
        "Full ANOVA" = analysis()$full_anova,
        "Additive ANOVA" = analysis()$additive_anova,
        "EMMeans main plot" = analysis()$emmeans_main,
        "EMMeans subplot" = analysis()$emmeans_sub,
        "Tukey main plot" = analysis()$tukey_main,
        "Tukey subplot" = analysis()$tukey_sub,
        "CLD main plot" = analysis()$cld_main,
        "CLD subplot" = analysis()$cld_sub,
        "Diagnostics" = analysis()$diagnostics
      )
      write.csv(table_map[[input$csv_table]], file, row.names = FALSE)
    }
  )

  output$download_report <- downloadHandler(
    filename = function() "split-plot-report.html",
    content = function(file) {
      req(analysis())
      save_html_report("Split Plot Report", list(
        list(title = "Dataset summary", subtitle = analysis()$report_note, table = head(analysis()$dataset, 20)),
        list(title = "Assumptions and model choice", table = analysis()$assumptions),
        list(title = "Full mixed-model ANOVA", table = analysis()$full_anova),
        list(title = "Additive mixed-model ANOVA", table = analysis()$additive_anova),
        list(title = "Estimated means for main plot", table = analysis()$emmeans_main),
        list(title = "Estimated means for subplot", table = analysis()$emmeans_sub),
        list(title = "Tukey comparisons for main plot", table = analysis()$tukey_main),
        list(title = "Compact letter display for main plot", table = analysis()$cld_main),
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
