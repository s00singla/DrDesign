# Presentation is deliberately separate from the full-precision model results.
reporting_note <- function() paste("Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.")

legacy_report_tables <- function(params) {
  # Explicit analysis titles take precedence over legacy generic parameter slots.
  candidates<-c(params$extra_tables,list(
    "Treatment Summary"=params$summary_stats,"ANOVA"=params$anova_table,
    "Key Statistics"=params$key_statistics,"Treatment Means"=params$mean_table,
    "Post-hoc Comparison Statistics"=params$posthoc_summary,
    "Post-hoc Comparison Results"=params$posthoc_table))
  result<-list()
  for(i in seq_along(candidates)) {
    x<-candidates[[i]]
    if(!is.data.frame(x) || !nrow(x)) next
    if(any(vapply(result,function(previous) identical(previous,x),logical(1)))) next
    result[[names(candidates)[i]]]<-x
  }
  result
}

report_labels <- function(nms) {
  labels <- c(Term="Source / term",Effect="Source / term",Source="Source / term",Df="df",DF="df",NumDF="Numerator df",DenDF="Denominator df",Den_df="Denominator df",
    `Sum Sq`="SS",Sum.Sq="SS",`Mean Sq`="MS",Mean.Sq="MS",`F value`="F",F.value="F",F_value="F",
    `Pr(>F)`="p-value",Pr..F.="p-value",Pr_F="p-value",P_value="p-value",p.value="p-value",pvalue="p-value",Pvalue="p-value",P="p-value",
    `Pr(>|t|)`="p-value",`Std. Error`="SE",Std.Error="SE",std.err="SE",se="SE",`Std Error Diff.`="SE(d)",`t value`="t",t.ratio="t",z.ratio="z",Z="z",HolmP="p-value (Holm)",DifferenceP="p-value (difference)",
    GEN="Genotype",REP="Replication",ENV="Environment",Trt="Treatment",FactA="Factor A",FactB="Factor B",MainPlot="Main-plot factor",SubPlot="Subplot factor",
    emmean="Estimated mean",estimate="Estimate",contrast="Contrast",lower.CL="CI lower",upper.CL="CI upper",asymp.LCL="CI lower",asymp.UCL="CI upper",LowerCI="CI lower",UpperCI="CI upper",Lower="CI lower",Upper="CI upper",LCL="CI lower",UCL="CI upper",
    `.group`="Group",groups="Group",BLUPg="Genotypic effect (BLUP)",LL="Interval lower",UL="Interval upper",mean.adj="Adjusted mean",SEd="SE(d)",EffectLower="Effect interval lower",EffectUpper="Effect interval upper",ConditionalSE="Conditional SE",
    std="SD",r="N",y="Observed mean",Critical_t="Critical t",predicted.values="Predicted",standard.errors="SE",vcov="Variance",sdcor="SD / Corr",grp="Group / Stratum",var1="Term 1",var2="Term 2",
    CV_pct="CV (%)",Rank_Mean="Mean rank",Rank_Yield="Yield rank",Rank_Stability="Stability rank",Rank_P_SSI="P-SSI rank",Rank_NP_SSI="NP-SSI rank",Rank_C_SSI="C-SSI rank",Rank_WAASBY="WAASBY rank",
    Rank_HMGV="HMGV rank",Rank_RPGV="RPGV rank",Rank_HMRPGV="HMRPGV rank",P_SSI="P-SSI",NP_SSI="NP-SSI",Explained_percent="Explained (%)",Accumulated_percent="Cumulative (%)",`sig.`="Sig")
  out <- nms
  hit <- nms %in% names(labels);out[hit]<-labels[nms[hit]]
  out[!hit] <- trimws(gsub("[._]+"," ",gsub("([a-z])([A-Z])","\\1 \\2",out[!hit])))
  out
}

report_number <- function(x, p = FALSE, count = FALSE) {
  out <- rep("NA",length(x));ok<-is.finite(x)
  if(p) out[ok]<-ifelse(x[ok]<0.001,"<0.001",sprintf("%.3f",x[ok])) else {
    out[ok]<-if(count && all(x[ok]==trunc(x[ok]))) sprintf("%.0f",x[ok]) else sprintf("%.3f",x[ok])
    tiny<-ok & x!=0 & (abs(x)<0.0005 | abs(x)>=1e7)
    out[tiny]<-formatC(x[tiny],format="e",digits=2)
    out[out=="-0.000"]<-"0.000"
  }
  out[is.infinite(x)]<-ifelse(x[is.infinite(x)]>0,"Inf","-Inf")
  out
}

publication_table <- function(x) {
  if(is.null(x)) return(NULL)
  p_matrix<-isTRUE(attr(x,"p_value_matrix"))
  x<-as.data.frame(x,check.names=FALSE)
  if(all(c("GEN","Genotype") %in% names(x)) && identical(as.character(x$GEN),as.character(x$Genotype))) {
    x$Genotype<-NULL
  }
  if(!identical(rownames(x),as.character(seq_len(nrow(x)))) && nrow(x)>0 && !all(grepl("^[0-9]+$",rownames(x))) && all(nzchar(trimws(rownames(x))))) {
    ids<-rownames(x)
    # Do not duplicate an identifier already present as an explicit column.
    if(!any(vapply(x,function(col) identical(as.character(col),ids),logical(1)))) x<-cbind(Term=ids,x)
  }
  rownames(x)<-NULL
  for(nm in names(x)) if(is.numeric(x[[nm]])) {
    is_p <- p_matrix || grepl("^(P|p|[Pp][._ -]?[Vv]alue|HolmP|DifferenceP|Pr_F)$|^Pr[.(]",nm)
    count<-grepl("^(N|n|r|df|DF|Df|NumDF|DenDF|Den_df|Rank|Rank_.*|Count|Observation|Row|Column|Replications|ReplicationsPerGroup|Groups|TotalUnits|Cluster|Seed|Comparisons|Traits_in_top10)$",nm)
    x[[nm]]<-report_number(x[[nm]],p=is_p,count=count)
  }
  # Older metadata tables store values in a mixed text column.
  label_col<-intersect(c("Metric","Statistic","Setting","Parameter","Check"),names(x))[1]
  if(!is.na(label_col) && "Value" %in% names(x)) {
    v<-suppressWarnings(as.numeric(x$Value));ok<-is.finite(v)
    is_p<-grepl("p[- ]?value|Pr\\(",x[[label_col]],ignore.case=TRUE)
    is_cnt<-grepl("^(Years|Replications|Main-plot levels|Subplot levels|Observations|Groups|Clusters|Seed|Treatments)$",x[[label_col]],ignore.case=TRUE)
    if(any(ok & is_p)) x$Value[ok & is_p]<-report_number(v[ok & is_p],p=TRUE)
    if(any(ok & !is_p & is_cnt)) x$Value[ok & !is_p & is_cnt]<-report_number(v[ok & !is_p & is_cnt],count=TRUE)
    if(any(ok & !is_p & !is_cnt)) x$Value[ok & !is_p & !is_cnt]<-report_number(v[ok & !is_p & !is_cnt])
  }
  for(nm in setdiff(names(x),"Version")) if(is.character(x[[nm]]) || is.factor(x[[nm]])) {
    vals<-as.character(x[[nm]])
    has_long_dec<-!is.na(vals) & grepl("[0-9]+\\.[0-9]{4,}",vals)
    if(any(has_long_dec)) {
      vals[has_long_dec]<-vapply(vals[has_long_dec],function(s) {
        m<-gregexpr("-?[0-9]+\\.[0-9]{4,}([eE][+-]?[0-9]+)?",s,perl=TRUE)
        regmatches(s,m)<-lapply(regmatches(s,m),function(nums) {
          vapply(nums,function(n_str) {
            num<-suppressWarnings(as.numeric(n_str))
            if(is.finite(num)) report_number(num) else n_str
          },character(1))
        })
        s
      },character(1),USE.NAMES=FALSE)
      x[[nm]]<-vals
    }
  }
  for(nm in names(x)) if(anyNA(x[[nm]])) {
    x[[nm]]<-as.character(x[[nm]])
    x[[nm]][is.na(x[[nm]])]<-"NA"
  }
  names(x)<-report_labels(names(x))
  if(all(c("Source / term","SS","MS") %in% names(x))) {
    anova_order<-c("Source / term","df","Numerator df","Denominator df","SS","MS","F","p-value","Sig")
    x<-x[,c(intersect(anova_order,names(x)),setdiff(names(x),anova_order)),drop=FALSE]
  }
  x
}

table_alignment <- function(raw_df, pub_df = publication_table(raw_df)) {
  if(!is.data.frame(pub_df) || !ncol(pub_df)) return("")
  num_labels<-if(is.data.frame(raw_df)) report_labels(names(raw_df)[vapply(raw_df,is.numeric,logical(1))]) else character()
  align<-ifelse(names(pub_df) %in% num_labels,"r","l")
  if("Value" %in% names(pub_df) && any(c("Metric","Statistic") %in% names(pub_df))) {
    vals<-as.character(pub_df$Value)
    if(length(vals)>0 && all(vals %in% c("NA","<0.001","Inf","-Inf") | grepl("^-?[0-9]+(\\.[0-9]+)?([eE][+-]?[0-9]+)?$",vals))) {
      align[names(pub_df)=="Value"]<-"r"
    }
  }
  paste(align,collapse="")
}

escape_report_markdown <- function(x) vapply(x,function(value) {
  chars<-strsplit(gsub("[\r\n]+"," ",value),"",fixed=TRUE)[[1]]
  special<-chars %in% c("\\","*","_","{","}","[","]","<",">","$","|",intToUtf8(96))
  chars[special]<-paste0("\\",chars[special])
  paste(chars,collapse="")
},character(1),USE.NAMES=FALSE)

report_table_notes <- function(x) unique(trimws(gsub("[\r\n[:space:]]+"," ",attr(x,"mesg") %||% character())))

report_kable <- function(x, caption = NULL) {
  notes<-report_table_notes(x)
  numeric_columns<-if(is.data.frame(x)) report_labels(names(x)[vapply(x,is.numeric,logical(1))]) else character()
  x<-publication_table(x)
  if(is.null(x) || !nrow(x)) {cat("No rows to report.\n");return(invisible(NULL))}
  # A row key keeps all compound identifiers unambiguous across wide segments.
  if(ncol(x)>6) {
    x<-cbind(`Table row`=seq_len(nrow(x)),x)
    groups<-lapply(split(2:ncol(x),ceiling(seq_along(2:ncol(x))/5)),function(cols)c(1,cols))
  } else groups<-list(seq_len(ncol(x)))
  for(cols in groups) {
    part<-x[,cols,drop=FALSE]
    tex<-knitr::is_latex_output()
    if(!tex) part[]<-lapply(part,function(values)escape_report_markdown(as.character(values)))
    safe_caption<-if(!is.null(caption)) {if(tex) knitr:::escape_latex(caption) else escape_report_markdown(caption)} else NULL
    rendered<-knitr::kable(part,format=if(tex) "latex" else "pandoc",caption=safe_caption,label=NA,row.names=FALSE,booktabs=tex,longtable=tex)
    lines<-strsplit(paste(as.character(rendered),collapse="\n"),"\n",fixed=TRUE)[[1]]
    if(tex) {
      alignment<-ifelse(names(part) %in% numeric_columns,"\\raggedleft","\\raggedright")
      columns<-paste0(">{",alignment,"\\arraybackslash}p{",sprintf("%.3f",0.86/ncol(part)),"\\linewidth}")
      lines[grepl("^\\\\begin\\{longtable\\}",lines)]<-paste0("\\begin{longtable}{",paste(columns,collapse=""),"}")
      mid<-which(lines=="\\midrule")[1];top<-which(lines=="\\toprule")[1]
      # Repeat headers after page breaks. This also separates booktabs rules
      # from first-cell parentheses such as "(Intercept)".
      lines<-append(lines,c("\\endfirsthead",lines[top:mid],"\\endhead"),after=mid)
    }
    cat(paste(lines,collapse="\n"),"\n\n")
  }
  if(length(notes)) cat("\n\n",paste(escape_report_markdown(notes),collapse="\n\n"),"\n\n")
  invisible(NULL)
}

render_publication_table <- function(expr, ..., env = parent.frame(), quoted = FALSE, caption = NULL) {
  force(env)
  expression<-if(quoted) expr else substitute(expr)
  table_args<-list(...)
  shiny::createRenderFunction(
    func=function() {
      value<-eval(expression,env)
      pub<-publication_table(value)
      list(table=pub,
           align=table_alignment(value,pub),
           caption=caption %||% paste(report_table_notes(value),collapse=" "))
    },
    transform=function(value,session,name,...) {
      args<-table_args
      if(is.null(args$align) && !isTRUE(args$rownames) && !is.null(value$align)) args$align<-value$align
      renderer<-do.call(shiny::renderTable,c(list(expr=quote(value$table),quoted=TRUE,
        env=environment(),caption=value$caption),args),quote=TRUE)
      renderer()
    },
    outputFunc=shiny::tableOutput)
}
