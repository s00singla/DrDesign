source("R/shared.R", local = TRUE)
source("R/analysis.R", local = TRUE)
source("R/app_builders.R", local = TRUE)

root_router_ui <- function(request) {
  target <- parseQueryString(request$QUERY_STRING)[["app"]]

  switch(
    target %||% "portal",
    "crd-rbd" = crd_rbd_ui(local_app_catalog),
    "factorial-design" = factorial_design_ui(local_app_catalog),
    "pooled-anova" = pooled_anova_ui(local_app_catalog),
    "split-plot" = split_plot_ui(local_app_catalog),
    "correlation-regression" = correlation_regression_ui(local_app_catalog),
    portal_ui(local_app_catalog)
  )
}

root_router_server <- function(input, output, session) {
  session$onFlushed(function() {
    target <- parseQueryString(isolate(session$clientData$url_search))
    app_name <- target[["app"]] %||% "portal"

    switch(
      app_name,
      "crd-rbd" = crd_rbd_server(input, output, session),
      "factorial-design" = factorial_design_server(input, output, session),
      "pooled-anova" = pooled_anova_server(input, output, session),
      "split-plot" = split_plot_server(input, output, session),
      "correlation-regression" = correlation_regression_server(input, output, session),
      portal_server(input, output, session)
    )
  }, once = TRUE)
}

shinyApp(ui = root_router_ui, server = root_router_server)
