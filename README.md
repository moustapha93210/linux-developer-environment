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

La configuration Netplan utilisée est disponible ici :

[Voir la configuration Netplan](configs/netplan/50-cloud-init.yaml)

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

Une application web basée sur **Node.js et Strapi** a été mise en place sur la machine virtuelle.

Strapi est utilisé comme CMS headless afin de gérer un blog contenant notamment des articles et des utilisateurs.

### Installation de Strapi

Pour installer Strapi sur une nouvelle machine, il faut suivre le **Quick Start Guide officiel de Strapi** :

https://docs.strapi.io/cms/quick-start

La documentation explique notamment comment :

* vérifier les prérequis Node.js et npm ;
* créer un projet Strapi ;
* installer les dépendances ;
* créer le premier compte administrateur ;
* démarrer le serveur Strapi.

Dans ce projet, l'application Strapi a été créée dans le dossier :

```text
/home/modo/blog-strapi
```

### Démarrer le projet existant

Une fois Strapi installé et le projet présent dans `/home/modo/blog-strapi`, se connecter à la machine virtuelle :

```bash
ssh modo@192.168.56.201
```

Puis se placer dans le dossier du projet :

```bash
cd /home/modo/blog-strapi
```

Démarrer ensuite Strapi en mode développement :

```bash
npm run develop
```

Lorsque le démarrage est terminé, le terminal doit notamment afficher :

```text
Strapi started successfully
```

Strapi écoute alors localement dans la VM sur :

```text
http://127.0.0.1:1337
```

ou :

```text
http://localhost:1337
```

Ces adresses correspondent à la boucle locale de la **machine virtuelle**. Elles ne permettent donc pas d'accéder directement à Strapi depuis le navigateur de la machine hôte.

### Accès depuis la machine hôte

Nginx est utilisé comme reverse proxy.

Il écoute sur le port HTTP `80` de la VM puis transmet les requêtes à Strapi sur :

```text
127.0.0.1:1337
```

L'application est accessible depuis la machine hôte à l'adresse :

```text
http://192.168.56.201
```

L'interface d'administration Strapi est accessible avec :

```text
http://192.168.56.201/admin
```

Les identifiants permettant de se connecter à l'administration sont conservés dans le fichier de rendu présent sur la VM :

```text
/home/modo/app-web.txt
```

Une version sans identifiants réels est disponible dans le dépôt :

[Voir les informations d'accès Strapi](docs/app-web.txt)

### API des articles

L'API REST permettant de récupérer les articles est accessible avec :

```text
GET http://192.168.56.201/api/articles
```

Elle peut également être testée avec :

```bash
curl http://192.168.56.201/api/articles
```

### Architecture de l'accès web

```text
Machine hôte
     |
     | HTTP :80
     v
192.168.56.201
     |
     v
   Nginx
     |
     | Reverse proxy
     v
127.0.0.1:1337
     |
     v
   Strapi
```

La configuration Nginx utilisée est disponible ici :

[Voir la configuration Nginx](configs/nginx/blog-strapi.conf)

### Erreur 502 Bad Gateway

Si Nginx affiche :

```text
502 Bad Gateway
```

cela signifie généralement que Nginx fonctionne mais qu'il ne peut pas joindre Strapi sur le port `1337`.

Il faut alors se connecter à la VM et redémarrer Strapi :

```bash
cd /home/modo/blog-strapi
npm run develop
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

Le schéma SQL complet est disponible ici :

[Voir le schéma PostgreSQL](database/schema.sql)

## Sauvegarde PostgreSQL

Un script Bash réalise automatiquement une sauvegarde de la base PostgreSQL.

Script :

[Voir le script de sauvegarde PostgreSQL](scripts/backup.sh)

Les sauvegardes sont stockées dans :

```text
/opt/backup/postgresql
```

Une tâche cron exécutée avec l'utilisateur `postgres` lance le backup tous les deux jours à **02h04** :

```cron
4 2 */2 * * /opt/backup/postgresql/backup.sh >> /opt/backup/postgresql/pg_backup.log 2>&1
```

La configuration cron est disponible ici :

[Voir le crontab PostgreSQL](cron/postgres-crontab.txt)

## SFTP

### Authentification SFTP

Un utilisateur Linux dédié nommé `sftpmodo` est utilisé pour les connexions SFTP.

Le compte peut être créé avec :

```bash
sudo useradd -m -d /opt/sftp/ -s /usr/sbin/nologin sftpmodo
```

Le mot de passe du compte est ensuite défini avec :

```bash
sudo passwd sftpmodo
```

La configuration SSH qui se trouve dans `/etc/ssh/sshd_config` limite cet utilisateur à l'utilisation du protocole SFTP :

```text
Match User sftpmodo
    ChrootDirectory /opt/sftp
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PasswordAuthentication yes
```

L'utilisateur ne dispose donc pas d'un shell Linux classique et reste cloisonné dans :

```text
/opt/sftp/
```

Les fichiers peuvent être transférés dans :

```text
/opt/sftp/uploads/
```

Pour se connecter depuis la machine hôte :

```bash
sftp sftpmodo@192.168.56.201
```

Le serveur demande ensuite le mot de passe défini précédemment avec `passwd`.

Les informations de connexion utilisées pour le rendu sont disponibles dans :

[Voir les informations SFTP](docs/sftp-identifiers.txt)


Un accès SFTP a été mis en place avec un utilisateur spécifique :

```text
sftpmodo
```

Le compte est cloisonné dans le dossier :

```text
/opt/sftp/
```

Le dossier utilisé pour les transferts de fichiers est accessible uniquement dans cet environnement cloisonné.

Une version sans mot de passe des informations de connexion est disponible ici :

[Voir les informations SFTP](docs/sftp-identifiers.txt)

### Tester le serveur SFTP

Le serveur SFTP peut être testé depuis la machine hôte avec :

```bash
sftp sftpmodo@192.168.56.201
```

Après authentification, une invite SFTP apparaît :

```text
sftp>
```

Il est possible de vérifier le dossier courant avec :

```text
pwd
```

Le résultat attendu est :

```text
Remote working directory: /
```

Dans cet environnement, `/` correspond au dossier chroot configuré sur la VM :

```text
/opt/sftp/
```

Les fichiers accessibles peuvent être listés avec :

```text
ls -la
```

Le dossier utilisé pour les transferts est :

```text
uploads
```

On peut y accéder avec :

```text
cd uploads
```

### Vérifier le cloisonnement

Le compte `sftpmodo` est volontairement limité à son environnement SFTP.

Par exemple :

```text
cd /etc
```

doit échouer, car le véritable dossier `/etc` de la machine n'est pas accessible depuis le chroot.

Cela permet de vérifier que l'utilisateur ne peut pas parcourir le reste du système.

### Tester l'envoi d'un fichier

Depuis le terminal Git Bash de la machine hôte, créer un fichier de test :

```bash
echo "Test SFTP Linux project" > test-sftp.txt
```

Puis se reconnecter au serveur SFTP :

```bash
sftp sftpmodo@192.168.56.201
```

Se placer dans le dossier d'upload :

```text
cd uploads
```

Puis envoyer le fichier :

```text
put test-sftp.txt
```

Vérifier sa présence avec :

```text
ls -l
```

### Tester le téléchargement d'un fichier

Toujours depuis l'invite SFTP :

```text
get test-sftp.txt test-sftp-download.txt
```

Puis quitter :

```text
exit
```

Le fichier téléchargé peut ensuite être vérifié depuis Git Bash :

```bash
cat test-sftp-download.txt
```

Le contenu attendu est :

```text
Test SFTP Linux project
```

Ces tests permettent de valider :

* la connexion au serveur SFTP ;
* l'authentification de l'utilisateur `sftpmodo` ;
* le cloisonnement du compte ;
* l'envoi de fichiers ;
* le téléchargement de fichiers.



## Pare-feu iptables

Le pare-feu de la machine est configuré avec **iptables**.

Le script est disponible ici :

[Voir le script du pare-feu iptables](scripts/firewall-script.sh)

Il permet notamment de :

* supprimer les anciennes règles ;
* bloquer les connexions entrantes par défaut ;
* autoriser les connexions déjà établies ;
* autoriser le trafic local via loopback ;
* autoriser SSH et SFTP sur le port `22` ;
* autoriser HTTP sur le port `80` ;
* autoriser PostgreSQL sur le port `5432`.

Les règles sont commentées en anglais afin d'expliquer leur rôle.

## Script des jours fériés

Le script est disponible ici :

[Voir le script des jours fériés](scripts/jour-ferie.sh)

Il utilise l'API officielle du gouvernement français afin de déterminer le prochain jour férié en France métropolitaine.

Le script :

* récupère les jours fériés depuis l'API ;
* compare les dates avec la date actuelle de la machine ;
* ignore le jour courant s'il est lui-même férié ;
* affiche le prochain jour férié ;
* affiche une erreur si l'API ne peut pas être interrogée.

## Météo et MOTD

La météo de Paris est récupérée grâce à l'API **OpenWeatherMap**.

Le script principal est disponible ici :

[Voir le script météo](scripts/weather.sh)

Il récupère notamment :

* la ville ;
* la température ;
* l'humidité ;
* les conditions météorologiques.

Un second script met à jour le message du jour :

[Voir le script MOTD](scripts/motd.sh)

Il met à jour le fichier :

```text
/etc/motd
```

afin que la météo soit affichée lors de la connexion à la machine.

Une tâche cron root exécute cette mise à jour tous les jours à **06h00** :

```cron
0 6 * * * /home/modo/motd2.sh
```

La configuration cron correspondante est disponible ici :

[Voir le crontab root](cron/root-crontab.txt)

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

## Documents

[Voir le fichier des auteurs](docs/authors.txt)

[Voir le sujet du projet](Sujet.pdf)

[Voir le syllabus du projet](SyllabusDuProjet-2.pdf)

## Partie non réalisée

La partie demandant la création d'un service **systemd** chargé de vérifier quotidiennement l'intégrité d'un environnement Flutter n'a pas été réalisée dans cette version du projet.

## Auteur

Moustapha CHAÏB

ESGI — Linux orienté développeurs
