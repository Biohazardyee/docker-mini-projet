# 🗳️ Application de vote distribuée – Docker & Docker Swarm

## 📌 Présentation du projet

Ce projet est une application distribuée permettant à une audience de voter entre deux propositions.  
Il repose sur une architecture micro-services et a été entièrement **conteneurisé avec Docker**, puis **déployé sur un cluster Docker Swarm** afin d’assurer la haute disponibilité et la tolérance aux pannes.

L’objectif est de remplacer un déploiement initial basé sur des scripts bash par une solution moderne utilisant les bonnes pratiques de conteneurisation et d’orchestration.

Lien GitHub: [https://github.com/Biohazardyee/docker-mini-projet](https://github.com/Biohazardyee/docker-mini-projet)
---

## 🧩 Architecture de l’application

### Services applicatifs
- **vote** : application web Python (Flask) permettant de voter
- **worker** : service .NET consommant les votes depuis Redis et les stockant dans PostgreSQL
- **result** : application web Node.js affichant les résultats en temps réel

### Services techniques
- **Redis** : file de messages pour les votes
- **PostgreSQL** : base de données relationnelle persistante

---

## 🧪 Technologies utilisées

| Composant | Technologie | Version |
|--------|------------|--------|
| vote | Python / Flask | 3.11 |
| worker | .NET | 9.0 |
| result | Node.js / Express | 18 |
| Base de données | PostgreSQL | 18.1 |
| File de messages | Redis | 7 |
| Conteneurisation | Docker | Latest |
| Orchestration | Docker Swarm | Latest |

---

## ⚙️ Variables d’environnement

Les variables sont centralisées dans un fichier `.env` à la racine du projet que vous devrez créer.

```env
OPTION_A=Cats
OPTION_B=Dogs

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
POSTGRES_PORT=5432

POSTGRES_HOST=db
REDIS_HOST=redis
```

---

## 🚀 Lancement du projet avec Docker Compose (mode local)

Pour lancer le projet, il suffit de taper cette commande dans le dossier où se trouve le fichier `docker-compose.yml` :

```bash
docker compose up -d
```

## 🐳 Déploiement avec Docker Swarm

Pour ce qui est du déploiement en utilisant **Docker Swarm**, un autre fichier nommé `README_SWARM.md` explique les étapes à suivre.
