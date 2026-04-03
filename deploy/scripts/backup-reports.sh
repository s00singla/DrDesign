#!/bin/sh
set -eu

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/research-station}"
SOURCE_DIR="${SOURCE_DIR:-/var/lib/docker/volumes/research-station_shiny_reports/_data}"

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/research-station-reports-$STAMP.tar.gz" -C "$SOURCE_DIR" .
