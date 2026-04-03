source("../../R/shared.R", local = TRUE)
source("../../R/analysis.R", local = TRUE)
source("../../R/app_builders.R", local = TRUE)

shinyApp(ui = correlation_regression_ui(), server = correlation_regression_server)
