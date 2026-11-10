# Research Station Cloud Deployment

## shinyapps.io

Use R 4.5.3 from the repository root. Run the local packaging check first:

```r
source("tests/deployment-check.R")
```

This validates the lock file as standard JSON, checks the deployment file list,
resolves dependencies without changing pinned versions, and creates a local
deployment manifest under `output/deployment-check/stage/`. It does not upload
or change the hosted application.

To redeploy the existing app:

```r
rsconnect::deployApp(
  appDir = ".",
  appFiles = rsconnect::listDeploymentFiles("."),
  appName = "DrDesignSingla",
  account = "sauravsingla",
  server = "shinyapps.io"
)
```

The root `.rscignore` excludes saved workspaces, private filing material, local
reports, documentation sources, tests and development artifacts. The app source,
report templates, bundled data and `renv.lock` remain included. `.gitignore` and
`.Rbuildignore` do not replace deployment exclusions. See the
[rsconnect file selection documentation](https://rstudio.github.io/rsconnect/reference/listDeploymentFiles.html).

The 28 October 2026 repair converted invalid R-style octal character escapes in
package author metadata to JSON Unicode escapes. No package versions changed.
Run the preflight again after regenerating `renv.lock`; invalid JSON should be
caught before an upload. Do not remove the lock file merely to bypass parsing.

## Docker on a cloud VM

1. Install Docker Engine and Docker Compose on the cloud VM.
2. Point your DNS record to the VM public IP.
3. From the repo root, run `docker compose -f deploy/docker-compose.yml up -d --build`.
4. Replace `research-station.example.org` in `deploy/nginx/default.conf` with the station domain.
5. Obtain TLS certificates with Certbot on the VM so the configured `fullchain.pem` and `privkey.pem` paths exist.
6. Schedule `deploy/scripts/backup-reports.sh` daily with `cron` if reports or uploads are persisted.
7. Monitor container logs from the `nginx_logs` and `shiny_logs` volumes.

Suggested health checks:

- `curl -I https://your-domain.example/`
- `curl -I https://your-domain.example/crd-rbd/`
- `curl -I https://your-domain.example/factorial-design/`
- `curl -I https://your-domain.example/pooled-anova/`
- `curl -I https://your-domain.example/split-plot/`
- `curl -I https://your-domain.example/correlation-regression/`
