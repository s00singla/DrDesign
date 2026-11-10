# Shiny automatically sources R/ alphabetically before app.R. Load shared
# definitions first; app.R also sources them for explicit/direct launches.
if (!exists("capture_analysis_health", mode = "function")) {
  shared_candidates <- file.path(c(".", "..", "../.."), "R", "shared.R")
  source(shared_candidates[file.exists(shared_candidates)][1], local = TRUE)
}
