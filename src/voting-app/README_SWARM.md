# Déploiement de l'application sur un cluster Docker Swarm

## 1. Objectif

L’objectif de ce projet est de **déployer une application multi-services sur un cluster Docker Swarm**, composé de :

* **1 nœud manager**
* **2 nœuds worker**

Le cluster est déployé localement à l’aide de **Vagrant** et **VirtualBox**, puis l’application est orchestrée via **Docker Swarm** à l’aide d’un fichier `docker-compose.yml` compatible Swarm.

> Pour des raisons de commodité, le cluster n’est pas livré.
> Ce document décrit **l’intégralité du processus de mise en place et de déploiement**.


## 2. Pré-requis

### 2.1 Outils nécessaires

* **VirtualBox**
  [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)
* **Vagrant**
  [https://www.vagrantup.com/docs/installation](https://www.vagrantup.com/docs/installation)
* **Docker** (installé automatiquement sur les VM via Vagrant)

### 2.2 Mise en place du docker-compose.yml

Veillez vous assurer que le fichier `docker-compose.yml` correspond bien au contenu suivant pour s'assurer de la compatibilité avec Docker Swarm :

```bash
services:

  redis:
    image: redis:7-alpine
    command: [ "redis-server", "--appendonly", "yes" ]
    volumes:
      - redis_data:/data
    networks:
      - vote-redis-net
      - worker-backend-net
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - worker-backend-net
      - result-db-net
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure

  vote:
    image: biohazardye/vote:1.0
    ports:
      - "8080:8080"
    environment:
      OPTION_A: ${OPTION_A}
      OPTION_B: ${OPTION_B}
      REDIS_HOST: redis
    networks:
      - vote-redis-net
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

  worker:
    image: biohazardye/worker:1.0
    environment:
      REDIS_HOST: redis
      POSTGRES_HOST: db
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    networks:
      - worker-backend-net
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

  result:
    image: biohazardye/result:1.0
    ports:
      - "8081:80"
    environment:
      POSTGRES_HOST: db
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_PORT: ${POSTGRES_PORT}
    networks:
      - result-db-net
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure

volumes:
  postgres_data:
  redis_data:


networks:
  vote-redis-net:
    driver: overlay
  worker-backend-net:
    driver: overlay
  result-db-net:
    driver: overlay
```
---

## 3. Mise en place du cluster Docker Swarm

### 3.1 Démarrage des machines virtuelles

Depuis le dossier du projet :

```bash
vagrant up
```

Cette commande démarre les 3 machines virtuelles :

* `manager1`
* `worker1`
* `worker2`

---

### 3.2 Vérification de Docker

Sur chaque machine :

```bash
docker --version
```

Cela permet de s’assurer que Docker est bien installé et fonctionnel.

---

### 3.3 Initialisation du Swarm (manager)

Connexion au nœud manager :

```bash
vagrant ssh manager1
```

Initialisation du Swarm :

```bash
docker swarm init --advertise-addr <manager1_ip>
```

> *Note: l'ip `<manager1_ip>` peut être trouvé avec la commande est située dans le Vagranfile*

---

### 3.4 Ajout des nœuds workers

Sur le manager, récupérer la commande d’adhésion :

```bash
docker swarm join-token worker
```

Exécuter ensuite cette commande sur :

* `worker1`
* `worker2`

Une fois terminé, le cluster Swarm est opérationnel avec :

* 1 manager
* 2 workers

---

## 4. Configuration des variables d’environnement

Docker Swarm ne lit pas automatiquement les fichiers `.env`.
Il est donc nécessaire de charger manuellement les variables dans le shell avant le déploiement.

### 4.1 Création du fichier `.env`

Sur le nœud manager :

```bash
cd /vagrant
nano .env
```

Contenu du fichier :

```env
OPTION_A=option_A
OPTION_B=option_B

POSTGRES_USER=votre_user
POSTGRES_PASSWORD=votre_mot_de_passe
POSTGRES_DB=votre_base_de_donnees
```

---

### 4.2 Conversion au format Unix

Les fichiers `.env` peuvent contenir des caractères Windows (`CRLF`), ce qui empêche leur chargement correct.

```bash
sudo apt-get install -y dos2unix
dos2unix .env
```

---

### 4.3 Chargement des variables dans le shell

```bash
set -a
source .env
set +a
```

Vérification (exemple) :

```bash
echo $POSTGRES_USER
```

---

## 5. Déploiement de la stack Docker Swarm

### 5.1 Déploiement de l’application

Depuis le nœud manager :

```bash
docker stack deploy -c docker-compose.yml votingapp
```

---

### 5.2 Vérification du déploiement

```bash
docker stack services votingapp
```

Les services peuvent mettre quelques minutes à devenir actifs.

---

## 6. Accès à l’application

Une fois tous les services démarrés :

* Application de vote :
  `http://<manager1_ip>:8080`
* Application de résultats :
  `http://<manager1_ip>:8081`

Les services étant exposés via Docker Swarm, l’accès fonctionne également depuis :

* `worker1`
* `worker2`

