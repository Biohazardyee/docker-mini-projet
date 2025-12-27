# -----------------------
# BUILD STAGE
# -----------------------
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY Worker.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish

# -----------------------
# RUNTIME STAGE
# -----------------------
FROM mcr.microsoft.com/dotnet/runtime:9.0
WORKDIR /app

COPY --from=build /app/publish .

# Sécurité : utilisateur non-root
RUN useradd -m appuser
USER appuser

ENTRYPOINT ["dotnet", "Worker.dll"]
