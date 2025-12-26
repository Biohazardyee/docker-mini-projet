FROM python:3.11-slim

# Variables d’environnement Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Dépendances système minimales (redis-py peut nécessiter gcc)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Installation des dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code applicatif
COPY . .

# Sécurité : utilisateur non-root
RUN useradd -m appuser
USER appuser

EXPOSE 8080

CMD ["python", "app.py"]