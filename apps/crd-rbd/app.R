source("../../R/shared.R", local = TRUE)
source("../../R/analysis.R", local = TRUE)
source("../../R/app_builders.R", local = TRUE)

shinyApp(ui = crd_rbd_ui(), server = crd_rbd_server)
