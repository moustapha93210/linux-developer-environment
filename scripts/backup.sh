#!/bin/bash

# Dossier où les sauvegardes seront stockées
BACKUP_DIR="/opt/backup/postgresql"

# Création d'un nom de fichier basé sur la date
DATE=$(date +"%Y-%m-%d_%H-%M")
FILENAME="backup-$DATE.sql"

# Commande pg_dump : on sauvegarde la base "data-db"
pg_dump data-db > "$BACKUP_DIR/$FILENAME"

# On supprime les fichiers de plus de 7 jours
find "$BACKUP_DIR" -type f -mtime +7 -delete
