FROM rocker/shiny:4.3.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    certbot \
    python3-certbot-nginx \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shiny','dplyr','tidyr','agricolae','readxl','htmltools','lme4','lmerTest','emmeans','ggplot2','multcomp','multcompView','car'), repos='https://cloud.r-project.org')"

COPY R /srv/shiny-server/R
COPY app.R /srv/shiny-server/app.R
COPY apps/crd-rbd /srv/shiny-server/crd-rbd
COPY apps/factorial-design /srv/shiny-server/factorial-design
COPY apps/pooled-anova /srv/shiny-server/pooled-anova
COPY apps/split-plot /srv/shiny-server/split-plot
COPY apps/correlation-regression /srv/shiny-server/correlation-regression
COPY deploy/shiny-server.conf /etc/shiny-server/shiny-server.conf

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
