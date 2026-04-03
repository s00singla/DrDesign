source("../../R/shared.R", local = TRUE)
source("../../R/analysis.R", local = TRUE)
source("../../R/app_builders.R", local = TRUE)

shinyApp(ui = portal_ui(), server = portal_server)
