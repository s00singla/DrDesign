source("../../R/shared.R", local = TRUE)
source("../../R/analysis.R", local = TRUE)
source("../../R/app_builders.R", local = TRUE)

shinyApp(ui = split_plot_ui(), server = split_plot_server)
