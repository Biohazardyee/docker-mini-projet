FROM python:3.11-slim

# Variables d’environnement Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Installation des dépendances Python
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copie du code applicatif
COPY . .

# Sécurité : utilisateur non-root
RUN useradd -m appuser
USER appuser

EXPOSE 8080

CMD ["python", "app.py"]