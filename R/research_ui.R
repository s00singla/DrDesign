research_example <- function(key) {
  d <- expand.grid(Genotype = sprintf("G%02d", 1:12), Rep = paste0("R", 1:3), stringsAsFactors = FALSE)
  i <- seq_len(nrow(d)); g <- match(d$Genotype, unique(d$Genotype))
  d$Yield <- round(20 + g*0.8 + sin(i*2.3)*2 + match(d$Rep, unique(d$Rep))*0.4, 3)
  d$Height <- round(50 + g*1.2 + cos(i*1.7)*5, 3)
  d$Maturity <- round(100 - g*0.2 + sin(i)*3, 3)
  if (key %in% c("multi-trait-selection", "pca-diversity")) {
    agg <- aggregate(d[c("Yield", "Height", "Maturity")], list(Genotype = d$Genotype), mean)
    agg[c("Yield", "Height", "Maturity")] <- lapply(agg[c("Yield", "Height", "Maturity")], round, 3)
    return(agg)
  }
  if (key == "augmented-trial") {
    z <- expand.grid(Block = paste0("B",1:3), Genotype = c("C1","C2"), stringsAsFactors=FALSE)
    z <- rbind(z, data.frame(Block=rep(paste0("B",1:3),each=3),Genotype=paste0("T",1:9)))
    z$Value <- round(20 + seq_len(nrow(z))*0.3 + sin(seq_len(nrow(z))*2), 3); return(z)
  }
  if (key == "strip-plot") {
    z <- expand.grid(Rep=paste0("R",1:3),FactorA=paste0("A",1:3),FactorB=paste0("B",1:3))
    z$Value <- round(20 + as.numeric(z$FactorA)*2+as.numeric(z$FactorB)+sin(seq_len(nrow(z))*2.7), 3); return(z)
  }
  if (key == "incomplete-block") {
    d$Block <- unlist(lapply(1:3, function(r) paste0("B", ((seq_len(12)-1 + (r-1)*2) %% 12) %/% 3+1)))
  }
  if (key == "spatial-field") {
    order <- c(7,22,3,30,15,34,19,4,27,10,35,16,1,25,12,32,6,21,28,14,36,8,23,2,17,31,5,26,11,33,24,9,20,13,29,18)
    d <- d[order, ]; d$Row <- rep(1:6, each=6); d$Column <- rep(1:6,6); d$Value <- round(d$Yield+d$Row*0.2, 3); return(d[c("Genotype","Rep","Row","Column","Value")])
  }
  if (key == "combining-ability") {
    z <- expand.grid(Rep=paste0("R",1:3),Parent1=paste0("L",1:3),Parent2=paste0("T",1:3))
    z$Value <- round(20+as.numeric(z$Parent1)*2+as.numeric(z$Parent2)+sin(seq_len(nrow(z))*2), 3); return(z)
  }
  if (key == "heterosis") { d$Value <- d$Yield; return(d[c("Genotype","Rep","Value")]) }
  if (key == "generation-means") return(data.frame(Generation=c("P1","P2","F1","F2","BC1","BC2"),Mean=c(24,16,25,22.5,24,19.5),SE=c(0.6,0.6,0.7,0.8,0.7,0.7)))
  d
}

research_example_text <- function(key) paste(capture.output(write.table(research_example(key), sep="\t", row.names=FALSE, quote=FALSE)), collapse="\n")

research_ui <- function(key, nav_catalog = module_catalog()) {
  spec <- module_registry[[key]]
  no_data <- key %in% c("power-planning", "alpha-layout")
  station_page(spec$label, spec$description, key,
    tagList(
      if (!no_data) tagList(fileInput("research_upload", "Upload CSV or Excel", accept=c(".csv",".xlsx",".xls",".tsv",".txt")),
        textAreaInput("research_paste", "Paste a table", value=research_example_text(key), rows=9),
        downloadButton("research_example", "Download example CSV"), uiOutput("research_mapping"),
        uiOutput("research_options"),
        tags$h4("Review observations"), tableOutput("research_issues"),
        checkboxInput("research_exclude", "Exclude the listed invalid observations", FALSE)),
      if (key == "power-planning") tagList(selectInput("power_method","Comparison",c("Balanced CRD ANOVA"="anova","Two independent groups"="two-sample")),textInput("power_means","Anticipated group means (comma separated)","20,22,24"),numericInput("power_sd","Residual standard deviation",3,min=0.001),numericInput("power_target","Target power",0.8,min=0.01,max=0.99)),
      if (key == "alpha-layout") tagList(numericInput("layout_treatments","Genotypes",12,min=4),numericInput("layout_block_size","Entries per incomplete block",3,min=2),numericInput("layout_reps","Replications",3,min=2),numericInput("layout_seed","Random seed",7,min=1)),
      numericInput("research_alpha", "Significance level", 0.05, min=0.001,max=0.2,step=0.01),
      actionButton("research_run","Run analysis",class="btn-primary"), tags$hr(),
      uiOutput("research_export_table"), downloadButton("research_csv","Download selected table"),
      downloadButton("research_html","HTML report"), downloadButton("research_word","Word report"), downloadButton("research_pdf","PDF report")
    ),
    tagList(uiOutput("research_status"), uiOutput("research_results")), nav_catalog=nav_catalog)
}

research_report_params <- function(result) {
  list(report_title=result$title, design_name=result$title, alpha=result$settings$Alpha,
    comparison_method=paste(unlist(result$settings),collapse="; "),
    summary_stats=result$tables[[1]], dataset_preview=head(result$dataset,20),
    report_note=paste(result$status, "| Observations:",nrow(result$dataset),"| Excluded:",nrow(result$exclusions)),
    extra_tables=result$tables, extra_plots=result$plots,
    extra_text_sections=list("Diagnostics"=result$warnings,"Method references"=result$references),generated_at=result$generated_at)
}

research_server <- function(key, input, output, session) {
  spec <- module_registry[[key]]; saved <- reactiveVal(NULL); error <- reactiveVal(NULL)
  no_data <- key %in% c("power-planning", "alpha-layout")
  raw <- reactive({ if (no_data) return(NULL); read_dataset_input(input$research_upload,input$research_paste) })
  output$research_mapping <- renderUI({
    d <- raw(); nms <- names(d)
    numeric <- nms[vapply(d,is.numeric,logical(1))]
    tagList(lapply(spec$roles,function(role) selectInput(paste0("map_",role),paste(role,"column"),choices=nms,selected=if(role %in% nms) role else nms[1])),
      if (isTRUE(spec$traits)) selectInput("research_traits","Trait / replication columns",choices=nms,selected=setdiff(numeric,spec$roles),multiple=TRUE),
      if (key == "data-preparation") tagList(selectInput("research_ids","Experimental-unit identifiers",choices=nms,selected=intersect(c("Genotype","Rep"),nms),multiple=TRUE),checkboxInput("research_wide","Convert replication columns to long format",FALSE)))
  })
  mapped <- reactive({
    d <- raw(); if (is.null(d)) return(d)
    columns <- vapply(spec$roles,function(role) input[[paste0("map_",role)]] %||% role,character(1))
    research_assert(!anyDuplicated(columns),"Assign a different column to each role.")
    research_assert(all(columns %in% names(d)),"Map all required columns.")
    out <- d[,setdiff(names(d),columns),drop=FALSE]
    for (role in spec$roles) out[[role]] <- d[[columns[[role]]]]
    out
  })
  selected_traits <- reactive({ input$research_traits %||% character() })
  output$research_options <- renderUI({
    d <- mapped(); gen <- if ("Genotype" %in% names(d)) unique(as.character(d$Genotype)) else character()
    tagList(
      if(key=="augmented-trial") selectInput("research_checks","Replicated checks",choices=gen,selected=intersect(c("C1","C2"),gen),multiple=TRUE),
      if(key %in% c("genetic-variability","multi-trait-selection","incomplete-block")) numericInput("selection_percent","Selection percentage",15,min=1,max=99),
      if(key=="multi-trait-selection") tagList(selectInput("selection_method","Selection method",c("Weighted standardized score"="weighted","MGIDI"="mgidi")),selectInput("lower_traits","Traits where lower is better",choices=selected_traits(),multiple=TRUE),textInput("trait_weights","Weights in trait order (blank = equal)",""),checkboxInput("directions_confirmed","I have reviewed the desired direction of every trait",FALSE)),
      if(key=="pca-diversity") numericInput("cluster_count","Number of clusters",2,min=2),
      if(key %in% c("incomplete-block","spatial-field")) checkboxInput("genotype_random","Treat genotypes as random (BLUPs)",key=="incomplete-block"),
      if(key=="combining-ability") selectInput("crossing_method","Crossing design",c("Line x tester"="line-tester","Griffing II: parents and F1, fixed"="diallel")),
      if(key=="heterosis") tagList(selectInput("heterosis_parent1","Parent 1",gen,selected=gen[1]),selectInput("heterosis_parent2","Parent 2",gen,selected=gen[2]),selectInput("heterosis_hybrids","Hybrids",gen,selected=gen[3],multiple=TRUE),selectInput("heterosis_check","Commercial check",c("None"="",gen)),checkboxInput("heterosis_lower","Lower response is better",FALSE)))
  })
  roles <- reactive({
    nums <- unique(c(intersect(spec$roles,c("Value","Row","Column","Mean","SE")),selected_traits()))
    ids <- if(key=="data-preparation") input$research_ids %||% character() else setdiff(spec$roles,nums)
    list(numeric=nums, ids=ids)
  })
  output$research_issues <- render_publication_table({ if(no_data) return(NULL); r <- roles(); issues <- observation_issues(mapped(),r$numeric,r$ids); if(!nrow(issues)) data.frame(Review="No missing or non-finite values in selected columns.") else issues })
  # A prior exclusion decision cannot authorize exclusions after data/mapping changes.
  observeEvent(list(if(!no_data) raw(), lapply(spec$roles,function(role) input[[paste0("map_",role)]]),selected_traits()), {
    updateCheckboxInput(session,"research_exclude",value=FALSE)
  },ignoreInit=TRUE)
  snapshot <- stable_input_signature(input,c("research_run","research_csv","research_html","research_word","research_pdf","research_example"),"^research_table(_|$)|^DataTables_")
  observeEvent(input$research_run, {
    error(NULL)
    tryCatch({
      a <- input$research_alpha %||% 0.05; exclude <- isTRUE(input$research_exclude)
      d <- if(no_data) NULL else mapped(); traits <- selected_traits()
      if(isTRUE(spec$traits)) research_assert(length(traits)>0,"Select at least one trait.")
      captured <- research_capture(switch(key,
        `data-preparation`=run_data_preparation(d,traits,input$research_ids %||% character(),exclude,isTRUE(input$research_wide)),
        `augmented-trial`=run_augmented_trial(d,input$research_checks,a,exclude),
        `strip-plot`=run_strip_trial(d,a,exclude),
        `genetic-variability`=run_genetic_variability(d,traits,a,input$selection_percent %||% 15,exclude),
        `incomplete-block`=run_genetic_variability(d,traits,a,input$selection_percent %||% 15,exclude,TRUE,isTRUE(input$genotype_random)),
        `multi-trait-selection`={
          research_assert(isTRUE(input$directions_confirmed),"Review and confirm the desired trait directions.")
          weights <- if(nzchar(trimws(input$trait_weights %||% ""))) suppressWarnings(as.numeric(strsplit(input$trait_weights,",",fixed=TRUE)[[1]])) else rep(1,length(traits))
          run_multi_trait_selection(d,traits,input$lower_traits %||% character(),weights,input$selection_percent %||% 15,input$selection_method %||% "weighted",exclude)
        },
        `pca-diversity`=run_diversity(d,traits,input$cluster_count %||% 2,exclude),
        `power-planning`=run_power_planning(suppressWarnings(as.numeric(strsplit(input$power_means,",",fixed=TRUE)[[1]])),input$power_sd,input$power_target,a,input$power_method),
        `alpha-layout`={
          book <- run_alpha_layout(input$layout_treatments,input$layout_block_size,input$layout_reps,input$layout_seed)
          research_result("Alpha-Lattice Fieldbook",list(data=book,exclusions=data.frame()),list("Fieldbook"=book),settings=list(Seed=input$layout_seed,Coordinates="Recording coordinates; verify field orientation"),references="agricolae::design.alpha")
        },
        `spatial-field`=run_spatial_trial(d,isTRUE(input$genotype_random),a,exclude),
        `combining-ability`=run_combining_ability(d,input$crossing_method %||% "line-tester",a,exclude),
        heterosis=run_heterosis(d,input$heterosis_parent1,input$heterosis_parent2,input$heterosis_hybrids,if(nzchar(input$heterosis_check %||% "")) input$heterosis_check else NULL,isTRUE(input$heterosis_lower),a,exclude),
        `generation-means`=run_generation_means(d,a)))
      result <- captured$value
      result$warnings <- unique(c(result$warnings,captured$warnings))
      if(length(result$warnings)) result$status <- "Review diagnostics"
      saved(list(result=result,signature=snapshot()))
    },error=function(e) { saved(NULL); error(conditionMessage(e)) })
  })
  current <- reactive({ value<-saved(); req(value); validate(need(identical(value$signature,snapshot()),"Inputs changed. Run analysis again before using or exporting results.")); value$result })
  output$research_status <- renderUI({
    if(!is.null(error())) return(div(class="alert alert-danger",error()))
    value<-saved(); if(is.null(value)) return(div(class="station-help","Review the data and settings, then run the analysis."))
    if(!identical(value$signature,snapshot())) {
      if(isTRUE(getOption("drdesign.debug",FALSE))) {
        before <- unserialize(value$signature); after <- unserialize(snapshot())
        changed <- union(names(before),names(after)); changed <- changed[!vapply(changed,function(nm) identical(before[[nm]],after[[nm]]),logical(1))]
        message("Changed analysis input names: ",paste(changed,collapse=", "))
      }
      return(div(class="alert alert-warning","Inputs changed. Results are stale; run analysis again."))
    }
    div(class="station-help",strong(value$result$status),tags$ul(lapply(value$result$warnings,tags$li)))
  })
  output$research_results <- renderUI({
    result <- current()
    audit_names <- c("Exclusions", "Reviewed data", "Software versions", "Analysis settings")
    table_names <- names(result$tables)
    primary_idx <- which(!table_names %in% audit_names)
    audit_idx <- which(table_names %in% audit_names)

    primary_sections <- lapply(primary_idx, function(i) {
      output_section(table_names[i], DT::DTOutput(paste0("research_table_", i)))
    })
    plot_sections <- lapply(seq_along(result$plots), function(i) {
      output_section(names(result$plots)[i], plotOutput(paste0("research_plot_", i), height = "420px"))
    })
    audit_sections <- c(
      lapply(audit_idx, function(i) {
        output_section(table_names[i], DT::DTOutput(paste0("research_table_", i)))
      }),
      if (length(result$references)) list(
        output_section("Method References", tags$p(class = "station-help", paste(result$references, collapse = "; ")))
      )
    )

    tabs <- list(tabPanel("Analysis Results", do.call(tagList, primary_sections)))
    if (length(plot_sections) > 0) {
      tabs[[length(tabs) + 1]] <- tabPanel("Plots & Visualizations", do.call(tagList, plot_sections))
    }
    tabs[[length(tabs) + 1]] <- tabPanel("Data & Audit", do.call(tagList, audit_sections))
    do.call(analysis_tabs, tabs)
  })
  observeEvent(saved(), {
    req(saved()); result<-saved()$result
    for(i in seq_along(result$tables)) local({
      n<-i
      output[[paste0("research_table_",n)]]<-DT::renderDT({
        tab<-current()$tables[[n]]
        tab_name<-names(current()$tables)[n]
        notes<-report_table_notes(tab)
        pub_tab<-publication_table(tab)
        is_compact<-nrow(pub_tab)<=12 && !identical(tab_name,"Reviewed data")
        dt_opts<-if(is_compact) list(dom="t",paging=FALSE,scrollX=TRUE,ordering=FALSE) else list(pageLength=10,scrollX=TRUE)
        dt<-DT::datatable(pub_tab,options=dt_opts,rownames=FALSE,
          caption=if(length(notes)) htmltools::tags$caption(paste(notes,collapse=" ")) else NULL)
        align_vec<-strsplit(table_alignment(tab,pub_tab),"")[[1]]
        right_cols<-which(align_vec=="r")
        if(length(right_cols)>0 && max(right_cols)<=ncol(pub_tab)) {
          dt<-DT::formatStyle(dt,columns=right_cols,textAlign="right")
        }
        dt
      })
    })
    for(i in seq_along(result$plots)) local({ n<-i; output[[paste0("research_plot_",n)]]<-renderPlot({p<-current()$plots[[n]]; if(is.function(p)) p() else print(p)}) })
  })
  output$research_export_table <- renderUI({result<-current();selectInput("research_table","Table to download",names(result$tables))})
  output$research_csv <- downloadHandler(filename=function() paste0(key,".csv"),content=function(file) {result<-current();write.csv(result$tables[[input$research_table %||% names(result$tables)[1]]],file,row.names=FALSE)})
  output$research_example <- downloadHandler(filename=function() paste0(key,"-example.csv"),content=function(file) write.csv(research_example(key),file,row.names=FALSE))
  output$research_html <- downloadHandler(filename=function() paste0(key,".html"),content=function(file) {
    result<-current();sections<-lapply(names(result$tables),function(nm) list(title=nm,table=result$tables[[nm]]))
    sections<-c(list(list(title="Diagnostics",text=paste(result$warnings,collapse="\n")),list(title="Method references",text=paste(result$references,collapse="\n"))),sections,lapply(names(result$plots),function(nm) list(title=nm,plot=result$plots[[nm]])))
    save_html_report(result$title,sections,file)
  })
  register_report_downloads(output,"research_pdf","research_word",key,reactive(research_report_params(current())),template_name="research-report-template.Rmd")
}
