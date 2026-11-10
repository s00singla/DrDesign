FROM rocker/shiny:4.5.3@sha256:cdb591d29b1d2f5be917ea502c15b7b60516dde835dea16f3677654a5b52ebaf

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

RUN R -e "install.packages('renv', repos='https://cloud.r-project.org')"

COPY renv.lock /srv/shiny-server/renv.lock
RUN R -e "renv::restore(lockfile='/srv/shiny-server/renv.lock', library=.libPaths()[1], prompt=FALSE)"

COPY R /srv/shiny-server/R
COPY inst /srv/shiny-server/inst
COPY app.R /srv/shiny-server/app.R
COPY analysis-report-template.Rmd /srv/shiny-server/analysis-report-template.Rmd
COPY research-report-template.Rmd /srv/shiny-server/research-report-template.Rmd
COPY DESCRIPTION /srv/shiny-server/DESCRIPTION
COPY LICENSE /srv/shiny-server/LICENSE
COPY COPYRIGHT /srv/shiny-server/COPYRIGHT
COPY NOTICE /srv/shiny-server/NOTICE
COPY deploy/shiny-server.conf /etc/shiny-server/shiny-server.conf

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
