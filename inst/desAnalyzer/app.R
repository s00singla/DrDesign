source("../../R/shared.R", local = TRUE)
source("../../R/analysis.R", local = TRUE)
source("../../R/app_builders.R", local = TRUE)

shinyApp(ui = design_analyzer_ui(), server = design_analyzer_server)
