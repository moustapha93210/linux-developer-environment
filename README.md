# Linux Developer Environment

Projet final réalisé dans le cadre du cours **Linux orienté développeurs** à l’ESGI.

L’objectif du projet est de mettre en place un environnement Linux complet destiné au développement, à l’administration système et à l’hébergement de services.

L’environnement repose sur une machine virtuelle **Ubuntu Server 24.04** configurée avec plusieurs services, scripts Bash, tâches cron, outils réseau et composants applicatifs.

## Environnement

La machine virtuelle utilisée pour le projet est basée sur Ubuntu Server.

Configuration principale :

* Ubuntu Server 24.04
* 2 Go de RAM minimum
* 20 Go de stockage
* Hostname : `linux-exam-vm`
* Utilisateur principal : `modo`
* Utilisateur `root` réactivé
* Accès SSH configuré
* Shell ZSH
* Oh My Zsh
* Thème Haribo

## Réseau

La machine virtuelle utilise deux interfaces réseau :

* `enp0s3` : NAT, utilisée pour l'accès à Internet
* `enp0s8` : Host-only avec une adresse IP statique

Adresse Host-only :

```text
192.168.56.201
```

Cette interface permet notamment d'accéder à la VM depuis la machine hôte en SSH, HTTP ou PostgreSQL.

La configuration Netplan utilisée est disponible dans :

```text
configs/netplan/50-cloud-init.yaml
```

## SSH

Le serveur SSH est configuré afin de permettre l'administration distante de la machine.

L'utilisateur `modo` peut se connecter en SSH.

La connexion directe de l'utilisateur `root` via SSH est interdite.

Une paire de clés SSH a également été générée pour l'utilisateur `modo`.

Exemple de connexion :

```bash
ssh modo@192.168.56.201
```

## Application web Node.js avec Strapi

Une application web basée sur **Node.js et Strapi** a été installée sur la machine.

Strapi est utilisé comme CMS headless pour gérer un blog comprenant notamment :

* des articles ;
* des utilisateurs.

Strapi fonctionne localement sur :

```text
http://127.0.0.1:1337
```

L'application est exposée sur le réseau grâce à **Nginx**, utilisé comme reverse proxy.

Accès externe :

```text
http://192.168.56.201
```

Administration Strapi :

```text
http://192.168.56.201/admin
```

API des articles :

```text
GET http://192.168.56.201/api/articles
```

La configuration Nginx est disponible dans :

```text
configs/nginx/blog-strapi.conf
```

## PostgreSQL

Une base de données PostgreSQL a été mise en place.

Configuration principale :

```text
Base de données : data-db
Utilisateur : dbuser
```

La base est accessible depuis l'extérieur de la machine virtuelle afin de pouvoir être administrée avec un outil comme DataGrip ou DBeaver.

Le schéma contient trois tables :

```text
users
events
event_participants
```

Les relations entre les tables permettent d'associer des utilisateurs à des événements.

Le schéma SQL complet est disponible dans :

```text
database/schema.sql
```

## Sauvegarde PostgreSQL

Un script Bash réalise automatiquement une sauvegarde de la base PostgreSQL.

Script :

```text
scripts/backup.sh
```

Les sauvegardes sont stockées dans :

```text
/opt/backup/postgresql
```

Une tâche cron exécutée avec l'utilisateur `postgres` lance le backup tous les deux jours à **02h04** :

```cron
4 2 */2 * * /opt/backup/postgresql/backup.sh >> /opt/backup/postgresql/pg_backup.log 2>&1
```

La configuration cron est disponible dans :

```text
cron/postgres-crontab.txt
```

## SFTP

Un accès SFTP a été mis en place avec un utilisateur spécifique :

```text
sftpmodo
```

Le compte est cloisonné dans le dossier :

```text
/opt/sftp/
```

Le dossier utilisé pour les transferts de fichiers est accessible uniquement dans cet environnement cloisonné.

Une version sans mot de passe des informations de connexion est disponible dans :

```text
docs/sftp-identifiers.txt
```

## Pare-feu iptables

Le pare-feu de la machine est configuré avec **iptables**.

Le script :

```text
scripts/firewall-script.sh
```

permet notamment de :

* supprimer les anciennes règles ;
* bloquer les connexions entrantes par défaut ;
* autoriser les connexions déjà établies ;
* autoriser le trafic local via loopback ;
* autoriser SSH et SFTP sur le port `22` ;
* autoriser HTTP sur le port `80` ;
* autoriser PostgreSQL sur le port `5432`.

Les règles sont commentées en anglais afin d'expliquer leur rôle.

## Script des jours fériés

Le script :

```text
scripts/jour-ferie.sh
```

utilise l'API officielle du gouvernement français afin de déterminer le prochain jour férié en France métropolitaine.

Le script :

* récupère les jours fériés depuis l'API ;
* compare les dates avec la date actuelle de la machine ;
* ignore le jour courant s'il est lui-même férié ;
* affiche le prochain jour férié ;
* affiche une erreur si l'API ne peut pas être interrogée.

## Météo et MOTD

La météo de Paris est récupérée grâce à l'API **OpenWeatherMap**.

Le script principal est :

```text
scripts/weather.sh
```

Il récupère notamment :

* la ville ;
* la température ;
* l'humidité ;
* les conditions météorologiques.

Un second script :

```text
scripts/motd.sh
```

met à jour le fichier :

```text
/etc/motd
```

afin que la météo soit affichée lors de la connexion à la machine.

Une tâche cron root exécute cette mise à jour tous les jours à **06h00** :

```cron
0 6 * * * /home/modo/motd2.sh
```

La configuration cron correspondante est disponible dans :

```text
cron/root-crontab.txt
```

## Organisation du dépôt

```text
.
├── configs/
│   ├── netplan/
│   │   └── 50-cloud-init.yaml
│   └── nginx/
│       └── blog-strapi.conf
│
├── cron/
│   ├── postgres-crontab.txt
│   └── root-crontab.txt
│
├── database/
│   └── schema.sql
│
├── docs/
│   ├── app-web.txt
│   ├── authors.txt
│   └── sftp-identifiers.txt
│
├── scripts/
│   ├── backup.sh
│   ├── firewall-script.sh
│   ├── jour-ferie.sh
│   ├── motd.sh
│   └── weather.sh
│
├── Sujet.pdf
├── SyllabusDuProjet-2.pdf
└── .gitignore
```


## Partie non réalisée

La partie demandant la création d'un service **systemd** chargé de vérifier quotidiennement l'intégrité d'un environnement Flutter n'a pas été réalisée dans cette version du projet.

## Auteur

Moustapha CHAÏB

ESGI — Linux orienté développeurs
