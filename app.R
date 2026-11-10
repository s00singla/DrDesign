source("R/shared.R", local = TRUE)
source("R/analysis.R", local = TRUE)
source("R/met_analysis.R", local = TRUE)
source("R/app_builders.R", local = TRUE)
source("R/research_analysis.R", local = TRUE)
source("R/research_ui.R", local = TRUE)

root_router_ui <- function(request) {
  key <- resolve_module(parseQueryString(request$QUERY_STRING)[["app"]])
  module_ui(key, local_app_catalog)
}

root_router_server <- function(input, output, session) {
  session$onFlushed(function() {
    key <- resolve_module(parseQueryString(isolate(session$clientData$url_search))[["app"]])
    module_server(key, input, output, session)
  }, once = TRUE)
}

shinyApp(ui = root_router_ui, server = root_router_server)