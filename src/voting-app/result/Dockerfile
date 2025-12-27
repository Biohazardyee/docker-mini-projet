FROM node:18-alpine

# Dossier de travail
WORKDIR /app

# Copier uniquement les fichiers de dépendances
COPY package*.json ./

# Installation propre et reproductible
RUN npm install --production

# Copier le reste du code
COPY . .

# Port exposé par l'application
EXPOSE 8081

# Lancement de l'app
CMD ["npm", "start"]
