## Docker Compose Swarm Setup for Voting App

```
services:

  redis:
    image: redis:7-alpine
    command: ["redis-server", "--appendonly", "yes"]
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

## Instructions

1. S'assurer d'avoir le bon Docker Compose
2. S'assurer d'avoir VirtualBox et Vagrant d'installés
   - Pour installer Vagrant : https://www.vagrantup.com/docs/installation
   - Pour installer VirtualBox : https://www.virtualbox.org/wiki/Downloads
3. Dans le dossier `src/voting-app`, lancer la commande `vagrant up` pour démarrer les machines virtuelles.
4. Une fois les machines démarrées, vérifier que Docker est bien installé sur chaque machine avec la commande `docker --version`.
5. Se connecter à la machine `manager1` avec la commande `vagrant ssh manager1`.
6. Initialiser le Swarm avec la commande `docker swarm init --advertise-addr <manager1_ip>`.
7. Récupérer la commande pour joindre les noeuds workers avec `docker swarm join-token worker` et exécuter cette commande sur chaque machine worker (`worker1` et `worker2`).
8. Retourner sur la machine `manager1` et déployer la stack avec la commande `docker stack deploy -c docker-compose.yml votingapp`.
9. Vérifier que les services sont bien déployés avec la commande `docker stack services votingapp`.
10. Accéder à l'application de vote via `http://<manager1_ip>:8080` et à l'application de résultats via `http://<manager1_ip>:8081`.