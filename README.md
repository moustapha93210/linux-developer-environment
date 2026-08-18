# Linux Developer Environment

![Ubuntu Server 24.04](https://img.shields.io/badge/Ubuntu%20Server-24.04-E95420?logo=ubuntu&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-Scripts-4EAA25?logo=gnubash&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-Strapi-339933?logo=nodedotjs&logoColor=white)
![Strapi](https://img.shields.io/badge/Strapi-CMS-4945FF?logo=strapi&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-Reverse%20Proxy-009639?logo=nginx&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white)

Projet final réalisé dans le cadre du cours **Linux orienté développeurs** à l'ESGI.

L'objectif est de mettre en place, sur une machine virtuelle **Ubuntu Server 24.04**, un environnement Linux complet destiné au développement, à l'administration système et à l'hébergement de services. L'environnement combine plusieurs services réseau, un CMS, une base de données, des scripts Bash et des tâches automatisées via cron.

## Sommaire

- [Présentation](#présentation)
- [Fonctionnalités](#fonctionnalités)
- [Technologies](#technologies)
- [Prérequis](#prérequis)
- [Architecture réseau](#architecture-réseau)
- [Démarrage rapide](#démarrage-rapide)
- [Accès à la VM (SSH)](#accès-à-la-vm-ssh)
- [Application web — Strapi et Nginx](#application-web--strapi-et-nginx)
- [PostgreSQL](#postgresql)
- [Sauvegarde PostgreSQL](#sauvegarde-postgresql)
- [SFTP](#sftp)
- [Pare-feu iptables](#pare-feu-iptables)
- [Scripts d'automatisation](#scripts-dautomatisation)
- [Tâches cron](#tâches-cron)
- [Structure du dépôt](#structure-du-dépôt)
- [Dépannage](#dépannage)
- [Sécurité et fichiers exclus](#sécurité-et-fichiers-exclus)
- [État du projet](#état-du-projet)
- [Auteur](#auteur)

## Présentation

L'environnement repose sur une seule machine virtuelle qui héberge l'ensemble des services. La VM est accessible depuis la machine hôte grâce à une interface réseau dédiée, tout en gardant un accès Internet via NAT.

Les principaux composants installés sont :

- un serveur SSH pour l'administration distante ;
- un CMS Strapi (Node.js) exposé au travers d'un reverse proxy Nginx ;
- une base de données PostgreSQL accessible depuis l'hôte ;
- un serveur SFTP cloisonné pour un utilisateur dédié ;
- un pare-feu iptables persistant ;
- des scripts Bash automatisés par cron.

## Fonctionnalités

| Fonctionnalité | Détail |
| -------------- | ------ |
| VM Ubuntu Server | Ubuntu Server 24.04, hostname `linux-exam-vm`, utilisateur `modo` |
| Accès SSH | Connexion de `modo`, connexion directe `root` interdite, paire de clés générée |
| Environnement shell | ZSH + Oh My Zsh + thème Haribo |
| CMS Strapi | Blog headless (articles, utilisateurs) sous Node.js |
| Reverse proxy | Nginx expose Strapi sur le port 80 |
| PostgreSQL | Base `data-db`, accessible depuis la machine hôte |
| Sauvegardes | Backup automatique de la base, tous les deux jours |
| SFTP | Utilisateur `sftpmodo` cloisonné dans `/opt/sftp` |
| Pare-feu | Règles iptables commentées et persistantes |
| Jours fériés | Script Bash interrogeant l'API du gouvernement français |
| Météo / MOTD | Récupération OpenWeatherMap affichée dans le message du jour |
| Automatisation | Tâches planifiées via cron |

> La vérification quotidienne d'un environnement Flutter via un service systemd était demandée mais **n'a pas été réalisée**. Voir la section [État du projet](#état-du-projet).

## Technologies

- **Système** : Ubuntu Server 24.04 (VirtualBox)
- **Shell** : ZSH, Oh My Zsh, thème Haribo
- **Web** : Node.js, Strapi, Nginx
- **Base de données** : PostgreSQL
- **Transfert de fichiers** : SFTP (OpenSSH)
- **Sécurité réseau** : iptables
- **Scripting** : Bash, cron
- **APIs externes** : [API des jours fériés (data.gouv.fr)](https://www.data.gouv.fr/fr/dataservices/jours-feries/), [OpenWeatherMap](https://openweathermap.org/api)

## Prérequis

Pour rejouer ou administrer l'environnement, il faut disposer :

- de la machine virtuelle Ubuntu Server 24.04 déjà installée (2 Go de RAM, 20 Go de stockage) ;
- d'un accès réseau host-only vers la VM (`192.168.56.201`) ;
- d'un client SSH et d'un client SFTP sur la machine hôte ;
- d'un client PostgreSQL (DBeaver, DataGrip ou `psql`) pour tester la base à distance.

## Architecture réseau

La VM utilise deux interfaces réseau distinctes :

- `enp0s3` — **NAT**, pour l'accès sortant vers Internet ;
- `enp0s8` — **Host-only**, avec une adresse IP statique pour la communication avec la machine hôte.

```text
                        Internet
                           │
                     NAT — enp0s3
                           │
                   ┌───────────────┐
                   │ Ubuntu Server │
                   │ linux-exam-vm │
                   └───────────────┘
                           │
                  Host-only — enp0s8
                   192.168.56.201/24
                           │
                     Machine hôte
```

L'interface host-only permet d'atteindre la VM depuis l'hôte en SSH, HTTP et PostgreSQL. Configuration Netplan : [50-cloud-init.yaml](configs/netplan/50-cloud-init.yaml).

> **Important — contexte d'exécution.** `127.0.0.1` désigne toujours la boucle locale de la machine où la commande est tapée. `127.0.0.1` **dans la VM** n'est donc pas `127.0.0.1` sur la machine hôte. Pour joindre un service de la VM depuis l'hôte, il faut utiliser `192.168.56.201`.

Récapitulatif des ports exposés par la VM :

| Service | Port | Adresse d'accès depuis l'hôte |
| ------- | ---- | ----------------------------- |
| SSH / SFTP | 22 | `192.168.56.201` |
| HTTP (Nginx → Strapi) | 80 | `http://192.168.56.201` |
| PostgreSQL | 5432 | `192.168.56.201:5432` |
| Strapi (interne à la VM) | 1337 | `127.0.0.1:1337` *(non exposé directement)* |

## Démarrage rapide

Pour un lecteur qui dispose déjà de la VM :

1. Démarrer la VM `linux-exam-vm`.
2. Vérifier que l'adresse host-only est bien `192.168.56.201`.
3. Se connecter en SSH (voir [Accès à la VM](#accès-à-la-vm-ssh)).
4. Démarrer Strapi (voir [Application web](#application-web--strapi-et-nginx)).
5. Ouvrir `http://192.168.56.201`.
6. Tester PostgreSQL et SFTP (voir sections dédiées).

Chaque étape est détaillée dans les sections correspondantes ci-dessous.

## Accès à la VM (SSH)

Le serveur SSH permet l'administration distante. L'utilisateur `modo` peut se connecter ; la connexion directe de `root` est interdite. Une paire de clés SSH a été générée pour `modo`.

Connexion depuis la machine hôte :

```bash
ssh modo@192.168.56.201
```

## Application web — Strapi et Nginx

Une application web basée sur **Node.js et Strapi** héberge un blog (articles et utilisateurs). Strapi est utilisé comme CMS headless, exposé à la machine hôte via un reverse proxy Nginx.

### Installation vs utilisation

Il faut distinguer deux choses :

- **Installer** Strapi sur une nouvelle machine se fait en suivant la [documentation officielle Strapi — Quick Start](https://docs.strapi.io/cms/quick-start) (prérequis Node.js/npm, création du projet, dépendances, premier compte administrateur, démarrage du serveur).
- **Utiliser** le projet existant : il est déjà présent dans `/home/modo/blog-strapi` sur la VM et se lance directement.

### Démarrer le projet existant

```bash
# Depuis la machine hôte
ssh modo@192.168.56.201

# Dans la VM
cd /home/modo/blog-strapi
npm run develop
```

Au démarrage, le terminal affiche notamment `Strapi started successfully`. Strapi écoute alors **localement dans la VM** sur `http://127.0.0.1:1337` (ou `http://localhost:1337`).

Ces adresses correspondent à la boucle locale de la VM : elles ne permettent **pas** de joindre Strapi depuis le navigateur de la machine hôte. L'accès depuis l'hôte passe par Nginx.

### Accès depuis la machine hôte

Nginx écoute sur le port HTTP `80` de la VM et transmet les requêtes à Strapi sur `127.0.0.1:1337`.

```text
Navigateur (machine hôte)
        │  HTTP :80
        ▼
   192.168.56.201
        │
      Nginx
        │  reverse proxy
        ▼
   127.0.0.1:1337
        │
      Strapi
```

| Ressource | URL |
| --------- | --- |
| Application | `http://192.168.56.201` |
| Administration | `http://192.168.56.201/admin` |
| API des articles | `http://192.168.56.201/api/articles` |

Test rapide de l'API :

```bash
curl http://192.168.56.201/api/articles
```

Les identifiants d'administration réels sont conservés sur la VM dans `/home/modo/app-web.txt`. Une version sans identifiants réels est fournie dans le dépôt : [app-web.txt](docs/app-web.txt). Configuration Nginx : [blog-strapi.conf](configs/nginx/blog-strapi.conf).

## PostgreSQL

Une base de données PostgreSQL héberge le schéma du projet.

| Paramètre | Valeur |
| --------- | ------ |
| Base | `data-db` |
| Utilisateur | `dbuser` |
| Mot de passe | `gTU1ZwxE92Z77H83a33OZ046` |
| Port | `5432` |

> Le mot de passe est celui imposé par le sujet académique ; il est reproduit tel quel.

Le schéma SQL (tables `users`, `events`, `event_participants`) est disponible dans [schema.sql](database/schema.sql).

### Connexion locale (dans la VM)

```bash
psql -h 127.0.0.1 -U dbuser -d data-db
```

- `-h` : hôte du serveur PostgreSQL ;
- `-U` : utilisateur ;
- `-d` : base ciblée.

Une fois connecté, lister les tables (commande `psql`, pas Bash) :

```sql
\dt
```

Les tables attendues sont `users`, `events` et `event_participants`.

### Vérifier les droits de `dbuser`

Ajout d'une donnée de test :

```sql
INSERT INTO users (first_name, last_name, email)
VALUES ('Test', 'User', 'test.user@example.com');

SELECT * FROM users;
```

Nettoyage :

```sql
DELETE FROM users
WHERE email = 'test.user@example.com';
```

Quitter `psql` :

```sql
\q
```

### Connexion depuis la machine hôte

La base est accessible à distance. Depuis DBeaver, DataGrip ou un autre client PostgreSQL :

```text
Host     : 192.168.56.201
Port     : 5432
Database : data-db
User     : dbuser
Password : gTU1ZwxE92Z77H83a33OZ046
```

Avec `psql` installé sur l'hôte :

```bash
psql -h 192.168.56.201 -p 5432 -U dbuser -d data-db
```

Pour vérifier depuis la VM que PostgreSQL écoute bien sur le port 5432 :

```bash
sudo ss -lntp | grep 5432
```

## Sauvegarde PostgreSQL

Un script Bash réalise automatiquement une sauvegarde de la base : [backup.sh](scripts/backup.sh). Les fichiers sont stockés dans `/opt/backup/postgresql`.

Une tâche cron exécutée par l'utilisateur `postgres` lance la sauvegarde tous les deux jours à **02h04** :

```cron
4 2 */2 * * /opt/backup/postgresql/backup.sh >> /opt/backup/postgresql/pg_backup.log 2>&1
```

Configuration : [postgres-crontab.txt](cron/postgres-crontab.txt).

## SFTP

Un accès SFTP cloisonné est mis en place pour un utilisateur Linux dédié, `sftpmodo`. Ce compte ne dispose pas d'un shell classique et reste confiné à `/opt/sftp` (chroot).

### Mise en place

```bash
# Création du compte, sans shell interactif
sudo useradd -m -d /opt/sftp/ -s /usr/sbin/nologin sftpmodo

# Définition du mot de passe
sudo passwd sftpmodo
```

La restriction est configurée dans `/etc/ssh/sshd_config` :

```text
Match User sftpmodo
    ChrootDirectory /opt/sftp
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
```

Le dossier utilisé pour les transferts est `/opt/sftp/uploads/`. Les informations de connexion (sans mot de passe réel) sont fournies dans [sftp-identifiers.txt](docs/sftp-identifiers.txt).

### Se connecter et tester

Depuis la machine hôte :

```bash
sftp sftpmodo@192.168.56.201
```

Le serveur demande le mot de passe défini plus haut, puis affiche l'invite `sftp>`. Les commandes suivantes sont celles de l'interpréteur SFTP (pas Bash) :

```text
pwd        # Remote working directory: /
ls -la
cd uploads
```

> Dans le chroot, `/` vu depuis SFTP correspond en réalité à `/opt/sftp/` sur la VM : c'est la racine attribuée à l'utilisateur, pas la racine du système.

### Vérifier le cloisonnement

Toujours dans l'invite `sftp>`, la commande suivante doit **échouer**, car le véritable `/etc` de la VM n'est pas accessible depuis le chroot :

```text
cd /etc
```

### Envoi et téléchargement d'un fichier

Créer un fichier de test sur l'hôte (Bash) :

```bash
echo "Test SFTP Linux project" > test-sftp.txt
```

Se reconnecter puis, dans l'invite `sftp>` :

```text
cd uploads
put test-sftp.txt
ls -l
get test-sftp.txt test-sftp-download.txt
exit
```

Vérifier le contenu récupéré sur l'hôte (Bash) :

```bash
cat test-sftp-download.txt   # Test SFTP Linux project
```

Ces tests valident la connexion, l'authentification de `sftpmodo`, le cloisonnement, l'envoi et le téléchargement de fichiers.

## Pare-feu iptables

Le pare-feu est géré avec **iptables** via un script commenté en anglais : [firewall-script.sh](scripts/firewall-script.sh). Il permet de :

- supprimer les anciennes règles ;
- bloquer les connexions entrantes par défaut ;
- autoriser les connexions déjà établies ;
- autoriser le trafic local via loopback ;
- autoriser SSH et SFTP sur le port `22` ;
- autoriser HTTP sur le port `80` ;
- autoriser PostgreSQL sur le port `5432`.

## Scripts d'automatisation

### Jours fériés

Script : [jour-ferie.sh](scripts/jour-ferie.sh). Il interroge l'[API officielle du gouvernement français](https://www.data.gouv.fr/fr/dataservices/jours-feries/) pour déterminer le prochain jour férié en France métropolitaine. Le script :

- récupère les jours fériés depuis l'API ;
- compare les dates avec la date actuelle de la machine ;
- ignore le jour courant s'il est lui-même férié ;
- affiche le prochain jour férié ;
- affiche une erreur si l'API ne peut pas être interrogée.

### Météo et MOTD

La météo de Paris est récupérée via l'API [OpenWeatherMap](https://openweathermap.org/api). Le script principal [weather.sh](scripts/weather.sh) récupère la ville, la température, l'humidité et les conditions météorologiques.

Un second script, [motd.sh](scripts/motd.sh), met à jour le fichier `/etc/motd` afin que la météo soit affichée lors de la connexion à la machine.

> **Note.** Le README source indique deux noms de scripts (`motd.sh` fourni dans le dépôt, et `motd2.sh` référencé par la tâche cron). Les deux noms sont conservés tels quels ; la tâche cron exécute effectivement `/home/modo/motd2.sh`.

## Tâches cron

| Fonction | Utilisateur | Planification | Script |
| -------- | ----------- | ------------- | ------ |
| Sauvegarde PostgreSQL | `postgres` | Tous les 2 jours à 02h04 | `/opt/backup/postgresql/backup.sh` |
| Mise à jour météo / MOTD | `root` | Tous les jours à 06h00 | `/home/modo/motd2.sh` |

Fichiers de configuration : [postgres-crontab.txt](cron/postgres-crontab.txt), [root-crontab.txt](cron/root-crontab.txt).

## Structure du dépôt

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

| Dossier | Rôle |
| ------- | ---- |
| `configs/` | Configurations système et réseau (Netplan, Nginx) |
| `cron/` | Tâches planifiées |
| `database/` | Schéma PostgreSQL |
| `docs/` | Fichiers liés au rendu |
| `scripts/` | Automatisations Bash |

Documents de référence : [authors.txt](docs/authors.txt), [Sujet.pdf](Sujet.pdf), [SyllabusDuProjet-2.pdf](SyllabusDuProjet-2.pdf).

## Dépannage

### Erreur 502 Bad Gateway

Lorsque le navigateur affiche `502 Bad Gateway` en ouvrant `http://192.168.56.201`, Nginx fonctionne mais ne parvient pas à joindre Strapi.

```text
Machine hôte → Nginx : OK
Nginx → Strapi : KO
```

**Cause probable :** Strapi n'est pas démarré sur le port `1337`.

**Solution :** redémarrer Strapi dans la VM.

```bash
cd /home/modo/blog-strapi
npm run develop
```

Puis vérifier que le port est bien à l'écoute :

```bash
ss -lntp | grep 1337
```

## Sécurité et fichiers exclus

Les identifiants réels (compte administrateur Strapi, mot de passe SFTP) ne sont pas publiés dans le dépôt : ils restent conservés sur la VM et dans les fichiers de rendu non versionnés. Les fichiers de documentation du dépôt (`docs/`) fournissent des versions sans secrets réels.

## État du projet

**Réalisé et opérationnel :**

- VM Ubuntu Server 24.04 (`linux-exam-vm`, utilisateur `modo`, `root` réactivé) ;
- accès SSH (`modo` autorisé, `root` interdit en direct, paire de clés) ;
- environnement shell ZSH + Oh My Zsh + thème Haribo ;
- Strapi derrière Nginx ;
- PostgreSQL accessible depuis l'hôte, avec sauvegarde automatisée ;
- serveur SFTP cloisonné ;
- pare-feu iptables persistant ;
- scripts jours fériés, météo et MOTD, automatisés par cron.

**Non réalisé :**

- le service **systemd** chargé de vérifier quotidiennement l'intégrité d'un environnement Flutter n'a pas été mis en place dans cette version du projet.

## Auteur

Moustapha CHAÏB

ESGI — Linux orienté développeurs
