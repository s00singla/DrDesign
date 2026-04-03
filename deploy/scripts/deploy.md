# Research Station Cloud Deployment

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
