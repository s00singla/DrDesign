FROM rocker/shiny:4.3.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    certbot \
    python3-certbot-nginx \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shiny','shinyWidgets','rmarkdown','knitr','htmltools','DT','readxl','dplyr','tidyr','agricolae','desplot','ggplot2','corrplot','RColorBrewer','emmeans','multcomp','multcompView','car','lme4','lmerTest','metan','writexl'), repos='https://cloud.r-project.org')"

COPY R /srv/shiny-server/R
COPY inst /srv/shiny-server/inst
COPY app.R /srv/shiny-server/app.R
COPY analysis-report-template.Rmd /srv/shiny-server/analysis-report-template.Rmd
COPY DESCRIPTION /srv/shiny-server/DESCRIPTION
COPY deploy/shiny-server.conf /etc/shiny-server/shiny-server.conf

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
