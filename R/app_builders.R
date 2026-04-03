portal_ui <- function(catalog = app_catalog) {
  fluidPage(
    tags$head(tags$style(research_station_styles)),
    div(class = "station-hero", h1("Research Analytics Station"), p("Cloud-ready Shiny suite for agricultural and experimental data analysis."), nav_links("portal", catalog)),
    fluidRow(
      column(6, div(class = "station-card", h3("How researchers will use this suite"), p("Choose a module, upload CSV/XLSX data or paste a table, review assumptions, then export CSV tables and HTML reports."), tags$ul(tags$li("Public link access for v1."), tags$li("Shared validation and reporting patterns across modules."), tags$li("Deployment assets included for Docker, nginx, and Shiny Server.")))),
      column(6, div(class = "station-card", h3("Support"), p("Version 1.0 deployment scaffold"), p("Recommended host: single cloud VM with Docker Compose."), p("Update this section with station support contacts before production."), p("Modules are linked below.")))
    ),
    fluidRow(lapply(catalog[-1], function(app) {
      column(6, div(class = "station-card", h3(app$label), p(switch(app$key, "crd-rbd" = "Single-factor CRD and RBD analysis with ANOVA, LSD, and confidence summaries.", "factorial-design" = "Two-factor factorial CRD and RBD analysis with EDA, diagnostics, emmeans, and post-hoc comparisons.", "pooled-anova" = "Pool trials across years or seasons after homogeneity checks.", "split-plot" = "Analyze split-plot experiments with correct strata.", "correlation-regression" = "Explore correlation, simple regression, and multiple regression.")), tags$a(class = "btn btn-success", href = app$path, "Open Module")))
    }))
  )
}

portal_server <- function(input, output, session) {}

crd_rbd_ui <- function(nav_catalog = app_catalog) {
  station_page(
    "CRD / RBD",
    "Single-factor CRD and RBD analysis with ANOVA, LSD, key statistics, and report export.",
    "crd-rbd",
    tagList(
      selectInput("design", "Experimental design", choices = c("CRD", "RBD")),
      numericInput("alpha", "Significance level", value = 0.05, min = 0.01, max = 0.2, step = 0.01),
      fileInput("upload", "Upload CSV / TSV / XLSX", accept = c(".csv", ".tsv", ".txt", ".xls", ".xlsx")),
      textAreaInput("data_input", "Or paste a table", value = default_data[["CRD"]], rows = 11),
      build_help_box("Expected format", c("First column should be the treatment label.", "Remaining columns should be replication columns.", "Use CRD for unblocked layouts and RBD when replications act as blocks.")),
      actionButton("analyze", "Run analysis", class = "btn-primary"),
      tags$hr(),
      selectInput("csv_table", "CSV table to download", choices = c("Long data", "ANOVA", "Key statistics", "Means", "LSD groups")),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(
      tabPanel("Long Data View", tableOutput("long_data_table")),
      tabPanel("ANOVA Table", tableOutput("anova_table")),
      tabPanel("Key Statistics", tableOutput("stats_table")),
      tabPanel("Means & CI", tableOutput("means_ci_table")),
      tabPanel("LSD & Letter Groups", tableOutput("lsd_stats"), tags$br(), tableOutput("lsd_groups"))
    ),
    nav_catalog = nav_catalog
  )
}

crd_rbd_server <- function(input, output, session) {
  observeEvent(input$design, updateTextAreaInput(session, "data_input", value = default_data[[input$design]]), ignoreNULL = FALSE)
  err <- reactiveVal(NULL)
  analysis <- eventReactive(input$analyze, {
    err(NULL)
    tryCatch(run_design_analysis(read_dataset_input(input$upload, input$data_input), input$design, 2, 2, input$alpha), error = function(e) {
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

  output$download_csv <- downloadHandler(
    filename = function() sprintf("crd-rbd-%s.csv", gsub("[^a-z]+", "-", tolower(input$csv_table))),
    content = function(file) {
      req(analysis())
      table_map <- list("Long data" = analysis()$dataset, "ANOVA" = analysis()$anova, "Key statistics" = analysis()$stats, "Means" = analysis()$means, "LSD groups" = analysis()$groups)
      write.csv(table_map[[input$csv_table]], file, row.names = FALSE)
    }
  )

  output$download_report <- downloadHandler(
    filename = function() "crd-rbd-report.html",
    content = function(file) {
      req(analysis())
      save_html_report("CRD / RBD Report", list(
        list(title = "Dataset summary", subtitle = analysis()$report_note, table = head(analysis()$dataset, 20)),
        list(title = "ANOVA table", table = analysis()$anova),
        list(title = "Key statistics", table = analysis()$stats),
        list(title = "Treatment means", table = analysis()$means),
        list(title = "Letter grouping", table = analysis()$groups)
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
      build_help_box("Expected data", c("Use numeric columns for correlation and regression.", "Choose one numeric response variable.", "Choose one or more numeric predictors.")),
      actionButton("analyze", "Run correlation and regression", class = "btn-primary"),
      tags$hr(),
      selectInput("csv_table", "CSV table to download", choices = c("Correlation matrix", "Coefficients", "Fit statistics", "Diagnostics")),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_report", "Download HTML report"),
      uiOutput("error_msg")
    ),
    analysis_tabs(tabPanel("Correlation Matrix", tableOutput("correlation_table")), tabPanel("Regression Coefficients", tableOutput("coefficients_table")), tabPanel("Fit Statistics", tableOutput("fit_table")), tabPanel("Diagnostics", tableOutput("diagnostics_table")), tabPanel("Long Data View", tableOutput("long_data_table")))
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
    checkboxGroupInput("predictors", "Predictor variables", choices = numeric_cols, selected = numeric_cols[2:min(length(numeric_cols), 3)])
  })

  analysis <- eventReactive(input$analyze, {
    err(NULL)
    tryCatch(run_correlation_regression(read_dataset_input(input$upload, input$data_input), input$response, input$predictors), error = function(e) {
      err(conditionMessage(e))
      NULL
    })
  })

  output$error_msg <- renderUI({ if (!is.null(err())) div(class = "alert alert-danger", tags$b("Error: "), err()) })
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

  output$download_report <- downloadHandler(
    filename = function() "correlation-regression-report.html",
    content = function(file) {
      req(analysis())
      save_html_report("Correlation and Regression Report", list(
        list(title = "Dataset summary", subtitle = analysis()$report_note, table = head(analysis()$dataset, 20)),
        list(title = "Correlation matrix", table = analysis()$correlation),
        list(title = "Regression coefficients", table = analysis()$coefficients),
        list(title = "Fit statistics", table = analysis()$fit),
        list(title = "Diagnostics", table = analysis()$diagnostics)
      ), file)
    }
  )
}
